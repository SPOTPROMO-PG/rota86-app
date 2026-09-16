# Telas e regras — o que cada uma faz, de onde lê, o que grava

Base: auditoria completa do `template_v3_direcional.html` original (o
código-fonte por trás do `rota86_v3.html`). Cada seção abaixo registra
também **o que foi simplificado** nesta primeira versão em PHP — para
alguém completar depois sem precisar reler o app antigo inteiro.

## Login (`/login`)

- Lê: `rota86.vw_usuario_perfil` + `rota86.usuario_escopo`.
- Grava: nada além da sessão PHP (`$_SESSION`) e `ultimo_login_em`.
- **Diferença do v3**: login real por pessoa/senha, substitui a senha
  única compartilhada por setor. Ver `ARQUITETURA.md`.

## Hoje (`/hoje`, só não-Promotor)

- Lê: `CarteiraRepository` (carteira do escopo) + `PontuacaoRepository`
  (nota/tendência) + `DirecionamentoRepository` (agregação de pontos
  perdidos por KPI/categoria).
- Grava: nada.
- **Simplificado em relação ao v3**: o original calculava "concentração de
  perda", "pior/melhor grupo por dimensão", "tendência subiu/caiu/estável"
  com bastante detalhe. Esta versão mostra nota média, contagem de lojas em
  risco e top 5 categorias com mais pontos perdidos — o essencial, não a
  paridade pixel a pixel. Expandir sem mudar o schema, é só mais
  agregação em `HojeController`.

## Direcionamentos (`/direcionamentos`, só Promotor)

- Lê: `rota86.vw_direcionamento_atual` (via `DirecionamentoRepository`) +
  último status de tratativa (`rota86.acao_direcionamento`, via
  `AcaoDirecionamentoRepository::statusAtualDeLojas`).
- Grava: `rota86.sp_registrar_acao_direcionamento` (botões Executei /
  Impedimento / Ajuda, via `POST /api/acao-direcionamento`).
- **Diferença do v3**: os 3 estados agora sincronizam com o servidor (no
  antigo, só Impedimento/Ajuda chegavam a um backend). Ver decisão em
  `ARQUITETURA.md`.
- **Simplificado**: no v3, "Impedimento"/"Ajuda" abriam um formulário que
  também criava uma **justificativa** (tipo `nota`), além de marcar a
  tratativa. Nesta versão, o botão só registra a tratativa
  (`sp_registrar_acao_direcionamento`) com um motivo em texto livre — não
  cria automaticamente uma linha em `rota86.justificativa`. Se o negócio
  quiser manter os dois registros juntos, é só fazer o
  `JustificativaController::registrarAcao` chamar também
  `JustificativaRepository::upsert()` quando `status` for `impedida`/`ajuda`.

## Pontuação / Fechamentos (`/pontuacao`, `/fechamentos`)

- Lê: `rota86.pontuacao_loja_mes` (série histórica) +
  `rota86.vw_pontuacao_slope_risco` (situação atual + tendência).
- Grava: nada.
- Mesma tela para as duas rotas (`PontuacaoController::fechamentos()`
  delega para `index()`) — no v3 eram duas telas separadas com o mesmo
  dado em recortes diferentes; aqui ficou uma só até haver necessidade real
  de separar.

## Equipe (`/equipe`, só não-Promotor)

- Lê: carteira do escopo + pontuação atual, agrupado em PHP por
  coordenador ou executivo (conforme o perfil logado).
- Grava: nada.
- **Sem tabela `AGG`** — o agrupamento é calculado a cada requisição, como
  já era no v3 (que também não usava uma tabela pré-agregada, apesar de
  `AGG` existir no JSON).

## Redes e Cidades (`/redes`)

- Lê: `rota86.vw_carteira_atual` (que já traz rede/cidade/canal via
  `dbo.bi_d_loja`) + pontuação atual, agrupado em PHP.
- Grava: nada.
- **Simplificado**: o v3 tinha 3 abas (Rede/Cidade/Grupo de canal, este
  último com um mapeamento fixo de canais em 3 grupos). Aqui as abas
  Rede/Cidade/Canal existem; o agrupamento "grupo de canal" (C&C+CLUB,
  DPP+PERF, etc.) não foi portado — usar o `canal` cru por enquanto.

