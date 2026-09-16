/* ============================================================================
   ROTA86 — Roteiro do dia (calculado) e visita realizada (Salesforce mensal)

   Modelo confirmado com o usuário: não existe tabela de "visita planejada"
   por data. O roteiro de qualquer dia é CALCULADO em SQL a partir de
   rota86.agenda_visita_semanal (que já vem do catálogo — ORDEM SEG..DOM) +
   o dia da semana da data pedida. O lado "realizado" vem do report mensal
   do Salesforce (pasta "visitas mensal"), que é reenviado várias vezes ao
   longo do dia — cada carga SUBSTITUI o mês corrente inteiro (mesma regra
   de "visita_mensal_loja"/"leitura_star_loja_mes"), então a visita de hoje
   está sempre atualizada com o último upload.

   Junção planejado x realizado: SETOR + LOJA + DIA (mesma chave presente
   nas duas fontes), como confirmado pelo usuário.
   ============================================================================ */

/* ---------------------------------------------------------------------------
   STAGING — report mensal de visitas do Salesforce (recarregado várias
   vezes ao dia; grão = 1 evento de visita).
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.stg_visita_realizada', 'U') IS NOT NULL DROP TABLE rota86.stg_visita_realizada;
CREATE TABLE rota86.stg_visita_realizada (
    stg_id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_loja             VARCHAR(20)     NOT NULL,   -- "FULL SALESFORCE ID" / "ID SALESFORCE COMPLETO"
    visit_id            VARCHAR(30)     NULL,       -- "VISIT ID" / "ID DA VISITA" — pode vir vazio (fallback por loja+data)
    status               VARCHAR(30)     NOT NULL,   -- ex.: COMPLETED, CLOSED - SYNCING, SCHEDULED...
    actual_start_time    DATETIME2(0)    NULL,       -- "ACTUAL START TIME" / "HORA DE INÍCIO REAL"
    visitor_user_id      VARCHAR(20)     NULL,       -- ID Salesforce do promotor (15/18 chars, texto) — informativo, não usado para achar o setor
    visitor_full_name    VARCHAR(50)     NULL,       -- ATENÇÃO: neste export o Salesforce grava o SETOR PROMOTOR neste campo, não o nome da pessoa
    batch_id             BIGINT          NOT NULL,
    loaded_at            DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX ix_stg_visita_realizada_loja ON rota86.stg_visita_realizada (id_loja, actual_start_time);
GO

/* ---------------------------------------------------------------------------
   FATO — visita realizada, curada. Considerada "válida" (contável como
   visita feita) somente quando status IN ('COMPLETED','CLOSED - SYNCING')
   — mesma regra já usada hoje em gerar_rota85.py.
   Substituição completa por competência a cada carga (sp_carregar_visita_realizada).
   Dedup: por visit_id quando existe; senão por (id_loja, data, visitor).
   --------------------------------------------------------------------------- */
