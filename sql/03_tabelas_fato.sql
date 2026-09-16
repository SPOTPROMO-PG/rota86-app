/* ============================================================================
   ROTA86 — Tabelas fato (o que o app PHP efetivamente consulta)
   Nenhuma tabela aqui guarda nome de pessoa/loja/hierarquia — sempre chave
   (ID_LOJA, COD_ROTA, COD_PESSOA) resolvida por JOIN com dbo.bi_d_pessoa /
   dbo.bi_d_rota / dbo.bi_catalogo / dbo.bi_d_loja (ver 07_ARQUITETURA_ALVO.md
   seção 4).
   ============================================================================ */

/* ---------------------------------------------------------------------------
   pontuacao_loja_mes — carga direta do fechamento oficial (stg_f_score).
   Não é recalculada; f_score já é a régua oficial.
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.pontuacao_loja_mes', 'U') IS NOT NULL DROP TABLE rota86.pontuacao_loja_mes;
CREATE TABLE rota86.pontuacao_loja_mes (
    id_loja                 VARCHAR(20)     NOT NULL,
    ordem_mes                INT             NOT NULL,   -- AAAAMM
    mes_referencia           VARCHAR(20)     NULL,
    score_total              DECIMAL(9,2)    NULL,
    score_total_objetivo     DECIMAL(9,2)    NULL,
    score_sos                DECIMAL(9,2)    NULL,
    score_sos_objetivo       DECIMAL(9,2)    NULL,
    score_kbd                DECIMAL(9,2)    NULL,       -- = SCORE PS do fechamento
    score_kbd_objetivo       DECIMAL(9,2)    NULL,
    score_pe                 DECIMAL(9,2)    NULL,
    score_pe_objetivo        DECIMAL(9,2)    NULL,
    score_cko                DECIMAL(9,2)    NULL,
    score_cko_objetivo       DECIMAL(9,2)    NULL,
    ultima_leitura           DATE            NULL,
    foi_lida                 AS (CASE WHEN ultima_leitura IS NOT NULL THEN 1 ELSE 0 END) PERSISTED,
    batch_id                 BIGINT          NOT NULL,
    updated_at               DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT pk_pontuacao_loja_mes PRIMARY KEY (id_loja, ordem_mes)
);
CREATE INDEX ix_pontuacao_mes ON rota86.pontuacao_loja_mes (ordem_mes);
GO

/* ---------------------------------------------------------------------------
   oportunidade_loja_mes — saída do motor (gerar_oportunidades_rota86.py),
   17 colunas originais + chaves técnicas. Recalculada a cada carga.
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.oportunidade_loja_mes', 'U') IS NOT NULL DROP TABLE rota86.oportunidade_loja_mes;
CREATE TABLE rota86.oportunidade_loja_mes (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_loja             VARCHAR(20)     NOT NULL,
    ordem_mes            INT             NOT NULL,
    kpi                  VARCHAR(10)     NOT NULL,   -- SOS | KBD | PE | CKO — o motor gera "PS" internamente (nome legado); renomear para KBD na carga (INSERT ... CASE WHEN kpi='PS' THEN 'KBD' ELSE kpi END), mesma convenção de rota86.pontuacao_loja_mes.score_kbd
    componente           VARCHAR(100)    NULL,
    categoria            VARCHAR(200)    NULL,
    regra_mop            NVARCHAR(300)   NULL,
    realizado            DECIMAL(9,2)    NULL,
    objetivo              DECIMAL(9,2)    NULL,
    unidade               VARCHAR(20)     NULL,       -- % | execução | quantidade | pontos
    pontos_atuais         DECIMAL(9,2)    NOT NULL DEFAULT 0,
    pontos_max            DECIMAL(9,2)    NOT NULL DEFAULT 0,
    pontos_faltantes      DECIMAL(9,2)    NOT NULL DEFAULT 0,
    acao_sugerida         NVARCHAR(500)   NULL,
    canal                 VARCHAR(30)     NULL,
    plataforma            VARCHAR(30)     NULL,
    confianca             VARCHAR(10)     NOT NULL DEFAULT 'media',  -- alta | media
    fonte                 VARCHAR(100)    NULL,       -- ex.: 'f_sos + MOP + f_score'
    batch_id              BIGINT          NOT NULL,
    created_at            DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX ix_oportunidade_loja_mes ON rota86.oportunidade_loja_mes (id_loja, ordem_mes, kpi);
CREATE INDEX ix_oportunidade_batch ON rota86.oportunidade_loja_mes (batch_id);
GO

/* ---------------------------------------------------------------------------
   mop_loja / mop_item — plano de execução por loja (curado a partir de
   stg_mop_base / stg_mop_item, 1 linha vigente por loja e competência).
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.mop_loja', 'U') IS NOT NULL DROP TABLE rota86.mop_loja;
CREATE TABLE rota86.mop_loja (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_loja             VARCHAR(20)     NOT NULL,
    ano_mes              CHAR(7)         NOT NULL,
    setor_promotor       VARCHAR(50)     NULL,
    canal                VARCHAR(30)     NOT NULL,
    plataforma           VARCHAR(30)     NOT NULL,
    mop_type             VARCHAR(100)    NULL,
    frequencia_visita    VARCHAR(30)     NULL,
    frequencia_leitura   VARCHAR(30)     NULL,
    caixas               VARCHAR(30)     NULL,
    tipo_atendimento     VARCHAR(50)     NULL,
    batch_id             BIGINT          NOT NULL,
    updated_at           DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT uq_mop_loja UNIQUE (id_loja, ano_mes)
);
GO

IF OBJECT_ID('rota86.mop_item', 'U') IS NOT NULL DROP TABLE rota86.mop_item;
CREATE TABLE rota86.mop_item (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    mop_loja_id     BIGINT          NOT NULL REFERENCES rota86.mop_loja(id),
    kpi             VARCHAR(10)     NULL,
    categoria       VARCHAR(200)    NULL,
    item            NVARCHAR(500)   NULL,
    objetivo        NVARCHAR(200)   NULL,
    is_supermop     BIT             NOT NULL DEFAULT 0
);
CREATE INDEX ix_mop_item_loja ON rota86.mop_item (mop_loja_id);
GO

/* ---------------------------------------------------------------------------
   agenda_visita_semanal — rota recorrente (não datada), curada de
   stg_agenda_assignacao. ordem = posição de exibição na tela "Minha semana";
   ordem_sort = chave numérica de ordenação quando ordem vem como texto
   (ex. horário); horas = duração estimada da visita, quando informada.
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.agenda_visita_semanal', 'U') IS NOT NULL DROP TABLE rota86.agenda_visita_semanal;
CREATE TABLE rota86.agenda_visita_semanal (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_loja         VARCHAR(20)     NOT NULL,
    setor_promotor  VARCHAR(50)     NOT NULL,
    ano_mes          CHAR(7)         NOT NULL,
    dia_idx          TINYINT         NOT NULL,   -- 0=segunda .. 6=domingo
    ordem            VARCHAR(20)     NULL,       -- rótulo de exibição (pode ser texto, ex. horário)
    ordem_sort        INT             NULL,       -- chave numérica de ordenação
    horas             DECIMAL(5,2)    NULL,       -- duração estimada da visita, quando informada
    batch_id         BIGINT          NOT NULL,
    CONSTRAINT uq_agenda_visita UNIQUE (id_loja, setor_promotor, ano_mes, dia_idx)
);
CREATE INDEX ix_agenda_loja ON rota86.agenda_visita_semanal (id_loja, ano_mes);
GO

/* ---------------------------------------------------------------------------
   loja_frequencia — curada de stg_loja_frequencia.
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.loja_frequencia', 'U') IS NOT NULL DROP TABLE rota86.loja_frequencia;
CREATE TABLE rota86.loja_frequencia (
    id_loja                       VARCHAR(20)     NOT NULL,
    ano_mes                        CHAR(7)         NOT NULL,
    frequencia_visita              VARCHAR(30)     NULL,
    frequencia_leitura             VARCHAR(30)     NULL,
    setor_especialista_gillette    VARCHAR(50)     NULL,
    batch_id                       BIGINT          NOT NULL,
    CONSTRAINT pk_loja_frequencia PRIMARY KEY (id_loja, ano_mes)
);
GO

/* ---------------------------------------------------------------------------
   STAR foi incorporado a rota86.leitura_star_loja_mes (07_visitas_e_leituras.sql)
   — a extração do Power BI já entrega leitura e STAR na mesma tabela/grão.
   --------------------------------------------------------------------------- */

