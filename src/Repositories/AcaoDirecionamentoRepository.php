<?php

declare(strict_types=1);

namespace Rota86\Repositories;

use Rota86\Database;

/**
 * Escreve via rota86.sp_registrar_acao_direcionamento — a "tratativa"
 * (feita/impedida/ajuda). DECISÃO TOMADA nesta migração: os 3 estados
 * passam a sincronizar com o servidor (no v3 atual, só impedida/ajuda
 * chegavam a algum backend; "feita" ficava só no localStorage — ver
 * docs/TELAS_E_REGRAS.md para o registro dessa mudança).
 */
final class AcaoDirecionamentoRepository
{
    public function registrar(array $dados): void
    {
        Database::execute(
            'EXEC rota86.sp_registrar_acao_direcionamento
                @id_loja = ?, @kpi = ?, @categoria = ?, @componente = ?,
                @ordem_mes = ?, @cod_pessoa = ?, @status = ?, @motivo = ?, @observacao = ?',
            [
                $dados['id_loja'],
                $dados['kpi'],
                $dados['categoria'] ?? null,
                $dados['componente'] ?? null,
                $dados['ordem_mes'],
                $dados['cod_pessoa'] ?? null,
                $dados['status'],
                $dados['motivo'] ?? null,
                $dados['observacao'] ?? null,
            ]
        );
    }

    /**
     * Último status de cada item de direcionamento das lojas informadas,
     * chaveado por "idLoja|kpi|categoria|componente|ordemMes" (mesma
     * convenção de chave usada no ACOES do v3 antigo, agora vindo do banco).
     */
    public function statusAtualDeLojas(array $idsLoja, int $ordemMes): array
    {
        if ($idsLoja === []) {
            return [];
        }
        $marcadores = implode(',', array_fill(0, count($idsLoja), '?'));
        $linhas = Database::query(
            "SELECT a.*
             FROM rota86.acao_direcionamento a
             INNER JOIN (
                 SELECT id_loja, kpi, categoria, componente, MAX(criado_em) AS ultimo
                 FROM rota86.acao_direcionamento
                 WHERE ordem_mes = ? AND id_loja IN ($marcadores)
                 GROUP BY id_loja, kpi, categoria, componente
             ) u ON u.id_loja = a.id_loja AND u.kpi = a.kpi
                AND (u.categoria = a.categoria OR (u.categoria IS NULL AND a.categoria IS NULL))
                AND (u.componente = a.componente OR (u.componente IS NULL AND a.componente IS NULL))
                AND u.ultimo = a.criado_em",
            array_merge([$ordemMes], $idsLoja)
        );

        $porChave = [];
        foreach ($linhas as $linha) {
            $chave = implode('|', [$linha['id_loja'], $linha['kpi'], $linha['categoria'] ?? '', $linha['componente'] ?? '']);
            $porChave[$chave] = $linha;
        }
        return $porChave;
    }

    /** Histórico de tratativas de um item de direcionamento (mais recente primeiro). */
    public function historicoDoItem(string $idLoja, string $kpi, int $ordemMes, ?string $categoria, ?string $componente): array
    {
        return Database::query(
            'SELECT * FROM rota86.acao_direcionamento
             WHERE id_loja = ? AND kpi = ? AND ordem_mes = ?
               AND (categoria = ? OR (categoria IS NULL AND ? IS NULL))
               AND (componente = ? OR (componente IS NULL AND ? IS NULL))
             ORDER BY criado_em DESC',
            [$idLoja, $kpi, $ordemMes, $categoria, $categoria, $componente, $componente]
        );
    }
}
