# Origem dos dados — "de onde vem cada coisa"

## Cadastro de pessoas, rotas e lojas — já existe, não duplicar

| Tabela | O que é | Fonte |
|---|---|---|
| `dbo.bi_d_pessoa` | Pessoa (promotor/coordenador/executivo), histórico versionado | Já existe no banco corporativo (`bi_pg_promotores`), carregado por processo próprio de TI/BI, fora deste projeto |
| `dbo.bi_d_rota` | Vínculo pessoa↔setor↔hierarquia, histórico versionado | Idem |
| `dbo.bi_catalogo` | Loja↔setor↔competência (`ID_LOJA, SETOR_PROMOTOR, TIPO, ANO_MES`) | Idem — **tem duplicação de linhas conhecida (4x)**, contornada com `DISTINCT` em `rota86.vw_carteira_atual`; a correção definitiva é no ETL corporativo que alimenta essa tabela, fora do escopo deste repositório |
| `dbo.bi_d_loja` | Cadastro de loja (nome, rede, canal, cidade/UF) | Idem |

Nenhuma tabela `rota86.*` repete nome de pessoa/loja/hierarquia — sempre
referencia por chave (`ID_LOJA`, `COD_ROTA`, `COD_PESSOA`) e resolve nome
via `JOIN` (ou pelas views `rota86.vw_hierarquia`/`vw_carteira_atual`).

## Pontuação, MOP e direcionamento — vêm de fora do banco corporativo

Esta é a parte que **não tem nada a ver** com `dbo.bi_f_efetividade`/
`bi_f_formulario` (tabelas do mesmo banco, mas de outro domínio — chamados
e pesquisas operacionais, confirmado por amostra). Vem de um motor
separado ("Lojas Perfeitas"), hoje planilhas locais processadas por
Python, que precisam ser carregadas nas tabelas de staging (`rota86.stg_*`)
antes de qualquer coisa funcionar:

| Arquivo de origem | Aba/coluna relevante | Tabela de staging | Tabela fato (o que o PHP lê) |
|---|---|---|---|
| `kbdscat.xlsx` | `Planilha1` | `rota86.stg_kbdscat` | `rota86.pontuacao_loja_mes.score_kbd` (via `f_score`) |
| `f_sos.xlsx` | `Planilha1` | `rota86.stg_f_sos` | idem, `score_sos` |
| `md_pe.xlsx` | `F_Ponto extra` | `rota86.stg_f_pe` | idem, `score_pe` |
| `bases_cko.xlsx` | `f_CKO Regular` / `f_CKO Drug Chain` | `rota86.stg_f_cko_regular` / `stg_f_cko_drug_chain` | idem, `score_cko` |
| `MOP 3.0 *.xlsx` | `BASE MOP` | `rota86.stg_mop_base` / `stg_mop_item` | `rota86.mop_loja` / `mop_item` |
| `julho_fechado.csv` / `f_score` (fechamento oficial) | — | `rota86.stg_f_score` | `rota86.pontuacao_loja_mes` (carga direta, sem recálculo — é a régua oficial) |
| Saída do motor `gerar_oportunidades_rota86.py` | CSV, 17 colunas | (gravado direto pelo motor) | `rota86.oportunidade_loja_mes` |
| Catálogo de Assignação (`ORDEM SEG..DOM`) | — | `rota86.stg_agenda_assignacao` | `rota86.agenda_visita_semanal` |
| Catálogo de Lojas (frequência) | — | `rota86.stg_loja_frequencia` | `rota86.loja_frequencia` |
| Retail-X — visitas mensal | `ID LOJA, PREVISTO TOTAL, TOTAL EXECUTADO VISITAS` | `rota86.stg_visita_mensal_loja` | `rota86.visita_mensal_loja` (**substitui a competência inteira a cada carga, nunca soma**) |
| Extração Power BI — leitura + STAR (unificada) | `ID, TARGET LEITURA, LEITURA REALIZADA, STATUS STAR` | `rota86.stg_leitura_star_loja` | `rota86.leitura_star_loja_mes` (mesma regra de substituição completa) |
| Report mensal do Salesforce (recarregado várias vezes ao dia) | `FULL SALESFORCE ID, VISIT ID, STATUS, ACTUAL START TIME, VISITOR: USER ID, VISITOR: FULL NAME` (**este último campo carrega o SETOR PROMOTOR, não o nome da pessoa** — confirmado com o usuário) | `rota86.stg_visita_realizada` | `rota86.visita_realizada` (substitui o mês inteiro a cada carga — cobre "hoje" automaticamente) |
| `calendario_excecoes_feriados.csv` | `DATA, DESCRICAO` | — (carga direta) | `rota86.feriado` (carga 1x/ano, nunca apaga anos anteriores) |

Detalhe completo de cada fórmula de cálculo (SOS/KBD/PE/CKO) e de cada
coluna do motor: ver os arquivos-fonte do motor, que devem viver junto
deste repositório em uma pasta separada quando o agente de carga for
implementado (ver `COMO_ATUALIZAR_DADOS.md`).

## Tabelas de referência — já carregadas neste repositório

| Tabela | Conteúdo | Como foi carregada |
|---|---|---|
| `rota86.ref_peso_kbd_canal_plataforma`, `ref_peso_sos_marca`, `ref_peso_pe_grupo`, `ref_meta_cko_canal`, `ref_config_cko` | Pesos/metas fixas por canal×plataforma | Portados dos valores validados no motor Python (`sql/02_tabelas_referencia.sql`) |
| `rota86.categoria_kpi` | Categoria válida por KPI (SOS/KBD/PE/CKO) | **Valores reais** extraídos com `openpyxl` direto dos arquivos `kbdscat.xlsx`/`f_sos.xlsx`/`md_pe.xlsx` (coluna `CATEGORIA`) e `bases_cko.xlsx` (coluna `MARCA`) — não é uma lista inventada |
| `rota86.motivo_justificativa`, `motivo_visita` | Motivos fixos de justificativa | Portados do texto hardcoded no app antigo |
| `rota86.feriado` | Calendário de feriados | Vazia — carregar via `rota86.sp_upsert_feriado`, ver `COMO_ATUALIZAR_DADOS.md` |

## Login

`rota86.usuario`/`usuario_escopo` — **sem dado real ainda**. O seed de
demonstração (`sql/99_seed_demo.sql`) cria 4 logins sintéticos
(`demo.promotor`, `demo.coordenador`, `demo.executivo`, `demo.operacao`,
senha `demo123`) só para smoke test em ambiente de desenvolvimento.
