/* ============================================================================
   ROTA86 — Procedures utilitárias
   Escopo desta fase: controle de lote, carga direta do fechamento oficial
   (passthrough, sem regra de negócio) e upserts idempotentes usados pelo
   app. O CÁLCULO de PS/SOS/PE/CKO/oportunidades continua no motor Python
   (ver 07_ARQUITETURA_ALVO.md seção 2) — não há stored procedure de
   recálculo aqui de propósito.
   ============================================================================ */

CREATE OR ALTER PROCEDURE rota86.sp_iniciar_lote
    @origem VARCHAR(50),
    @arquivo NVARCHAR(300),
    @competencia CHAR(7),
    @batch_id BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO rota86.lote_carga (origem, arquivo, competencia, status)
    VALUES (@origem, @arquivo, @competencia, 'em_andamento');
    SET @batch_id = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE rota86.sp_finalizar_lote
    @batch_id BIGINT,
    @status VARCHAR(15),               -- concluido | rejeitado | erro
    @linhas_recebidas INT = NULL,
    @linhas_aceitas INT = NULL,
    @linhas_rejeitadas INT = NULL,
    @erro NVARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE rota86.lote_carga
       SET status = @status,
           finalizado_em = SYSUTCDATETIME(),
           linhas_recebidas = @linhas_recebidas,
           linhas_aceitas = @linhas_aceitas,
           linhas_rejeitadas = @linhas_rejeitadas,
           erro = @erro
     WHERE batch_id = @batch_id;
END
GO

