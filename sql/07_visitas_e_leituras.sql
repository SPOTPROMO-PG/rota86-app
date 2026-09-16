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
    status_star            VARCHAR(3)      NOT NULL,   -- 'OK' | 'NOK' (normalizado; NOK = pendência ativa, OK = recuperada)
    batch_id               BIGINT          NOT NULL,
    carregado_em            DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT pk_leitura_star_loja_mes PRIMARY KEY (id_loja, ano_mes),
    CONSTRAINT ck_leitura_star_status CHECK (status_star IN ('OK','NOK'))
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
                ELSE 'NOK'  -- ausência de leitura de STAR é tratada como pendência, não como "sem dado"
            END AS status_star,
            batch_id
        FROM rota86.stg_leitura_star_loja
        WHERE batch_id = @batch_id AND ano_mes = @competencia;
    COMMIT;
END
GO
