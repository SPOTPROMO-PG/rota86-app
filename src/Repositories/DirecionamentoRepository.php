<?php

declare(strict_types=1);

namespace Rota86\Repositories;

use Rota86\Database;

/** Lê rota86.vw_direcionamento_atual (fonte da tela "Direcionamentos" / "O que falta executar"). */
final class DirecionamentoRepository
{
    /** @return array<int, array<string, mixed>> */
    public function daLoja(string $idLoja): array
    {
        return Database::query(
            'SELECT * FROM rota86.vw_direcionamento_atual WHERE id_loja = ?
             ORDER BY pontos_faltantes DESC',
            [$idLoja]
        );
    }

    /** @param string[] $idsLoja */
    public function deLojas(array $idsLoja): array
    {
        if ($idsLoja === []) {
            return [];
        }
        $marcadores = implode(',', array_fill(0, count($idsLoja), '?'));
        return Database::query(
            "SELECT * FROM rota86.vw_direcionamento_atual WHERE id_loja IN ($marcadores)
             ORDER BY id_loja, pontos_faltantes DESC",
            $idsLoja
        );
    }

    public function porKpi(string $idLoja, string $kpi): array
    {
        return Database::query(
            'SELECT * FROM rota86.vw_direcionamento_atual WHERE id_loja = ? AND kpi = ?
             ORDER BY pontos_faltantes DESC',
            [$idLoja, $kpi]
        );
    }
}
