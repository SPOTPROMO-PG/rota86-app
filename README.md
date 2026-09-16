# ROTA86

Painel de acompanhamento de promotores/lojas do programa Lojas Perfeitas.
Substitui o antigo `rota86_v3.html` (HTML estático de 15 MB, gerado
localmente, nunca publicado) por uma aplicação **PHP** que lê direto do
banco corporativo (SQL Server, `bi_pg_promotores`).

## Estado deste repositório (importante ler antes de mexer)

- **O schema de banco (`sql/`) foi validado sintaticamente contra o
  servidor real, mas ainda não foi aplicado em produção por ninguém do
  TI.** Sem ele, nada funciona.
- **O código PHP foi verificado com `php -l` (0 erros de sintaxe) e revisado
  linha a linha contra o schema, mas nunca rodou de ponta a ponta** — esta
  máquina não tinha PHP/SQL Server disponíveis para um teste real no
  momento em que foi escrito. Ver `docs/TELAS_E_REGRAS.md` para o que foi
  simplificado em relação ao app antigo.
- Há um script de dado sintético (`sql/99_seed_demo.sql`, prefixo `DEMO-`)
  para smoke test — **nunca rodar em `bi_pg_promotores` de produção**, só
  numa base de desenvolvimento/homologação isolada.

## Como rodar localmente

Pré-requisitos: PHP 8.1+ com a extensão `pdo_sqlsrv` (driver oficial da
Microsoft — [ODBC Driver + PHP Drivers for SQL Server](https://learn.microsoft.com/sql/connect/php/microsoft-php-driver-for-sql-server)),
acesso de rede ao SQL Server.

```bash
cp .env.example .env
# edite .env com DB_SERVER / DB_DATABASE / DB_USER / DB_PASSWORD

php -S localhost:8000 -t public
```

Acesse `http://localhost:8000`. Sem servidor web (Apache/Nginx/IIS)
configurado, o servidor embutido do PHP (`php -S`) já é suficiente para
desenvolvimento.

## Estrutura

```
public/        ← raiz web (front controller + CSS/JS)
src/           ← PHP: Config, Database, Auth, Router, Repositories/, Controllers/
templates/     ← 1 arquivo por tela
sql/           ← schema completo do banco (rodar 01..09 nesta ordem, depois 99 só em dev)
docs/          ← arquitetura, origem dos dados, como atualizar, telas e regras
```

Sem framework, sem Composer obrigatório — autoload próprio
(`spl_autoload_register` em `public/index.php`). Decisão registrada em
`docs/ARQUITETURA.md`: minimizar dependências porque a hospedagem final
ainda não está definida.

## Documentação

| Arquivo | Conteúdo |
|---|---|
| `docs/ARQUITETURA.md` | Decisões de arquitetura, por que PHP puro, onde fica a lógica de cálculo |
| `docs/ORIGEM_DOS_DADOS.md` | De onde vem cada tabela/coluna — a pergunta "de onde isso vem?" respondida |
| `docs/COMO_ATUALIZAR_DADOS.md` | O fluxo mensal/diário de carga de dado — quem roda o quê, quando |
| `docs/TELAS_E_REGRAS.md` | Tela por tela: o que mostra, de onde lê, o que grava, e o que ficou simplificado em relação ao `rota86_v3.html` original |

## Deploy — ainda não definido

Não há hospedagem configurada. Qualquer ambiente PHP 8.1+ com
`pdo_sqlsrv`/`sqlsrv` habilitado e rota de rede até `172.18.0.59` serve.
Ver `docs/ARQUITETURA.md` para o que precisa ser decidido antes do primeiro
deploy real (usuário técnico do banco, HTTPS, etc.).
