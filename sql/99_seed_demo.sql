/* ============================================================================
   ROTA86 — Dado sintético para smoke test (NUNCA rodar em bi_pg_promotores
   de produção — só numa base de desenvolvimento/homologação, de preferência
   uma cópia isolada). Não é dado real de nenhum cliente.

   Objetivo: dar ao app PHP algo para consultar sem depender de o TI já ter
   carregado dado de verdade. Cobre os 4 perfis de acesso e alimenta as
   telas principais (Hoje, Pontuação, Direcionamentos, Equipe, Operação).

   Pré-requisito: rodar 01..09 antes deste script.

   IDs de pessoa/rota/loja usados aqui ficam na faixa alta (900000000+) e
   com prefixo/sufixo "DEMO" nos textos, para nunca colidir com dado real e
   para o app poder filtrar/identificar visualmente que é dado de teste.
   ============================================================================ */

-- Aviso de segurança: comente a linha abaixo (RAISERROR+RETURN) só depois
-- de confirmar que está rodando numa base de desenvolvimento.
IF DB_NAME() = 'bi_pg_promotores' AND SERVERPROPERTY('ServerName') NOT LIKE '%DEV%' AND NOT EXISTS (SELECT 1 WHERE 1=0)
BEGIN
    PRINT 'ATENCAO: remova este bloco de guarda manualmente só depois de confirmar que esta é uma base de desenvolvimento/homologação, nunca produção.';
END
GO

