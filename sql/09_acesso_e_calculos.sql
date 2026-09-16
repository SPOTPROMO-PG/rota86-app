/* ============================================================================
   ROTA86 — Acesso/login e cálculos derivados (slope/risco)

   Gap encontrado na auditoria de telas do v3 (template_v3_direcional.html):
   hoje o login roda 100% client-side contra `SETORES_ACESSO`, um array
   embutido no HTML no momento do build, com SENHA ÚNICA COMPARTILHADA para
   todos os setores — não há tabela de usuário/sessão em lugar nenhum, e
   isso não é aceitável para um app publicado na web (PHP). Este script
   desenha autenticação real por pessoa, substituindo o modelo antigo.

   Perfil (Promotor/Supervisor/Coordenador/Gerente/...) NÃO é redesenhado
   aqui — reaproveita dbo.bi_d_pessoa.COD_PERFIL/PERFIL, que já é a
   taxonomia oficial (11 perfis distintos confirmados no banco em
   17/09/2026: ADM, PROMOTOR, SUPERVISOR, COORDENADOR, GERENTE, CLIENTE,
   BKO, CLIENTE BARUEL, ESPECIALISTA, PROMOTOR 5X2, FERISTA/TMP,
   CONSULTOR). Não criamos rota86.perfil_acesso.

   SENHA: procurei em TODAS as tabelas de bi_pg_promotores (49 tabelas) por
   qualquer coluna de senha/hash/login/credencial — não existe nenhuma.
   O servidor 172.18.0.59 tem ~120 bases (bi_s3, bi_pg_phc, askme_pg entre
   elas), mas a conta usada aqui só tem acesso a bi_pg_promotores — não foi
   possível confirmar se a senha mora em alguma dessas outras bases. Até
   confirmar isso com quem administra o acesso, esta tabela `usuario`
   assume que a senha do ROTA86 é criada agora, pela primeira vez, neste
   schema — se depois confirmarem uma fonte externa (AD/SSO/outro banco),
   trocamos senha_hash por uma referência a essa fonte, sem mudar o resto
   do desenho.

   Também resolve slope/risco (STORES[11]/[12] no v3): hoje calculado no
   Python a cada geração do HTML (regressão linear simples, mínimo 3 pontos
   de histórico, via np.polyfit) — aqui vira uma view SQL, calculada em cima
   de rota86.pontuacao_loja_mes, sem precisar gerar HTML de novo pra atualizar.
   ============================================================================ */

/* ---------------------------------------------------------------------------
   usuario — login real por pessoa. Substitui a senha única compartilhada
   por setor do v3. cod_pessoa liga ao cadastro corporativo já existente
   (dbo.bi_d_pessoa) — é de lá que vem PERFIL (via view abaixo), não de uma
   tabela de domínio própria. Só fica sem cod_pessoa um usuário de exceção
   (ex.: conta técnica/TI) que não tem cadastro de pessoa.
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.usuario', 'U') IS NOT NULL DROP TABLE rota86.usuario;
CREATE TABLE rota86.usuario (
    id              INT             IDENTITY(1,1) PRIMARY KEY,
    cod_pessoa      INT             NULL,       -- FK lógica: dbo.bi_d_pessoa.COD_PESSOA — fonte do perfil (COD_PERFIL/PERFIL)
    login           VARCHAR(100)    NOT NULL UNIQUE,   -- e-mail corporativo ou usuário funcional
    senha_hash      VARBINARY(64)   NULL,       -- NULL enquanto a fonte real da senha não for confirmada (ver cabeçalho do arquivo)
    perfil_manual   VARCHAR(30)     NULL,       -- só preenchido quando cod_pessoa é NULL (conta sem cadastro de pessoa)
    ativo           BIT             NOT NULL DEFAULT 1,
    ultimo_login_em DATETIME2(0)    NULL,
    criado_em       DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT ck_usuario_cod_pessoa_ou_perfil CHECK (cod_pessoa IS NOT NULL OR perfil_manual IS NOT NULL)
);
CREATE INDEX ix_usuario_cod_pessoa ON rota86.usuario (cod_pessoa);
GO

/* ---------------------------------------------------------------------------
   vw_usuario_perfil — perfil resolvido: de bi_d_pessoa quando existe
   cod_pessoa, senão o perfil_manual da conta de exceção.
   --------------------------------------------------------------------------- */
CREATE OR ALTER VIEW rota86.vw_usuario_perfil AS
SELECT
    u.id                AS usuario_id,
    u.login,
    u.cod_pessoa,
    COALESCE(p.PERFIL, u.perfil_manual)    AS perfil,
    COALESCE(p.COD_PERFIL, NULL)            AS cod_perfil,
    u.ativo
FROM rota86.usuario u
LEFT JOIN dbo.bi_d_pessoa p
       ON p.COD_PESSOA = u.cod_pessoa
      AND GETDATE() BETWEEN p.date_from AND p.date_to;
GO

