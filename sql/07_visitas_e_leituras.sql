/* ============================================================================
   ROTA86 — Visitas mensal (agregado) e Leitura+STAR (extração Power BI)
   Ambas seguem a mesma regra de negócio já documentada em 01_MAPA_ATUAL.md:
   "Cada arquivo novo é tratado como uma substituição completa da
   competência" — NUNCA soma ao que já existia naquele mês, sempre troca o
   mês inteiro. Por isso a carga usa DELETE+INSERT dentro de uma transação
   (rota86.sp_carregar_visita_mensal / sp_carregar_leitura_star), não MERGE
   incremental como em rota86.pontuacao_loja_mes (que é aditiva mês a mês).

   Isso é DIFERENTE do roteiro do dia (rota86.fn_roteiro_do_dia, calculado
   a partir de rota86.agenda_visita_semanal — ver 08_roteiro_e_visita_realizada.sql),
   que é a agenda dia a dia. Esta tabela aqui é o AGREGADO mensal por loja
   (previsto total x executado total), grão de snapshot mensal.

   NOTA sobre leitura+STAR: confirmado nos dados reais (16/09/2026) que
   hoje `leitura_por_loja.csv` (target/leitura, ~2.937 lojas) e
   `lojs_star.csv` (status STAR, só ~24 lojas — as poucas com pendência ou
   recém-recuperadas) continuam vindo como DOIS arquivos separados, não
   uma extração já unificada do Power BI. Decisão (confirmada com o
   usuário): por ora os arquivos continuam separados na origem; existe um
   motor de união (`CODIGO/unir_leitura_star.py`) que faz o LEFT JOIN por
   ID_LOJA e gera um CSV único (`retailx_leituras.csv`) no formato que
   `rota86.stg_leitura_star_loja` espera — é esse arquivo unificado que
   deve ser carregado no staging, não os dois brutos direto. Loja ausente
   de `lojs_star.csv` vira `status_star = NULL` (nunca esteve na lista de
   STAR daquela competência), nunca `NOK` por padrão — ver comentário na
   coluna abaixo.
   ============================================================================ */

