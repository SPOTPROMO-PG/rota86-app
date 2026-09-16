<?php

declare(strict_types=1);

namespace Rota86\Repositories;

use Rota86\Database;

/**
 * Lê rota86.vw_carteira_atual, aplicando o filtro de escopo do usuário
 * logado (equivalente ao PERM.baseAcesso() do v3 — ver docs/TELAS_E_REGRAS.md).
 */
final class CarteiraRepository
{
    /** @return array<int, array<string, mixed>> */
    public function carteiraDoUsuario(array $usuario): array
    {
        $escopos = $usuario['escopos'] ?? [];

        foreach ($escopos as $escopo) {
            if ($escopo['tipo_escopo'] === 'TODOS') {
                // Perfil "Operação": vê tudo, exceto lojas de demonstração
                // (mesma convenção do app atual — prefixo DEMO-).
                return Database::query(
                    "SELECT * FROM rota86.vw_carteira_atual WHERE id_loja NOT LIKE 'DEMO-%'"
                );
            }
        }

        $condicoes = [];
        $params = [];
        foreach ($escopos as $escopo) {
            switch ($escopo['tipo_escopo']) {
                case 'SETOR':
                    $condicoes[] = 'setor_promotor = ?';
                    $params[] = $escopo['valor_texto'];
                    break;
                case 'COORDENADOR':
                    $condicoes[] = 'nome_coordenador_regional = ?';
                    $params[] = $escopo['valor_texto'];
                    break;
                case 'EXECUTIVO':
                    $condicoes[] = 'nome_executivo = ?';
                    $params[] = $escopo['valor_texto'];
                    break;
            }
        }

        if ($condicoes === []) {
            return [];
        }

        $sql = 'SELECT * FROM rota86.vw_carteira_atual WHERE ' . implode(' OR ', $condicoes);
        return Database::query($sql, $params);
    }

    public function porLoja(string $idLoja): ?array
    {
        return Database::queryOne('SELECT * FROM rota86.vw_carteira_atual WHERE id_loja = ?', [$idLoja]);
    }
}