/* ---------------------------------------------------------------------------
   Não existe tabela "visita_planejada" materializada por data — decisão
   confirmada: a visita prevista de qualquer dia é CALCULADA a partir de
   rota86.agenda_visita_semanal (catálogo já carregado) + o dia da semana da
   data pedida. Ver rota86.fn_roteiro_do_dia em 08_roteiro_e_visita_realizada.sql.
   --------------------------------------------------------------------------- */

/* ---------------------------------------------------------------------------
   justificativa — unifica os dois tipos hoje enviados ao Google Sheets
   (tipo = LOJA | VISITA). Idempotente por id_justificativa (gerado no app).
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.justificativa', 'U') IS NOT NULL DROP TABLE rota86.justificativa;
CREATE TABLE rota86.justificativa (
    id_justificativa            VARCHAR(50)     NOT NULL PRIMARY KEY,   -- gerado no cliente (app), chave de idempotência
    tipo                         VARCHAR(5)      NOT NULL,               -- LOJA | VISITA
    id_loja                      VARCHAR(20)     NOT NULL,
    cod_rota                     INT             NULL,                  -- FK lógica: dbo.bi_d_rota.COD_ROTA
    cod_pessoa                   INT             NULL,                  -- FK lógica: dbo.bi_d_pessoa.COD_PESSOA
    setor_acesso                 VARCHAR(50)     NULL,
    nota_atual                   DECIMAL(9,2)    NULL,
    mes_leitura                  CHAR(7)         NULL,
    kpi                          VARCHAR(15)     NULL,                  -- SOS | KBD | CKO | PONTO EXTRA | VISITA
    categoria                    VARCHAR(200)    NULL,
    justificativa_texto          NVARCHAR(500)   NULL,
    observacao                   NVARCHAR(500)   NULL,
    data_visita                  DATE            NULL,                  -- só tipo=VISITA
    setor_promotor                VARCHAR(50)     NULL,                  -- junto com id_loja+data_visita, localiza a visita prevista via fn_roteiro_do_dia (não há FK: o plano é calculado, não materializado)
    visit_id                     VARCHAR(30)     NULL,                  -- ID Salesforce do evento realizado, quando existir (opcional; liga a rota86.visita_realizada)
    status_visita                VARCHAR(30)     NULL,
    cod_motivo_nao_realizacao    INT             NULL REFERENCES rota86.motivo_visita(id),
    origem                       VARCHAR(20)     NULL,                  -- 'app' | 'site'
    registrado_em_app            DATETIME2(0)    NULL,
    registrado_em_servidor       DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
    status_sincronizacao         VARCHAR(15)     NOT NULL DEFAULT 'confirmado',
    CONSTRAINT ck_justificativa_tipo CHECK (tipo IN ('LOJA','VISITA'))
);
CREATE INDEX ix_justificativa_loja ON rota86.justificativa (id_loja, mes_leitura);
CREATE INDEX ix_justificativa_visita ON rota86.justificativa (id_loja, setor_promotor, data_visita);
GO

/* ---------------------------------------------------------------------------
   acao_direcionamento — a "tratativa" (feita/impedida/ajuda), hoje só
   existente no localStorage do app. Agora persistida no servidor.
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.acao_direcionamento', 'U') IS NOT NULL DROP TABLE rota86.acao_direcionamento;
CREATE TABLE rota86.acao_direcionamento (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_loja             VARCHAR(20)     NOT NULL,
    kpi                 VARCHAR(10)     NOT NULL,
    categoria           VARCHAR(200)    NULL,
    componente          VARCHAR(100)    NULL,
    ordem_mes            INT             NOT NULL,   -- competência da oportunidade tratada
    cod_pessoa           INT             NULL,       -- quem tratou (FK lógica: dbo.bi_d_pessoa.COD_PESSOA)
    status                VARCHAR(10)     NOT NULL,   -- feita | impedida | ajuda
    motivo                NVARCHAR(300)   NULL,
    observacao            NVARCHAR(500)   NULL,
    criado_em             DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT ck_acao_direcionamento_status CHECK (status IN ('feita','impedida','ajuda'))
);
CREATE INDEX ix_acao_direcionamento_loja ON rota86.acao_direcionamento (id_loja, ordem_mes, kpi);
GO