/* ---------------------------------------------------------------------------
   STAGING
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.stg_visita_mensal_loja', 'U') IS NOT NULL DROP TABLE rota86.stg_visita_mensal_loja;
CREATE TABLE rota86.stg_visita_mensal_loja (
    stg_id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_loja             VARCHAR(20)     NOT NULL,
    ano_mes              CHAR(7)         NOT NULL,
    previsto_total        INT             NULL,       -- "PREVISTO TOTAL"
    executado_total       INT             NULL,       -- "TOTAL EXECUTADO VISITAS"
    batch_id              BIGINT          NOT NULL,
    loaded_at              DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX ix_stg_visita_mensal_loja ON rota86.stg_visita_mensal_loja (id_loja, ano_mes);
GO

IF OBJECT_ID('rota86.stg_leitura_star_loja', 'U') IS NOT NULL DROP TABLE rota86.stg_leitura_star_loja;
CREATE TABLE rota86.stg_leitura_star_loja (
    stg_id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_loja             VARCHAR(20)     NOT NULL,
    ano_mes              CHAR(7)         NOT NULL,
    target_leitura        DECIMAL(9,2)    NULL,       -- "SOMA DE TOTAL TARGET DE LEITURA"
    leitura_realizada     DECIMAL(9,2)    NULL,       -- "SOMA DE TOTAL LEITURA"
    status_star_raw       VARCHAR(10)     NULL,       -- valor cru vindo do Power BI: OK/NOK, SIM/NÃO — normalizado no destino
    batch_id              BIGINT          NOT NULL,
    loaded_at              DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX ix_stg_leitura_star_loja ON rota86.stg_leitura_star_loja (id_loja, ano_mes);
GO

/* ---------------------------------------------------------------------------
   FATO (curado, 1 linha vigente por loja x competência — substituição total)
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.visita_mensal_loja', 'U') IS NOT NULL DROP TABLE rota86.visita_mensal_loja;
CREATE TABLE rota86.visita_mensal_loja (
    id_loja             VARCHAR(20)     NOT NULL,
    ano_mes              CHAR(7)         NOT NULL,
    previsto_total        INT             NULL,
    executado_total       INT             NULL,
    pct_compliance         AS (CASE WHEN previsto_total > 0
                                THEN CAST(executado_total AS DECIMAL(9,4)) / previsto_total
                                ELSE NULL END) PERSISTED,
    batch_id               BIGINT          NOT NULL,
    carregado_em            DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT pk_visita_mensal_loja PRIMARY KEY (id_loja, ano_mes)
);
CREATE INDEX ix_visita_mensal_mes ON rota86.visita_mensal_loja (ano_mes);
GO

IF OBJECT_ID('rota86.leitura_star_loja_mes', 'U') IS NOT NULL DROP TABLE rota86.leitura_star_loja_mes;
CREATE TABLE rota86.leitura_star_loja_mes (
    id_loja             VARCHAR(20)     NOT NULL,
    ano_mes              CHAR(7)         NOT NULL,
    target_leitura        DECIMAL(9,2)    NULL,
    leitura_realizada     DECIMAL(9,2)    NULL,
    pct_leitura            AS (CASE WHEN target_leitura > 0
                                THEN CAST(leitura_realizada AS DECIMAL(9,4)) / target_leitura
                                ELSE NULL END) PERSISTED,
    status_star            VARCHAR(3)      NULL,       -- 'OK' | 'NOK' | NULL. NULL = loja não está na lista de STAR desta
                                                          -- competência (não é pendência — é ausência de registro; confirmado
                                                          -- nos dados reais em 16/09/2026: lojs_star.csv só lista ~24 de 2.937
                                                          -- lojas). NOK = pendência ativa listada; OK = recuperada.
    batch_id               BIGINT          NOT NULL,
    carregado_em            DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT pk_leitura_star_loja_mes PRIMARY KEY (id_loja, ano_mes),
    CONSTRAINT ck_leitura_star_status CHECK (status_star IN ('OK','NOK') OR status_star IS NULL)
);
CREATE INDEX ix_leitura_star_mes ON rota86.leitura_star_loja_mes (ano_mes);
GO

/* ---------------------------------------------------------------------------
   PROCEDURES DE CARGA — substituição completa da competência (DELETE+INSERT
   transacional), nunca soma ao que já existia no mês.
   --------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE rota86.sp_carregar_visita_mensal
    @batch_id BIGINT,
    @competencia CHAR(7)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;
        DELETE FROM rota86.visita_mensal_loja WHERE ano_mes = @competencia;
        INSERT INTO rota86.visita_mensal_loja (id_loja, ano_mes, previsto_total, executado_total, batch_id)
        SELECT id_loja, ano_mes, previsto_total, executado_total, batch_id
        FROM rota86.stg_visita_mensal_loja
        WHERE batch_id = @batch_id AND ano_mes = @competencia;
    COMMIT;
END
GO

CREATE OR ALTER PROCEDURE rota86.sp_carregar_leitura_star
    @batch_id BIGINT,
    @competencia CHAR(7)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;
        DELETE FROM rota86.leitura_star_loja_mes WHERE ano_mes = @competencia;
        INSERT INTO rota86.leitura_star_loja_mes (id_loja, ano_mes, target_leitura, leitura_realizada, status_star, batch_id)
        SELECT
            id_loja, ano_mes, target_leitura, leitura_realizada,
            CASE
                WHEN UPPER(status_star_raw) IN ('OK', 'SIM') THEN 'OK'
                WHEN UPPER(status_star_raw) IN ('NOK', 'NÃO', 'NAO') THEN 'NOK'
                ELSE NULL  -- loja fora da lista de STAR desta competência — ausência de registro, não pendência (ver comentário na tabela)
            END AS status_star,
            batch_id
        FROM rota86.stg_leitura_star_loja
        WHERE batch_id = @batch_id AND ano_mes = @competencia;
    COMMIT;
END
GO