## Lojas — catálogo (`/lojas`)

- Lê: carteira do escopo + pontuação atual. Promotor vê só a carteira
  dele, ordenada pelo roteiro do dia (`fn_roteiro_do_dia`); outros perfis
  veem busca por texto (nome/rede/cidade/ID) e paginação (25/página).
- Grava: nada.
- **Simplificado**: filtros de faixa/STAR/rede/cidade/canal do v3 (sheet de
  filtros dedicado) viraram só uma busca de texto por enquanto. A estrutura
  já suporta adicionar filtros — é mais parâmetros de `$_GET` em
  `LojasController::index()`.

## Detalhe da loja (`/loja?id=...`)

- Lê: `vw_carteira_atual` (cabeçalho), `pontuacao_loja_mes` (histórico),
  `vw_direcionamento_atual` (plano da visita), `mop_loja`/`mop_item`
  (orientações MOP), `leitura_star_loja_mes` (leitura do mês).
- Grava: mesma ação de tratativa da tela Direcionamentos (botões na
  própria página).
- **Simplificado**: o v3 agrupava direcionamento + MOP em 8 "famílias 360°"
  (fraldas/bebê, cabelos, desodorantes...) por heurística de texto sobre a
  categoria/item. Aqui os dois blocos aparecem separados (direcionamentos
  primeiro, MOP depois) — mais simples de ler no código, menos "narrativo"
  que o original. Reagrupar por família é só uma função de mapeamento
  categoria→família no controller, se quiserem essa experiência de volta.

## Calculadora SOS (`/calculadora-sos?id=...`, só Promotor)

- Lê: `vw_direcionamento_atual` filtrado por KPI=SOS (as categorias
  pendentes daquela loja).
- Grava: **nada no servidor** — cálculo e persistência ficam no
  `localStorage` do navegador (`public/assets/app.js`), igual ao v3. Ver
  `ARQUITETURA.md` para a decisão em aberto de centralizar isso.

## Operação/Execução (`/operacao`, só não-Promotor)

- Lê: `visita_mensal_loja`, `leitura_star_loja_mes`, `visita_realizada`
  (via `fn_roteiro_do_dia` para o dia corrente).
- Grava: nada nesta versão (o v3 tinha um botão "Justificar" por loja não
  visitada, que abria o mesmo formulário de justificativa de visita —
  ainda não ligado nesta tela; o endpoint `POST /api/justificativa` já
  existe e cobre isso, é só adicionar o botão no template
  `templates/operacao.php`).
- **Não portado**: exportar PNG das pendências (o v3 gerava isso via
  `<canvas>` no navegador) — não é dado de servidor, fica como
  possível adição de JS puro depois.

## Perfil (`/perfil`)

- Lê: contagem de lojas no escopo + último lote de carga concluído
  (`rota86.lote_carga`) — mostra "de onde vêm os números e quando foi
  atualizado", pedido explícito do escopo original da tela.
- Grava: nada (o "Sincronizar agora" do v3 não existe mais como conceito —
  não há mais fila de sincronização client-side a reenviar; cada ação já
  vai direto ao servidor).

## Justificativa (`POST /api/justificativa`)

- Não é uma tela — é o endpoint chamado por um formulário (a construir em
  `templates/`, análogo ao modal do v3) para os dois tipos: `LOJA`
  (barreira ligada a um KPI) e `VISITA` (visita não realizada).
- Grava via `rota86.sp_upsert_justificativa` — idempotente por
  `id_justificativa` (gerado no cliente), mesma regra do app antigo.
- **Pendência**: o formulário HTML/JS de justificativa em si (campos KPI →
  categoria → motivo → observação, populados de `rota86.categoria_kpi` e
  `rota86.motivo_justificativa`/`motivo_visita`) ainda não foi escrito
  como template — o `JustificativaController::salvar()` já está pronto
  para recebê-lo. Prioridade natural do próximo incremento.
