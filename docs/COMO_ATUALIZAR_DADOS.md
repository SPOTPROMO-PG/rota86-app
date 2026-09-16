# Como atualizar os dados

## Fluxo alvo

```
Power BI / Retail-X (exports) → agente de carga → tabelas rota86.stg_*
    → motor de cálculo (Python) → tabelas rota86.* (fato)
    → app PHP (só leitura das tabelas fato/views)
```

O app PHP **nunca** gera nem recalcula dado — só lê o que já está pronto
nas tabelas fato. Toda a responsabilidade de "atualizar os dados" é do
agente de carga + motor de cálculo, que rodam **fora** deste repositório,
como um job agendado num servidor (não no notebook de ninguém).

## Cadência por fonte

| Fonte | Frequência | Regra de carga |
|---|---|---|
| Pontuação (`f_score`), MOP, leituras brutas (SOS/KBD/PE/CKO) | Mensal (mesmo ritmo do fechamento oficial) | Upsert por competência (`rota86.sp_carregar_pontuacao_do_stage`) |
| Visita mensal agregada, leitura+STAR | Mensal | **Substituição completa da competência** (`sp_carregar_visita_mensal`, `sp_carregar_leitura_star`) — nunca soma ao que já existia |
| Visita realizada (Salesforce) | Várias vezes ao dia | Mesma regra de substituição completa (`sp_carregar_visita_realizada`) — cobre "hoje" automaticamente porque o mensal é sempre o snapshot mais atual |
| Feriados | 1x por ano | `sp_upsert_feriado` — nunca apaga anos anteriores |
| Catálogo/agenda semanal | Mensal | Acompanha a carga do catálogo corporativo (`dbo.bi_catalogo`, fora deste projeto) + `rota86.stg_agenda_assignacao` |

## Passo a passo de uma carga manual (até o agente automatizado existir)

1. Depositar os arquivos novos (Power BI/Retail-X/MOP/catálogo) numa pasta
   de entrada.
2. `EXEC rota86.sp_iniciar_lote @origem=..., @arquivo=..., @competencia=...`
   para abrir um lote (`batch_id`).
3. Carregar cada arquivo na tabela `rota86.stg_*` correspondente
   (ver `ORIGEM_DOS_DADOS.md` para o mapeamento arquivo → tabela).
4. Rodar o motor Python (fora deste repositório — ver a seção "Onde fica o
   cálculo" em `ARQUITETURA.md`) para gerar `rota86.oportunidade_loja_mes`
   a partir do staging, e `rota86.sp_carregar_pontuacao_do_stage` para
   `rota86.pontuacao_loja_mes`.
5. `EXEC rota86.sp_finalizar_lote @batch_id=..., @status='concluido', ...`
6. Nenhuma etapa do app PHP precisa ser reiniciada — a próxima requisição
   já lê o dado novo (não há cache).

## Regra de ouro

Nunca gravar direto numa tabela fato (`rota86.pontuacao_loja_mes`,
`rota86.oportunidade_loja_mes` etc.) sem passar por staging primeiro e sem
`batch_id` — é assim que se audita depois "de onde veio esse número" via
`rota86.lote_carga`.
