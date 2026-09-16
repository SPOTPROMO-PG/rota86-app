/* ============================================================================
   ROTA86 — Views de contrato (o que o app PHP realmente consulta)
   Resolvem nome/hierarquia por JOIN com dbo.bi_d_pessoa / dbo.bi_d_rota /
   dbo.bi_catalogo — nenhuma tabela rota86.* duplica esse cadastro.
   Seleção "vigente" via GETDATE() BETWEEN date_from AND date_to (SCD2).
   COD_PESSOA/COD_SUPERVISOR/COD_COORDENADOR = 0 é tratado como vago/nulo,
   conforme 04_ESPECIFICACAO_S3_ROTA86.md.
   ============================================================================ */

CREATE OR ALTER VIEW rota86.vw_hierarquia AS
SELECT
    r.COD_ROTA,
    r.DES_ROTA                     AS setor_promotor,
    r.DES_ROTA_NOME                AS nome_rota,
    r.STATUS_ROTA                  AS status_rota,
    NULLIF(r.COD_PESSOA, 0)        AS cod_promotor,
    promotor.NOM_PESSOA_COMPLETO   AS nome_promotor,
    promotor.STATUS_PESSOA         AS status_promotor,
    NULLIF(r.COD_SUPERVISOR, 0)    AS cod_coordenador_regional,
    supervisor.NOM_PESSOA_COMPLETO AS nome_coordenador_regional,
    NULLIF(r.COD_COORDENADOR, 0)   AS cod_coordenador_lider,
    coordenador.NOM_PESSOA_COMPLETO AS nome_coordenador_lider,
    NULLIF(r.COD_GERENTE, 0)       AS cod_executivo,
    gerente.NOM_PESSOA_COMPLETO    AS nome_executivo,
    r.date_from,
    r.date_to
FROM dbo.bi_d_rota r
LEFT JOIN dbo.bi_d_pessoa promotor
       ON promotor.COD_PESSOA = r.COD_PESSOA AND r.COD_PESSOA <> 0
      AND GETDATE() BETWEEN promotor.date_from AND promotor.date_to
LEFT JOIN dbo.bi_d_pessoa supervisor
       ON supervisor.COD_PESSOA = r.COD_SUPERVISOR AND r.COD_SUPERVISOR <> 0
      AND GETDATE() BETWEEN supervisor.date_from AND supervisor.date_to
LEFT JOIN dbo.bi_d_pessoa coordenador
       ON coordenador.COD_PESSOA = r.COD_COORDENADOR AND r.COD_COORDENADOR <> 0
      AND GETDATE() BETWEEN coordenador.date_from AND coordenador.date_to
LEFT JOIN dbo.bi_d_pessoa gerente
       ON gerente.COD_PESSOA = r.COD_GERENTE AND r.COD_GERENTE <> 0
      AND GETDATE() BETWEEN gerente.date_from AND gerente.date_to
WHERE GETDATE() BETWEEN r.date_from AND r.date_to;
GO

/* ---------------------------------------------------------------------------
   vw_carteira_atual — 1 linha por vínculo vigente da competência mais
   recente de dbo.bi_catalogo. Aplica DISTINCT para contornar a duplicação
   4x já documentada (04_ESPECIFICACAO_S3_ROTA86.md) — resolver a causa raiz
   no ETL corporativo continua sendo a correção definitiva.
   --------------------------------------------------------------------------- */
CREATE OR ALTER VIEW rota86.vw_carteira_atual AS
WITH competencia_mais_recente AS (
    SELECT MAX(ANO_MES) AS ano_mes FROM dbo.bi_catalogo
),
catalogo_dedup AS (
    SELECT DISTINCT
        c.ID_LOJA, c.CNPJ, c.SETOR_PROMOTOR, c.TIPO, c.ANO_MES
    FROM dbo.bi_catalogo c
    CROSS JOIN competencia_mais_recente cmr
    WHERE c.ANO_MES = cmr.ano_mes
)
SELECT
    cd.ID_LOJA        AS id_loja,
    cd.CNPJ           AS cnpj,
    cd.TIPO           AS tipo_atendimento,
    cd.ANO_MES        AS ano_mes,
    h.setor_promotor,
    h.cod_promotor, h.nome_promotor, h.status_promotor,
    h.cod_coordenador_regional, h.nome_coordenador_regional,
    h.cod_coordenador_lider, h.nome_coordenador_lider,
    h.cod_executivo, h.nome_executivo,
    CASE WHEN h.cod_promotor IS NULL THEN 1 ELSE 0 END AS rota_vaga,
    loja.NOM_FANTASIA AS nome_loja,
    loja.DES_REDE     AS rede,
    loja.DES_CANAL    AS canal,
    loja.DES_CIDADE   AS cidade,
    loja.DES_UF       AS uf,
    CONCAT(loja.DES_CIDADE, '/', loja.DES_UF) AS cidade_uf
FROM catalogo_dedup cd
LEFT JOIN rota86.vw_hierarquia h ON h.setor_promotor = cd.SETOR_PROMOTOR
LEFT JOIN dbo.bi_d_loja loja
       ON loja.ID_LOJA_SALESFORCE = cd.ID_LOJA
      AND GETDATE() BETWEEN loja.date_from AND loja.date_to;
GO

/* ---------------------------------------------------------------------------
   vw_direcionamento_atual — direcionamento da competência mais recente,
   já com hierarquia resolvida (é o que a tela "O que falta executar" lê).
   --------------------------------------------------------------------------- */
CREATE OR ALTER VIEW rota86.vw_direcionamento_atual AS
WITH competencia_mais_recente AS (
    SELECT MAX(ordem_mes) AS ordem_mes FROM rota86.oportunidade_loja_mes
)
SELECT
    o.id, o.id_loja, o.ordem_mes, o.kpi, o.componente, o.categoria,
    o.regra_mop, o.realizado, o.objetivo, o.unidade,
    o.pontos_atuais, o.pontos_max, o.pontos_faltantes, o.acao_sugerida,
    o.canal, o.plataforma, o.confianca, o.fonte,
    ca.setor_promotor, ca.nome_promotor, ca.nome_coordenador_regional, ca.nome_executivo
FROM rota86.oportunidade_loja_mes o
CROSS JOIN competencia_mais_recente cmr
LEFT JOIN rota86.vw_carteira_atual ca ON ca.id_loja = o.id_loja
WHERE o.ordem_mes = cmr.ordem_mes;
GO
