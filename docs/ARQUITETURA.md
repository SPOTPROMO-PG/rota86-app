# Arquitetura

## Contexto

O ROTA86 rodava como um pipeline de arquivos: exportações de Salesforce,
Retail-X e Power BI ficavam em pastas locais; um script Python
(`gerar_rota85.py`) cruzava tudo e gerava um HTML estático com o dado
embutido em JSON; esse HTML nunca chegou a ser publicado. Este repositório
substitui isso por: banco relacional (schema `rota86` dentro de
`bi_pg_promotores`, SQL Server) + aplicação PHP.

## Decisão: onde fica o cálculo de pontuação (SOS/KBD/PE/CKO)

**Continua em Python, fora deste repositório**, não foi reescrito em T-SQL
nem em PHP. As 4 fórmulas (uma por KPI) foram reconstruídas por engenharia
reversa e validadas a 99–100% contra o fechamento oficial — reescrever sem
dado real para revalidar é o jeito mais fácil de introduzir uma regressão
silenciosa, principalmente no CKO (regra mais complexa, com um limiar
calibrado empiricamente). O motor Python lê as tabelas de staging do banco
(`rota86.stg_*`) e grava as tabelas fato (`rota86.pontuacao_loja_mes`,
`rota86.oportunidade_loja_mes`) — ver `COMO_ATUALIZAR_DADOS.md`. O PHP
nunca calcula pontuação, só lê o resultado já pronto.

## Decisão: PHP puro, sem framework

Hospedagem final ainda não definida. Minimizar dependências (só
`pdo_sqlsrv`, driver oficial da Microsoft) maximiza a chance de rodar em
qualquer ambiente PHP padrão sem precisar de `composer install` nem de uma
versão específica de framework. Autoload próprio, roteador próprio
(`src/Router.php`) — deliberadamente simples, o app tem ~12 telas, não
justifica uma dependência externa.

## Camadas

```
templates/*.php  →  Controllers  →  Repositories  →  views/procs do banco (rota86.vw_*, sp_*)
```

- **Controllers** (`src/Controllers/`): 1 por tela (ou par de telas
  parecidas, ex. Pontuação/Fechamentos). Só orquestram — chamam
  Repository, montam dado para o template, nunca têm SQL dentro.
- **Repositories** (`src/Repositories/`): único lugar que conversa com o
  banco. Só usam as **views/functions/procs de contrato** já desenhadas
  (`vw_hierarquia`, `vw_carteira_atual`, `vw_direcionamento_atual`,
  `vw_usuario_perfil`, `vw_pontuacao_slope_risco`, `fn_roteiro_do_dia`,
  `sp_upsert_justificativa`, `sp_registrar_acao_direcionamento`) —
  **nunca** uma tabela de staging (`rota86.stg_*`) diretamente. Prepared
  statements em 100% das queries.
- **Templates** (`templates/`): só HTML + o dado já pronto. Sem lógica de
  negócio, sem SQL.

## Acesso/login

Login real por pessoa (`rota86.usuario`), substituindo a senha única
compartilhada do app antigo. **Perfil não tem tabela própria** — vem de
`dbo.bi_d_pessoa.COD_PERFIL`/`PERFIL` (taxonomia corporativa já existente:
PROMOTOR, SUPERVISOR, COORDENADOR, GERENTE, etc.), resolvido por
`rota86.vw_usuario_perfil`. `rota86.usuario_escopo` define o que cada
usuário enxerga (substitui os arrays de texto `nomes[]`/`coordenadores[]`
do modelo antigo).

**Autenticação/senha ainda em aberto**: não existe hoje nenhuma coluna de
senha em `bi_pg_promotores`; não foi possível confirmar se existe em
outra base do mesmo servidor (`bi_s3`, `bi_pg_phc`, `askme_pg` são
candidatas, sem acesso confirmado). `rota86.usuario.senha_hash` está pronta
para receber um hash (`password_hash()` do PHP, `PASSWORD_DEFAULT`) — se
depois for confirmada uma fonte de autenticação corporativa (AD/SSO), o
`Auth::tentarLogin()` troca de "comparar hash local" para "validar contra
essa fonte", sem mudar o resto do desenho.

## Decisões de migração em relação ao app antigo (v3)

- **AGG/AVAL**: não existem no schema nem no app novo. No `template_v3_direcional.html`
  antigo, essas duas variáveis eram declaradas mas nunca usadas por
  nenhuma tela — ranking é calculado ao vivo a partir de `STORES`
  (aqui: agregação em PHP sobre `rota86.pontuacao_loja_mes` +
  `rota86.vw_hierarquia`, ver `EquipeController`/`RedesController`).
- **Slope/risco** (tendência da loja): antes calculado em Python a cada
  geração do HTML; agora é `rota86.vw_pontuacao_slope_risco`, uma view SQL
  com a mesma fórmula (regressão linear, mínimo 3 leituras). Atualiza
  sozinha a cada carga nova.
- **Roteiro do dia**: não existe tabela de "visita planejada" por data — é
  calculado por `rota86.fn_roteiro_do_dia(@data)` a partir da agenda
  semanal recorrente (`rota86.agenda_visita_semanal`), cruzado com
  `rota86.visita_realizada` (Salesforce) por Setor+Loja+Dia.
- **"Executei" de um direcionamento**: no app antigo, só "Impedimento" e
  "Ajuda" chegavam a um backend (via Apps Script/Sheets); "Executei" ficava
  só no `localStorage`. **Decisão tomada nesta migração**: os 3 estados
  passam a sincronizar com o servidor via
  `rota86.sp_registrar_acao_direcionamento` — é o objetivo de centralizar
  o dado. Reversível se o negócio preferir manter "Executei" só local.
- **Calculadora SOS**: continua só local (`localStorage` do navegador),
  igual ao app antigo — decisão de persistir ou não ficou em aberto (ver
  `TELAS_E_REGRAS.md`).