IF OBJECT_ID('rota86.visita_realizada', 'U') IS NOT NULL DROP TABLE rota86.visita_realizada;
CREATE TABLE rota86.visita_realizada (
    id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_loja             VARCHAR(20)     NOT NULL,
    data_visita          DATE            NOT NULL,
    ano_mes               AS (CONVERT(CHAR(7), data_visita, 120)) PERSISTED,
    visit_id              VARCHAR(30)     NULL,
    status                 VARCHAR(30)     NOT NULL,
    valida                  AS (CASE WHEN status IN ('COMPLETED','CLOSED - SYNCING') THEN 1 ELSE 0 END) PERSISTED,
    actual_start_time       DATETIME2(0)    NULL,
    visitor_user_id         VARCHAR(20)     NULL,
    setor_promotor           VARCHAR(50)     NOT NULL,   -- = stg.visitor_full_name (é o setor, não o nome — ver comentário na staging)
    batch_id                 BIGINT          NOT NULL,
    carregado_em              DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX ix_visita_realizada_loja_dia ON rota86.visita_realizada (id_loja, data_visita);
CREATE INDEX ix_visita_realizada_setor_loja_dia ON rota86.visita_realizada (setor_promotor, id_loja, data_visita);
CREATE INDEX ix_visita_realizada_mes ON rota86.visita_realizada (ano_mes);
CREATE UNIQUE INDEX uq_visita_realizada_visit_id ON rota86.visita_realizada (visit_id) WHERE visit_id IS NOT NULL;
GO

/* ---------------------------------------------------------------------------
   sp_carregar_visita_realizada — substitui o mês inteiro a cada carga
   (o Salesforce mensal é sempre um snapshot completo da competência, não
   um incremento). O setor vem direto de stg.visitor_full_name (confirmado
   pelo usuário: neste export do Salesforce esse campo carrega o SETOR
   PROMOTOR, não o nome da pessoa) — não depende de resolver pessoa/hierarquia.
   --------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE rota86.sp_carregar_visita_realizada
    @batch_id BIGINT,
    @competencia CHAR(7)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;
        DELETE FROM rota86.visita_realizada WHERE ano_mes = @competencia;

        INSERT INTO rota86.visita_realizada
            (id_loja, data_visita, visit_id, status, actual_start_time,
             visitor_user_id, setor_promotor, batch_id)
        SELECT
            s.id_loja,
            CAST(s.actual_start_time AS DATE)  AS data_visita,
            s.visit_id,
            s.status,
            s.actual_start_time,
            s.visitor_user_id,
            LTRIM(RTRIM(s.visitor_full_name))  AS setor_promotor,
            s.batch_id
        FROM rota86.stg_visita_realizada s
        WHERE s.batch_id = @batch_id
          AND CONVERT(CHAR(7), s.actual_start_time, 120) = @competencia
          AND s.visitor_full_name IS NOT NULL;
    COMMIT;
END
GO

/* ---------------------------------------------------------------------------
   fn_roteiro_do_dia — o roteiro de uma data: planejado (agenda semanal,
   calculado pelo dia da semana) LEFT JOIN realizado (visita_realizada),
   casado por SETOR + LOJA + DIA.
   A fórmula de dia_idx é independente de @@DATEFIRST (0=segunda..6=domingo,
   igual ao "diaIdx" já usado no app hoje).
   --------------------------------------------------------------------------- */
CREATE OR ALTER FUNCTION rota86.fn_roteiro_do_dia (@data DATE)
RETURNS TABLE
AS
RETURN
(
    WITH parametro AS (
        SELECT
            @data AS data_visita,
            (DATEPART(WEEKDAY, @data) + @@DATEFIRST - 2) % 7 AS dia_idx,
            CONVERT(CHAR(7), @data, 120) AS ano_mes
    )
    SELECT
        ag.id_loja,
        ag.setor_promotor,
        p.dia_idx,
        p.data_visita,
        ag.ordem,
        h.cod_promotor,
        h.nome_promotor,
        h.nome_coordenador_regional,
        h.nome_executivo,
        vr.status                  AS status_realizado,
        vr.valida                  AS visita_valida,
        vr.actual_start_time,
        vr.visit_id,
        CASE
            WHEN vr.id IS NULL THEN 'PENDENTE'
            WHEN vr.valida = 1 THEN 'REALIZADA'
            ELSE 'FORA_DO_PLANO_OU_NAO_VALIDA'
        END AS status_roteiro
    FROM parametro p
    JOIN rota86.agenda_visita_semanal ag
      ON ag.ano_mes = p.ano_mes AND ag.dia_idx = p.dia_idx
    LEFT JOIN rota86.vw_hierarquia h ON h.setor_promotor = ag.setor_promotor
    LEFT JOIN rota86.visita_realizada vr
           ON vr.id_loja = ag.id_loja
          AND vr.setor_promotor = ag.setor_promotor
          AND vr.data_visita = p.data_visita
);
GO

/* Exemplo de uso: SELECT * FROM rota86.fn_roteiro_do_dia(CAST(GETDATE() AS DATE)); */