/* ---------------------------------------------------------------------------
   sp_carregar_pontuacao_do_stage — passthrough de rota86.stg_f_score para
   rota86.pontuacao_loja_mes. Não recalcula nada: f_score já é a régua
   oficial. Upsert por (id_loja, ordem_mes).
   --------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE rota86.sp_carregar_pontuacao_do_stage
    @batch_id BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    MERGE rota86.pontuacao_loja_mes AS destino
    USING (
        SELECT id_loja, ordem_mes, mes_referencia,
               score_total, score_total_objetivo,
               score_sos, score_sos_objetivo,
               score_ps AS score_kbd, score_ps_objetivo AS score_kbd_objetivo,
               score_pe, score_pe_objetivo,
               score_cko, score_cko_objetivo,
               TRY_CONVERT(DATE, NULLIF(ultima_leitura, '')) AS ultima_leitura,
               batch_id
        FROM rota86.stg_f_score
        WHERE batch_id = @batch_id
    ) AS origem
    ON destino.id_loja = origem.id_loja AND destino.ordem_mes = origem.ordem_mes
    WHEN MATCHED THEN UPDATE SET
        mes_referencia = origem.mes_referencia,
        score_total = origem.score_total, score_total_objetivo = origem.score_total_objetivo,
        score_sos = origem.score_sos, score_sos_objetivo = origem.score_sos_objetivo,
        score_kbd = origem.score_kbd, score_kbd_objetivo = origem.score_kbd_objetivo,
        score_pe = origem.score_pe, score_pe_objetivo = origem.score_pe_objetivo,
        score_cko = origem.score_cko, score_cko_objetivo = origem.score_cko_objetivo,
        ultima_leitura = origem.ultima_leitura,
        batch_id = origem.batch_id,
        updated_at = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT
        (id_loja, ordem_mes, mes_referencia, score_total, score_total_objetivo,
         score_sos, score_sos_objetivo, score_kbd, score_kbd_objetivo,
         score_pe, score_pe_objetivo, score_cko, score_cko_objetivo,
         ultima_leitura, batch_id)
    VALUES
        (origem.id_loja, origem.ordem_mes, origem.mes_referencia, origem.score_total, origem.score_total_objetivo,
         origem.score_sos, origem.score_sos_objetivo, origem.score_kbd, origem.score_kbd_objetivo,
         origem.score_pe, origem.score_pe_objetivo, origem.score_cko, origem.score_cko_objetivo,
         origem.ultima_leitura, origem.batch_id);
END
GO

/* ---------------------------------------------------------------------------
   sp_upsert_justificativa — usada pelo app PHP no envio de justificativa
   (nota ou visita). Idempotente por id_justificativa: reenvio do mesmo id
   confirma a linha existente sem duplicar (mesma regra do Apps Script hoje).
   Retorna 1 linha: (id_justificativa, duplicado).
   --------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE rota86.sp_upsert_justificativa
    @id_justificativa VARCHAR(50),
    @tipo VARCHAR(5),
    @id_loja VARCHAR(20),
    @cod_rota INT = NULL,
    @cod_pessoa INT = NULL,
    @setor_acesso VARCHAR(50) = NULL,
    @nota_atual DECIMAL(9,2) = NULL,
    @mes_leitura CHAR(7) = NULL,
    @kpi VARCHAR(15) = NULL,
    @categoria VARCHAR(200) = NULL,
    @justificativa_texto NVARCHAR(500) = NULL,
    @observacao NVARCHAR(500) = NULL,
    @data_visita DATE = NULL,
    @setor_promotor VARCHAR(50) = NULL,   -- junto com id_loja+data_visita, localiza a visita prevista via rota86.fn_roteiro_do_dia
    @visit_id VARCHAR(30) = NULL,
    @status_visita VARCHAR(30) = NULL,
    @cod_motivo_nao_realizacao INT = NULL,
    @origem VARCHAR(20) = NULL,
    @registrado_em_app DATETIME2(0) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM rota86.justificativa WHERE id_justificativa = @id_justificativa)
    BEGIN
        SELECT @id_justificativa AS id_justificativa, CAST(1 AS BIT) AS duplicado;
        RETURN;
    END

    IF @tipo NOT IN ('LOJA', 'VISITA')
    BEGIN
        RAISERROR('tipo deve ser LOJA ou VISITA', 16, 1);
        RETURN;
    END
    IF @tipo = 'LOJA' AND @mes_leitura IS NULL
    BEGIN
        RAISERROR('justificativa de LOJA exige mes_leitura', 16, 1);
        RETURN;
    END
    IF @tipo = 'VISITA' AND @data_visita IS NULL
    BEGIN
        RAISERROR('justificativa de VISITA exige data_visita', 16, 1);
        RETURN;
    END

    INSERT INTO rota86.justificativa (
        id_justificativa, tipo, id_loja, cod_rota, cod_pessoa, setor_acesso,
        nota_atual, mes_leitura, kpi, categoria, justificativa_texto, observacao,
        data_visita, setor_promotor, visit_id, status_visita,
        cod_motivo_nao_realizacao, origem, registrado_em_app
    ) VALUES (
        @id_justificativa, @tipo, @id_loja, @cod_rota, @cod_pessoa, @setor_acesso,
        @nota_atual, @mes_leitura, @kpi, @categoria, @justificativa_texto, @observacao,
        @data_visita, @setor_promotor, @visit_id, @status_visita,
        @cod_motivo_nao_realizacao, @origem, @registrado_em_app
    );

    SELECT @id_justificativa AS id_justificativa, CAST(0 AS BIT) AS duplicado;
END
GO

/* ---------------------------------------------------------------------------
   sp_registrar_acao_direcionamento — usada pelo app quando o promotor marca
   "feita"/"impedida"/"ajuda" num item de direcionamento. Upsert por
   (id_loja, kpi, categoria, componente, ordem_mes, cod_pessoa): a última
   marcação da mesma pessoa no mesmo item substitui a anterior.
   --------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE rota86.sp_registrar_acao_direcionamento
    @id_loja VARCHAR(20),
    @kpi VARCHAR(10),
    @categoria VARCHAR(200) = NULL,
    @componente VARCHAR(100) = NULL,
    @ordem_mes INT,
    @cod_pessoa INT = NULL,
    @status VARCHAR(10),
    @motivo NVARCHAR(300) = NULL,
    @observacao NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @status NOT IN ('feita','impedida','ajuda')
    BEGIN
        RAISERROR('status deve ser feita, impedida ou ajuda', 16, 1);
        RETURN;
    END
    INSERT INTO rota86.acao_direcionamento
        (id_loja, kpi, categoria, componente, ordem_mes, cod_pessoa, status, motivo, observacao)
    VALUES
        (@id_loja, @kpi, @categoria, @componente, @ordem_mes, @cod_pessoa, @status, @motivo, @observacao);
END
GO

/* ---------------------------------------------------------------------------
   sp_upsert_feriado — carga anual do calendário de feriados
   (calendario_excecoes_feriados.csv). Upsert por data: atualiza a
   descrição se a data já existir, insere se for nova. Não apaga nada —
   feriados de anos anteriores continuam valendo para consulta histórica.
   --------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE rota86.sp_upsert_feriado
    @data DATE,
    @descricao NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    MERGE rota86.feriado AS destino
    USING (SELECT @data AS data, @descricao AS descricao) AS origem
    ON destino.data = origem.data
    WHEN MATCHED THEN UPDATE SET descricao = origem.descricao
    WHEN NOT MATCHED THEN INSERT (data, descricao) VALUES (origem.data, origem.descricao);
END
GO
