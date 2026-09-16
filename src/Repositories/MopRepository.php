<?php

declare(strict_types=1);

namespace Rota86\Repositories;

use Rota86\Database;

/** Lê rota86.mop_loja/mop_item (plano de execução por loja — tela "Plano da visita"/360°). */
final class MopRepository
{
    public function daLoja(string $idLoja): ?array
    {
        $mop = Database::queryOne(
            'SELECT TOP 1 * FROM rota86.mop_loja WHERE id_loja = ? ORDER BY ano_mes DESC',
            [$idLoja]
        );
        if ($mop === null) {
            return null;
        }

        $mop['itens'] = Database::query(
            'SELECT kpi, categoria, item, objetivo, is_supermop FROM rota86.mop_item WHERE mop_loja_id = ?',
            [$mop['id']]
        );

        return $mop;
    }
}