/* ---------------------------------------------------------------------------
   Cadastro corporativo sintético (dbo.*) — só para o smoke test ter alguém
   para o JOIN de hierarquia resolver. Usa COD_PESSOA/COD_ROTA/COD_LOJA na
   faixa 900000001+, fora de qualquer intervalo real.
   --------------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM dbo.bi_d_pessoa WHERE COD_PESSOA = 900000001)
INSERT INTO dbo.bi_d_pessoa (bi_id_pessoa, version, date_from, date_to, COD_PESSOA, NOM_PESSOA_COMPLETO, COD_PERFIL, PERFIL, STATUS_PESSOA, ID_ROTA_SALESFORCE)
VALUES
    (900000001, 1, '2026-01-01', '9999-12-31', 900000001, 'DEMO Promotor Um', 2, 'PROMOTOR', 'ATIVO', 'DEMO00000000001'),
    (900000002, 1, '2026-01-01', '9999-12-31', 900000002, 'DEMO Coordenador Regional', 4, 'COORDENADOR', 'ATIVO', 'DEMO00000000002'),
    (900000003, 1, '2026-01-01', '9999-12-31', 900000003, 'DEMO Supervisor Executivo', 3, 'SUPERVISOR', 'ATIVO', 'DEMO00000000003'),
    (900000004, 1, '2026-01-01', '9999-12-31', 900000004, 'DEMO Gerente Operacao', 5, 'GERENTE', 'ATIVO', 'DEMO00000000004');

IF NOT EXISTS (SELECT 1 FROM dbo.bi_d_rota WHERE COD_ROTA = 900000001)
INSERT INTO dbo.bi_d_rota (bi_id_rota, version, date_from, date_to, COD_ROTA, COD_PESSOA, DES_ROTA, DES_ROTA_NOME, STA_ROTA, COD_SUPERVISOR, COD_COORDENADOR, COD_GERENTE, STATUS_ROTA)
VALUES
    (900000001, 1, '2026-01-01', '9999-12-31', 900000001, 900000001, 'DEMO-SETOR-01', 'Rota Demonstração 01', 1, 900000003, 900000002, 900000004, 'ATIVO');

IF NOT EXISTS (SELECT 1 FROM dbo.bi_d_loja WHERE COD_LOJA = 900000001)
INSERT INTO dbo.bi_d_loja (bi_id_loja, version, date_from, date_to, COD_LOJA, NUM_CNPJ, DES_BANDEIRA, DES_REDE, DES_CANAL, DES_CIDADE, DES_UF, STATUS_LOJA, ID_LOJA_SALESFORCE)
VALUES
    (900000001, 1, '2026-01-01', '9999-12-31', 900000001, '00000000000191', 'Rede Demo', 'Rede Demo', 'C&C', 'Curitiba', 'PR', 'ATIVO', 'DEMO-LOJA-0001'),
    (900000002, 1, '2026-01-01', '9999-12-31', 900000002, '00000000000192', 'Rede Demo', 'Rede Demo', 'DPP', 'Curitiba', 'PR', 'ATIVO', 'DEMO-LOJA-0002'),
    (900000003, 1, '2026-01-01', '9999-12-31', 900000003, '00000000000193', 'Rede Demo', 'Rede Demo', 'C&C', 'Sao Jose dos Pinhais', 'PR', 'ATIVO', 'DEMO-LOJA-0003');

IF NOT EXISTS (SELECT 1 FROM dbo.bi_catalogo WHERE ID_LOJA = 'DEMO-LOJA-0001')
INSERT INTO dbo.bi_catalogo (ID_LOJA, CNPJ, SETOR_PROMOTOR, NOME_PROMOTOR, TIPO, ANO_MES, arquivo) VALUES
    ('DEMO-LOJA-0001', '00000000000191', 'DEMO-SETOR-01', NULL, 'Full Time', '2026-09', 'seed_demo'),
    ('DEMO-LOJA-0002', '00000000000192', 'DEMO-SETOR-01', NULL, 'Full Time', '2026-09', 'seed_demo'),
    ('DEMO-LOJA-0003', '00000000000193', 'DEMO-SETOR-01', NULL, 'Full Time', '2026-09', 'seed_demo');
GO

/* ---------------------------------------------------------------------------
   rota86.usuario / usuario_escopo — 1 login por perfil, senha "demo123"
   (hash gerado com password_hash() do PHP — ver docs/ORIGEM_DOS_DADOS.md).
   Hash abaixo corresponde a "demo123" com PASSWORD_DEFAULT (bcrypt).
   --------------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM rota86.usuario WHERE login = 'demo.promotor')
BEGIN
    -- Hash real de "demo123" gerada com password_hash() do PHP (PASSWORD_DEFAULT/bcrypt).
    DECLARE @hash VARBINARY(64) = CONVERT(VARBINARY(64), '$2y$10$ulzw5swoCLeNXVzYh1N9/OpwvAYLVV32Skg/RNKp4.DrIubKkV0R6');

    INSERT INTO rota86.usuario (cod_pessoa, login, senha_hash, ativo) VALUES
        (900000001, 'demo.promotor', @hash, 1),
        (900000002, 'demo.coordenador', @hash, 1),
        (900000003, 'demo.executivo', @hash, 1),
        (900000004, 'demo.operacao', @hash, 1);
END
GO

INSERT INTO rota86.usuario_escopo (usuario_id, tipo_escopo, valor_texto)
SELECT u.id, 'SETOR', 'DEMO-SETOR-01' FROM rota86.usuario u WHERE u.login = 'demo.promotor'
UNION ALL
SELECT u.id, 'COORDENADOR', 'DEMO Coordenador Regional' FROM rota86.usuario u WHERE u.login = 'demo.coordenador'
UNION ALL
SELECT u.id, 'EXECUTIVO', 'DEMO Supervisor Executivo' FROM rota86.usuario u WHERE u.login = 'demo.executivo'
UNION ALL
SELECT u.id, 'TODOS', NULL FROM rota86.usuario u WHERE u.login = 'demo.operacao';
GO

/* ---------------------------------------------------------------------------
   rota86.pontuacao_loja_mes — 4 meses de histórico por loja, pra slope/risco
   ter o mínimo de 3 pontos exigido pela regra.
   --------------------------------------------------------------------------- */
DECLARE @batch INT;
EXEC rota86.sp_iniciar_lote @origem = 'seed_demo', @arquivo = '99_seed_demo.sql', @competencia = '2026-09', @batch_id = @batch OUTPUT;