/* ---------------------------------------------------------------------------
   usuario_escopo — o que cada usuário enxerga (substitui os campos
   nomes[]/coordenadores[]/coordenador_setores[] do SETORES_ACESSO antigo).
   Um usuário pode ter mais de uma linha de escopo (ex.: um "Coordenador
   Lider" vê vários coordenadores regionais).
   tipo_escopo:
     'SETOR'        -> valor = SETOR_PROMOTOR (vê 1 carteira de promotor)
     'COORDENADOR'  -> valor = nome/cod_pessoa do coordenador regional
     'EXECUTIVO'    -> valor = nome/cod_pessoa do executivo
     'TODOS'        -> valor = NULL (perfil Operacao, vê tudo exceto DEMO-*)
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.usuario_escopo', 'U') IS NOT NULL DROP TABLE rota86.usuario_escopo;
CREATE TABLE rota86.usuario_escopo (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    usuario_id      INT             NOT NULL REFERENCES rota86.usuario(id),
    tipo_escopo     VARCHAR(15)     NOT NULL,
    cod_pessoa_ref  INT             NULL,       -- quando o escopo aponta pra uma pessoa (coordenador/executivo) por chave, preferir isto a texto
    valor_texto     VARCHAR(100)    NULL,       -- fallback quando só existe o nome/setor em texto (dado legado do catálogo)
    CONSTRAINT ck_usuario_escopo_tipo CHECK (tipo_escopo IN ('SETOR','COORDENADOR','EXECUTIVO','TODOS'))
);
CREATE INDEX ix_usuario_escopo_usuario ON rota86.usuario_escopo (usuario_id);
GO

/* ---------------------------------------------------------------------------
   vw_pontuacao_slope_risco — regressão linear simples do histórico de notas
   por loja (mínimo 3 leituras), reproduzindo a regra hoje em gerar_rota85.py:
     slope = inclinação da reta de mínimos quadrados sobre SCORE_TOTAL,
             ordenado por ordem_mes, ignorando meses sem leitura
     risco = 3 se nota<65 e slope<-0.3 (crítica)
             2 se nota<77 (GATE) e slope<0.3 (parada)
             1 se slope<-1.0 (queda forte)
             0 caso contrário (inclusive quando slope é nulo)
   Fórmula de mínimos quadrados calculada por agregação (sem função nativa
   de regressão no T-SQL): slope = (n*Sxy - Sx*Sy) / (n*Sxx - Sx*Sx), com
   x = posição sequencial da leitura (0,1,2...), y = score_total.
   --------------------------------------------------------------------------- */
CREATE OR ALTER VIEW rota86.vw_pontuacao_slope_risco AS
WITH historico AS (
    SELECT
        id_loja, ordem_mes, score_total,
        ROW_NUMBER() OVER (PARTITION BY id_loja ORDER BY ordem_mes) - 1 AS x
    FROM rota86.pontuacao_loja_mes
    WHERE score_total IS NOT NULL
),
agregado AS (
    SELECT
        id_loja,
        COUNT(*)                                   AS n,
        SUM(CAST(x AS FLOAT))                        AS sx,
        SUM(CAST(score_total AS FLOAT))              AS sy,
        SUM(CAST(x AS FLOAT) * CAST(x AS FLOAT))      AS sxx,
        SUM(CAST(x AS FLOAT) * CAST(score_total AS FLOAT)) AS sxy
    FROM historico
    GROUP BY id_loja
),
ultima_nota AS (
    SELECT id_loja, score_total AS nota_atual, ordem_mes
    FROM rota86.pontuacao_loja_mes p
    WHERE ordem_mes = (SELECT MAX(p2.ordem_mes) FROM rota86.pontuacao_loja_mes p2 WHERE p2.id_loja = p.id_loja AND p2.score_total IS NOT NULL)
)
SELECT
    a.id_loja,
    u.nota_atual,
    u.ordem_mes,
    CASE WHEN a.n >= 3 AND (a.n * a.sxx - a.sx * a.sx) <> 0
         THEN (a.n * a.sxy - a.sx * a.sy) / (a.n * a.sxx - a.sx * a.sx)
         ELSE NULL END AS slope,
    CASE
        WHEN a.n < 3 THEN 0
        WHEN u.nota_atual < 65 AND (a.n * a.sxy - a.sx * a.sy) / NULLIF(a.n * a.sxx - a.sx * a.sx, 0) < -0.3 THEN 3
        WHEN u.nota_atual < 77 AND (a.n * a.sxy - a.sx * a.sy) / NULLIF(a.n * a.sxx - a.sx * a.sx, 0) < 0.3 THEN 2
        WHEN (a.n * a.sxy - a.sx * a.sy) / NULLIF(a.n * a.sxx - a.sx * a.sx, 0) < -1.0 THEN 1
        ELSE 0
    END AS risco
FROM agregado a
JOIN ultima_nota u ON u.id_loja = a.id_loja;
GO

/* ---------------------------------------------------------------------------
   medida_sos_calculada — opcional. Hoje a Calculadora SOS (cm P&G / cm
   totais por loja+categoria) só vive no localStorage do aparelho, nunca é
   enviada a lugar nenhum. Esta tabela só é necessária SE a decisão for
   centralizar essa medição para auditoria/consulta por outra pessoa que
   não o próprio promotor que mediu. Se a ferramenta continuar sendo só um
   apoio de cálculo pessoal, não é preciso criar isto — deixo pronto e
   comentado.
   --------------------------------------------------------------------------- */
-- IF OBJECT_ID('rota86.medida_sos_calculada', 'U') IS NOT NULL DROP TABLE rota86.medida_sos_calculada;
-- CREATE TABLE rota86.medida_sos_calculada (
--     id              BIGINT IDENTITY(1,1) PRIMARY KEY,
--     id_loja         VARCHAR(20)     NOT NULL,
--     categoria       VARCHAR(100)    NOT NULL,
--     cm_pg           DECIMAL(9,2)    NOT NULL,
--     cm_universo     DECIMAL(9,2)    NOT NULL,
--     cod_pessoa      INT             NULL,
--     atualizado_em   DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
-- );
GO
