/* ============================================================================
   ROTA86 — Schema e tabelas de staging
   Base: bi_pg_promotores (172.18.0.59)
   Não referencia nada em dbo.* (staging é espelho quase 1:1 das planilhas
   brutas do motor "Lojas Perfeitas"). batch_id liga cada linha ao lote que
   a carregou (ver 05_operacional.sql, tabela rota86.lote_carga).
   ============================================================================ */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'rota86')
    EXEC('CREATE SCHEMA rota86 AUTHORIZATION dbo');
GO

/* ---------------------------------------------------------------------------
   stg_kbdscat — leitura bruta de KBD/PS (kbdscat.xlsx, aba Planilha1)
   Grão: 1 loja x 1 pergunta x 1 mês
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.stg_kbdscat', 'U') IS NOT NULL DROP TABLE rota86.stg_kbdscat;
CREATE TABLE rota86.stg_kbdscat (
    stg_id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_loja             VARCHAR(20)     NOT NULL,   -- "ID MODULAR" = loja
    tipo_pergunta       VARCHAR(100)    NULL,
    pergunta            NVARCHAR(500)   NULL,
    mes                 DATE            NOT NULL,   -- último dia do mês (data de fechamento)
    agencia             VARCHAR(100)    NULL,
    categoria           VARCHAR(100)    NULL,
    chave_leitura       VARCHAR(200)    NULL,
    leituras            DECIMAL(9,2)    NULL,
    compliance          DECIMAL(9,4)    NULL,
    pontuacao           DECIMAL(9,4)    NOT NULL DEFAULT 0,
    realizado           DECIMAL(9,4)    NULL,
    objetivo             DECIMAL(9,4)    NULL,
    realizado_atingido  DECIMAL(9,4)    NULL,
    batch_id            BIGINT          NOT NULL,
    loaded_at           DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX ix_stg_kbdscat_loja_mes ON rota86.stg_kbdscat (id_loja, mes);
CREATE INDEX ix_stg_kbdscat_batch ON rota86.stg_kbdscat (batch_id);
GO

/* ---------------------------------------------------------------------------
   stg_f_sos — leitura bruta de SOS (f_sos.xlsx, aba Planilha1)
   Grão: 1 loja x 1 categoria x 1 mês
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.stg_f_sos', 'U') IS NOT NULL DROP TABLE rota86.stg_f_sos;
CREATE TABLE rota86.stg_f_sos (
    stg_id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_loja             VARCHAR(20)     NOT NULL,
    categoria           VARCHAR(100)    NOT NULL,
    mes                 DATE            NOT NULL,
    resultado           DECIMAL(9,4)    NULL,       -- fração 0-1 (RESULTADO * 100 = %)
    total_pg_cm         DECIMAL(9,2)    NULL,
    total_segmento_cm   DECIMAL(9,2)    NULL,
    qtde_leituras       DECIMAL(9,2)    NULL,
    objetivo_pct        DECIMAL(9,4)    NULL,
    contrato_ok         BIT             NULL,
    pontuacao_ok        BIT             NOT NULL DEFAULT 0,
    agencia             VARCHAR(100)    NULL,
    chave_leitura       VARCHAR(200)    NULL,
    acoes_conversao     NVARCHAR(500)   NULL,
    qtde_bandejas       DECIMAL(9,2)    NULL,
    batch_id            BIGINT          NOT NULL,
    loaded_at           DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX ix_stg_f_sos_loja_mes ON rota86.stg_f_sos (id_loja, mes);
CREATE INDEX ix_stg_f_sos_batch ON rota86.stg_f_sos (batch_id);
GO

/* ---------------------------------------------------------------------------
   stg_f_pe — leitura bruta de Ponto Extra (md_pe.xlsx, aba "F_Ponto extra")
   Grão: 1 loja x 1 móvel x 1 categoria x 1 mês
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.stg_f_pe', 'U') IS NOT NULL DROP TABLE rota86.stg_f_pe;
CREATE TABLE rota86.stg_f_pe (
    stg_id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_loja             VARCHAR(20)     NOT NULL,
    movel               VARCHAR(200)    NULL,
    mes                 DATE            NOT NULL,
    categoria           VARCHAR(200)    NULL,       -- inclui a linha-alvo "Total PG" do grupo Conquistas
    tipo                VARCHAR(100)    NULL,
    grupo               VARCHAR(50)     NOT NULL,   -- '1. Contrato' | '2. Outras Negociações' | '3. Conquistas'
    objetivo            DECIMAL(9,4)    NOT NULL DEFAULT 0,
    realizado           DECIMAL(9,4)    NOT NULL DEFAULT 0,
    agencia             VARCHAR(100)    NULL,
    chave_leitura       VARCHAR(200)    NULL,
    batch_id            BIGINT          NOT NULL,
    loaded_at           DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX ix_stg_f_pe_loja_mes ON rota86.stg_f_pe (id_loja, mes);
CREATE INDEX ix_stg_f_pe_batch ON rota86.stg_f_pe (batch_id);
GO

/* ---------------------------------------------------------------------------
   stg_f_cko_regular — leitura bruta de CKO regular/self-checkout
   (bases_cko.xlsx, aba "f_CKO Regular")
   Grão: 1 loja x 1 marca x 1 mês
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.stg_f_cko_regular', 'U') IS NOT NULL DROP TABLE rota86.stg_f_cko_regular;
CREATE TABLE rota86.stg_f_cko_regular (
    stg_id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_loja                 VARCHAR(20)     NOT NULL,
    mes                     DATE            NOT NULL,
    marca                   VARCHAR(100)    NOT NULL,
    qtde                    DECIMAL(9,2)    NULL,
    total_cko_realizado     DECIMAL(9,2)    NULL,
    total_cko_objetivo      DECIMAL(9,2)    NULL,
    realizado_cko_regular   DECIMAL(9,2)    NULL,
    objetivo_cko_regular    DECIMAL(9,2)    NULL,
    realizado_self_cko      DECIMAL(9,2)    NULL,
    objetivo_self_cko       DECIMAL(9,2)    NULL,
    plataforma_flag         BIT             NULL,   -- coluna 11 (índice 10) da planilha
    contrato_flag           BIT             NULL,   -- coluna 12 (índice 11) da planilha — usada para filtrar "somente_contrato"
    target_cko_regular      DECIMAL(9,4)    NULL,   -- limiar por loja quando informado (senão usa rota86.ref_config_cko)
    batch_id                BIGINT          NOT NULL,
    loaded_at               DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX ix_stg_f_cko_reg_loja_mes ON rota86.stg_f_cko_regular (id_loja, mes);
CREATE INDEX ix_stg_f_cko_reg_batch ON rota86.stg_f_cko_regular (batch_id);
GO

/* ---------------------------------------------------------------------------
   stg_f_cko_drug_chain — leitura bruta de Paredão/Papa-fila
   (bases_cko.xlsx, aba "f_CKO Drug Chain", idêntica a "f_CKO Papa Fila Paredão")
   Grão: 1 loja x 1 marca x 1 mês
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.stg_f_cko_drug_chain', 'U') IS NOT NULL DROP TABLE rota86.stg_f_cko_drug_chain;
CREATE TABLE rota86.stg_f_cko_drug_chain (
    stg_id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_loja             VARCHAR(20)     NOT NULL,
    mes                 DATE            NOT NULL,
    marca               VARCHAR(100)    NOT NULL,
    cko_tipo_atingido   VARCHAR(100)    NULL,       -- 'Não Executa' = não atingiu; qualquer outro valor = atingiu
    plataforma_flag     BIT             NULL,
    batch_id            BIGINT          NOT NULL,
    loaded_at           DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX ix_stg_f_cko_drug_loja_mes ON rota86.stg_f_cko_drug_chain (id_loja, mes);
CREATE INDEX ix_stg_f_cko_drug_batch ON rota86.stg_f_cko_drug_chain (batch_id);
GO

/* ---------------------------------------------------------------------------
   stg_mop_base — BASE MOP (MOP 3.0 *.xlsx), 1 linha por loja/competência.
   É a chave de canal/plataforma usada por todas as tabelas de peso.
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.stg_mop_base', 'U') IS NOT NULL DROP TABLE rota86.stg_mop_base;
CREATE TABLE rota86.stg_mop_base (
    stg_id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_loja                 VARCHAR(20)     NOT NULL,   -- "ID SALESFORCE" na planilha
    ano_mes                 CHAR(7)         NOT NULL,   -- 'AAAA-MM'
    setor_promotor          VARCHAR(50)     NULL,
    canal                   VARCHAR(30)     NOT NULL,   -- C&C, DPP, NMR, GMR, HFS, PHC, PERFUMARIA, LASA, CLUB
    plataforma              VARCHAR(30)     NOT NULL,   -- LEGO, STORE PLATFORM, SEM PLATAFORMA
    mop_type                VARCHAR(100)    NULL,       -- "Qual é o MOP"
    frequencia_visita       VARCHAR(30)     NULL,
    frequencia_leitura      VARCHAR(30)     NULL,
    caixas                  VARCHAR(30)     NULL,
    tipo_atendimento        VARCHAR(50)     NULL,
    batch_id                BIGINT          NOT NULL,
    loaded_at               DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT uq_stg_mop_base UNIQUE (id_loja, ano_mes, batch_id)
);
CREATE INDEX ix_stg_mop_base_loja ON rota86.stg_mop_base (id_loja, ano_mes);
GO

/* ---------------------------------------------------------------------------
   stg_mop_item — itens de execução do MOP (planograma/orientação por
   KPI/categoria), hoje texto livre em "REGRA MOP"/"item"/"objetivo".
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.stg_mop_item', 'U') IS NOT NULL DROP TABLE rota86.stg_mop_item;
CREATE TABLE rota86.stg_mop_item (
    stg_id          BIGINT IDENTITY(1,1) PRIMARY KEY,
    mop_base_stg_id BIGINT          NOT NULL REFERENCES rota86.stg_mop_base(stg_id),
    kpi             VARCHAR(10)     NULL,       -- SOS | KBD | PE | CKO | NULL (não classificado)
    categoria       VARCHAR(200)    NULL,
    item            NVARCHAR(500)   NULL,       -- texto livre do que deve ser executado
    objetivo        NVARCHAR(200)   NULL,       -- texto livre (pode ser cm, %, unidade)
    is_supermop     BIT             NOT NULL DEFAULT 0,
    batch_id        BIGINT          NOT NULL,
    loaded_at       DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX ix_stg_mop_item_base ON rota86.stg_mop_item (mop_base_stg_id);
GO

/* ---------------------------------------------------------------------------
   stg_f_score — fechamento oficial de pontuação (f_score / julho_fechado.csv
   / o mesmo arquivo hoje citado como "pontuacao/atual.csv"). É a régua
   oficial: rota86.pontuacao_loja_mes é carregada direto daqui.
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.stg_f_score', 'U') IS NOT NULL DROP TABLE rota86.stg_f_score;
CREATE TABLE rota86.stg_f_score (
    stg_id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_loja                 VARCHAR(20)     NOT NULL,
    ordem_mes                INT             NOT NULL,  -- AAAAMM
    mes_referencia           VARCHAR(20)     NULL,
    score_total              DECIMAL(9,2)    NULL,
    score_total_objetivo     DECIMAL(9,2)    NULL,
    score_sos                DECIMAL(9,2)    NULL,
    score_sos_objetivo       DECIMAL(9,2)    NULL,
    score_ps                 DECIMAL(9,2)    NULL,       -- PS = KBD
    score_ps_objetivo        DECIMAL(9,2)    NULL,
    score_pe                 DECIMAL(9,2)    NULL,
    score_pe_objetivo        DECIMAL(9,2)    NULL,
    score_cko                DECIMAL(9,2)    NULL,
    score_cko_objetivo       DECIMAL(9,2)    NULL,
    ultima_leitura           VARCHAR(20)     NULL,       -- vazio = loja sem leitura no mês
    batch_id                 BIGINT          NOT NULL,
    loaded_at                DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT uq_stg_f_score UNIQUE (id_loja, ordem_mes, batch_id)
);
CREATE INDEX ix_stg_f_score_loja_mes ON rota86.stg_f_score (id_loja, ordem_mes);
GO

/* ---------------------------------------------------------------------------
   stg_agenda_assignacao — catálogo de assignação mensal, incluindo a agenda
   semanal (ORDEM SEG..DOM) que não existe em dbo.bi_catalogo.
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.stg_agenda_assignacao', 'U') IS NOT NULL DROP TABLE rota86.stg_agenda_assignacao;
CREATE TABLE rota86.stg_agenda_assignacao (
    stg_id                      BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_loja                     VARCHAR(20)     NOT NULL,
    setor_promotor               VARCHAR(50)     NOT NULL,
    ano_mes                      CHAR(7)         NOT NULL,
    ordem_seg                    INT             NULL,
    ordem_ter                    INT             NULL,
    ordem_qua                    INT             NULL,
    ordem_qui                    INT             NULL,
    ordem_sex                    INT             NULL,
    ordem_sab                    INT             NULL,
    ordem_dom                    INT             NULL,
    batch_id                     BIGINT          NOT NULL,
    loaded_at                    DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX ix_stg_agenda_loja ON rota86.stg_agenda_assignacao (id_loja, ano_mes);
GO

/* ---------------------------------------------------------------------------
   stg_loja_frequencia — catálogo de lojas (frequência de visita/leitura),
   fonte também usada pelo app MEU DIA.
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.stg_loja_frequencia', 'U') IS NOT NULL DROP TABLE rota86.stg_loja_frequencia;
CREATE TABLE rota86.stg_loja_frequencia (
    stg_id                      BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_loja                     VARCHAR(20)     NOT NULL,
    ano_mes                      CHAR(7)         NOT NULL,
    frequencia_visita            VARCHAR(30)     NULL,
    frequencia_leitura           VARCHAR(30)     NULL,
    setor_especialista_gillette  VARCHAR(50)     NULL,
    batch_id                     BIGINT          NOT NULL,
    loaded_at                    DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT uq_stg_loja_freq UNIQUE (id_loja, ano_mes, batch_id)
);
CREATE INDEX ix_stg_loja_freq_loja ON rota86.stg_loja_frequencia (id_loja, ano_mes);
GO
