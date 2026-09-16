<?php

declare(strict_types=1);

namespace Rota86\Repositories;

use Rota86\Database;

/** Lê rota86.vw_hierarquia (join já resolvido com dbo.bi_d_pessoa/bi_d_rota). */
final class HierarquiaRepository
{
    public function porSetor(string $setorPromotor): ?array
    {
        return Database::queryOne(
            'SELECT * FROM rota86.vw_hierarquia WHERE setor_promotor = ?',
            [$setorPromotor]
        );
    }

    /** @return array<int, array<string, mixed>> */
    public function todas(): array
    {
        return Database::query('SELECT * FROM rota86.vw_hierarquia');
    }
}