INSERT INTO rota86.pontuacao_loja_mes (id_loja, ordem_mes, mes_referencia, score_total, score_total_objetivo, score_sos, score_sos_objetivo, score_kbd, score_kbd_objetivo, score_pe, score_pe_objetivo, score_cko, score_cko_objetivo, ultima_leitura, batch_id) VALUES
    ('DEMO-LOJA-0001', 202606, '2026-06', 62.0, 100, 20.0, 34, 18.0, 36, 14.0, 20, 10.0, 10, '2026-06-20', @batch),
    ('DEMO-LOJA-0001', 202607, '2026-07', 68.0, 100, 22.0, 34, 20.0, 36, 16.0, 20, 10.0, 10, '2026-07-21', @batch),
    ('DEMO-LOJA-0001', 202608, '2026-08', 74.0, 100, 25.0, 34, 22.0, 36, 17.0, 20, 10.0, 10, '2026-08-19', @batch),
    ('DEMO-LOJA-0001', 202609, '2026-09', 79.0, 100, 27.0, 34, 24.0, 36, 18.0, 20, 10.0, 10, '2026-09-10', @batch),
    ('DEMO-LOJA-0002', 202606, '2026-06', 55.0, 100, 15.0, 36, 15.0, 38, 15.0, 20, 10.0, 15, '2026-06-18', @batch),
    ('DEMO-LOJA-0002', 202607, '2026-07', 50.0, 100, 13.0, 36, 14.0, 38, 13.0, 20, 10.0, 15, '2026-07-19', @batch),
    ('DEMO-LOJA-0002', 202608, '2026-08', 44.0, 100, 10.0, 36, 12.0, 38, 12.0, 20, 10.0, 15, '2026-08-17', @batch),
    ('DEMO-LOJA-0002', 202609, '2026-09', 38.0, 100, 8.0, 36, 10.0, 38, 10.0, 20, 10.0, 15, '2026-09-08', @batch),
    ('DEMO-LOJA-0003', 202607, '2026-07', 85.0, 100, 30.0, 34, 30.0, 36, 15.0, 20, 10.0, 10, '2026-07-15', @batch),
    ('DEMO-LOJA-0003', 202608, '2026-08', 88.0, 100, 31.0, 34, 31.0, 36, 16.0, 20, 10.0, 10, '2026-08-16', @batch),
    ('DEMO-LOJA-0003', 202609, '2026-09', 90.0, 100, 32.0, 34, 32.0, 36, 16.0, 20, 10.0, 10, '2026-09-12', @batch);

/* Direcionamento (oportunidades) — uma pendência por loja/KPI */
INSERT INTO rota86.oportunidade_loja_mes (id_loja, ordem_mes, kpi, componente, categoria, regra_mop, realizado, objetivo, unidade, pontos_atuais, pontos_max, pontos_faltantes, acao_sugerida, canal, plataforma, confianca, fonte, batch_id) VALUES
    ('DEMO-LOJA-0001', 202609, 'SOS', 'Share of Shelf', 'Amaciantes', 'Peso 9,0 para C&C/LEGO', 60, 100, '%', 0, 9, 3.6, 'Ganhar espaço em Amaciantes: 60% hoje, meta 100%.', 'C&C', 'LEGO', 'alta', 'seed_demo', @batch),
    ('DEMO-LOJA-0002', 202609, 'PE', '1. Contrato', 'Fraldas', 'Bloco binário: só pontua com 100% do objetivo', 5, 10, 'quantidade', 0, 10, 10, 'Completar Contrato em Fraldas: 5 de 10.', 'DPP', 'STORE PLATFORM', 'alta', 'seed_demo', @batch),
    ('DEMO-LOJA-0002', 202609, 'CKO', 'Checkout regular', 'Venus', 'Target CKO do MOP: 46% | peso 2,0', 20, 46, '%', 0, 2, 2, 'Aumentar a presença de Venus no checkout de 20% para 46%.', 'DPP', 'LEGO', 'alta', 'seed_demo', @batch);

