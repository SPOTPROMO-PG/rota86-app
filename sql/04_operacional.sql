/* ============================================================================
   ROTA86 — Tabelas operacionais (auditoria de carga, e-mail)
   ============================================================================ */

/* ---------------------------------------------------------------------------
   lote_carga — 1 linha por execução do agente de carga. Toda tabela stg_*
   e fato carrega um batch_id que aponta para cá.
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.lote_carga', 'U') IS NOT NULL DROP TABLE rota86.lote_carga;
CREATE TABLE rota86.lote_carga (
    batch_id            BIGINT IDENTITY(1,1) PRIMARY KEY,
    origem               VARCHAR(50)     NOT NULL,   -- kbdscat | f_sos | md_pe | bases_cko | mop | f_score | agenda | frequencia
    arquivo               NVARCHAR(300)   NULL,
    competencia           CHAR(7)         NULL,       -- 'AAAA-MM'
    iniciado_em           DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
    finalizado_em         DATETIME2(0)    NULL,
    status                 VARCHAR(15)     NOT NULL DEFAULT 'em_andamento',  -- em_andamento | concluido | rejeitado | erro
    linhas_recebidas       INT             NULL,
    linhas_aceitas         INT             NULL,
    linhas_rejeitadas      INT             NULL,
    checksum               VARCHAR(64)     NULL,
    erro                    NVARCHAR(1000)  NULL,
    CONSTRAINT ck_lote_carga_status CHECK (status IN ('em_andamento','concluido','rejeitado','erro'))
);
GO

/* ---------------------------------------------------------------------------
   destinatario_email — cadastro de quem recebe o fechamento diário (hoje
   aba CONFIG_EMAIL_JUSTIFICATIVAS do Sheets).
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.destinatario_email', 'U') IS NOT NULL DROP TABLE rota86.destinatario_email;
CREATE TABLE rota86.destinatario_email (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    tipo        VARCHAR(15)     NOT NULL,   -- EXECUTIVO | GERAL
    nome        NVARCHAR(200)   NOT NULL,
    email       VARCHAR(200)    NOT NULL,
    ativo       BIT             NOT NULL DEFAULT 1,
    CONSTRAINT ck_destinatario_email_tipo CHECK (tipo IN ('EXECUTIVO','GERAL')),
    CONSTRAINT uq_destinatario_email UNIQUE (tipo, email)
);
GO

/* ---------------------------------------------------------------------------
   envio_email — log idempotente do disparo diário (hoje aba
   LOG_EMAIL_JUSTIFICATIVAS do Sheets). chave_envio evita reenvio no mesmo dia.
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.envio_email', 'U') IS NOT NULL DROP TABLE rota86.envio_email;
CREATE TABLE rota86.envio_email (
    chave_envio         VARCHAR(200)    NOT NULL PRIMARY KEY,  -- data|tipo|nome|email normalizados
    data_referencia      DATE            NOT NULL,
    tipo                  VARCHAR(15)     NOT NULL,
    nome                  NVARCHAR(200)   NULL,
    email                 VARCHAR(200)    NOT NULL,
    qtd_justificativas    INT             NOT NULL DEFAULT 0,
    enviado_em            DATETIME2(0)    NULL,
    status                 VARCHAR(15)     NOT NULL DEFAULT 'pendente',  -- pendente | sucesso | erro
    erro                   NVARCHAR(500)   NULL,
    CONSTRAINT ck_envio_email_status CHECK (status IN ('pendente','sucesso','erro'))
);
CREATE INDEX ix_envio_email_data ON rota86.envio_email (data_referencia);
GO
