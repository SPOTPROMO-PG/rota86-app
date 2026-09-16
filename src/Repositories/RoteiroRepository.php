<?php

declare(strict_types=1);

namespace Rota86\Repositories;

use Rota86\Database;

/**
 * Lê rota86.fn_roteiro_do_dia(@data) — roteiro CALCULADO a partir da agenda
 * semanal, não uma tabela de "visita planejada" (decisão registrada em
 * docs/ARQUITETURA.md). Junta planejado x realizado por Setor+Loja+Dia.
 */
final class RoteiroRepository
{
    public function doDia(\DateTimeImmutable $data): array
    {
        return Database::query(
            'SELECT * FROM rota86.fn_roteiro_do_dia(?) ORDER BY ordem_sort, ordem',
            [$data->format('Y-m-d')]
        );
    }

    public function doDiaParaSetor(\DateTimeImmutable $data, string $setorPromotor): array
    {
        return Database::query(
            'SELECT * FROM rota86.fn_roteiro_do_dia(?) WHERE setor_promotor = ? ORDER BY ordem_sort, ordem',
            [$data->format('Y-m-d'), $setorPromotor]
        );
    }

    /** Agenda da semana inteira de um setor — tela "Minha semana" do Promotor. */
    public function semanaDoSetor(string $setorPromotor, string $anoMes): array
    {
        return Database::query(
            'SELECT * FROM rota86.agenda_visita_semanal
             WHERE setor_promotor = ? AND ano_mes = ?
             ORDER BY dia_idx, ordem_sort, ordem',
            [$setorPromotor, $anoMes]
        );
    }
}