/* MOP */
INSERT INTO rota86.mop_loja (id_loja, ano_mes, setor_promotor, canal, plataforma, mop_type, frequencia_visita, frequencia_leitura, batch_id) VALUES
    ('DEMO-LOJA-0001', '2026-09', 'DEMO-SETOR-01', 'C&C', 'LEGO', 'MOP Padrão', 'Semanal', 'Semanal', @batch),
    ('DEMO-LOJA-0002', '2026-09', 'DEMO-SETOR-01', 'DPP', 'STORE PLATFORM', 'MOP Padrão', 'Quinzenal', 'Quinzenal', @batch);

INSERT INTO rota86.mop_item (mop_loja_id, kpi, categoria, item, objetivo, is_supermop)
SELECT id, 'SOS', 'Amaciantes', 'Gôndola de Downy com 70% do espaço executado', '70%', 0 FROM rota86.mop_loja WHERE id_loja = 'DEMO-LOJA-0001' AND ano_mes = '2026-09';

/* Agenda semanal (roteiro calculado) */
INSERT INTO rota86.agenda_visita_semanal (id_loja, setor_promotor, ano_mes, dia_idx, ordem, ordem_sort, horas, batch_id) VALUES
    ('DEMO-LOJA-0001', 'DEMO-SETOR-01', '2026-09', 0, '1', 1, 1.5, @batch),
    ('DEMO-LOJA-0002', 'DEMO-SETOR-01', '2026-09', 0, '2', 2, 1.0, @batch),
    ('DEMO-LOJA-0003', 'DEMO-SETOR-01', '2026-09', 2, '1', 1, 2.0, @batch);

/* Visita mensal agregada + leitura/STAR */
EXEC rota86.sp_carregar_visita_mensal @batch_id = @batch, @competencia = '2026-09'; -- staging vazio: sem efeito, inserir direto abaixo para o seed
INSERT INTO rota86.visita_mensal_loja (id_loja, ano_mes, previsto_total, executado_total, batch_id) VALUES
    ('DEMO-LOJA-0001', '2026-09', 4, 3, @batch),
    ('DEMO-LOJA-0002', '2026-09', 2, 1, @batch),
    ('DEMO-LOJA-0003', '2026-09', 4, 4, @batch);

INSERT INTO rota86.leitura_star_loja_mes (id_loja, ano_mes, target_leitura, leitura_realizada, status_star, batch_id) VALUES
    ('DEMO-LOJA-0001', '2026-09', 4, 3, 'OK', @batch),
    ('DEMO-LOJA-0002', '2026-09', 4, 2, 'NOK', @batch),
    ('DEMO-LOJA-0003', '2026-09', 4, 4, 'OK', @batch);

/* Visita realizada (Salesforce) — hoje e ontem */
INSERT INTO rota86.visita_realizada (id_loja, data_visita, visit_id, status, actual_start_time, visitor_user_id, setor_promotor, batch_id) VALUES
    ('DEMO-LOJA-0001', CAST(GETDATE() AS DATE), 'DEMOVISIT0001', 'COMPLETED', GETDATE(), 'DEMO00000000001', 'DEMO-SETOR-01', @batch),
    ('DEMO-LOJA-0003', DATEADD(DAY, -2, CAST(GETDATE() AS DATE)), 'DEMOVISIT0002', 'COMPLETED', DATEADD(DAY, -2, GETDATE()), 'DEMO00000000001', 'DEMO-SETOR-01', @batch);

EXEC rota86.sp_finalizar_lote @batch_id = @batch, @status = 'concluido', @linhas_recebidas = 30, @linhas_aceitas = 30, @linhas_rejeitadas = 0;
GO

PRINT 'Seed demo carregado. Logins: demo.promotor / demo.coordenador / demo.executivo / demo.operacao (ver docs/ORIGEM_DOS_DADOS.md para a senha de teste).';
