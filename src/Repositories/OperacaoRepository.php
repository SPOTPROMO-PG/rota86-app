<?php

declare(strict_types=1);

namespace Rota86\Repositories;

use Rota86\Database;

/**
 * Lê o que a tela "Operação/Execução" do v3 chamava de RETAILX —
 * hoje três tabelas separadas (ver docs/ORIGEM_DOS_DADOS.md):
 * visita_mensal_loja (agregado), leitura_star_loja_mes (leitura+STAR),
 * visita_realizada (eventos Salesforce, atualizado várias vezes ao dia).
 */
final class OperacaoRepository
{
    public function visitasMensal(array $idsLoja, string $anoMes): array
    {
        if ($idsLoja === []) {
            return [];
        }
        $marcadores = implode(',', array_fill(0, count($idsLoja), '?'));
        return Database::query(
            "SELECT * FROM rota86.visita_mensal_loja WHERE ano_mes = ? AND id_loja IN ($marcadores)",
            array_merge([$anoMes], $idsLoja)
        );
    }

    public function leituraStar(array $idsLoja, string $anoMes): array
    {
        if ($idsLoja === []) {
            return [];
        }
        $marcadores = implode(',', array_fill(0, count($idsLoja), '?'));
        return Database::query(
            "SELECT * FROM rota86.leitura_star_loja_mes WHERE ano_mes = ? AND id_loja IN ($marcadores)",
            array_merge([$anoMes], $idsLoja)
        );
    }

    public function visitasRealizadasDoDia(\DateTimeImmutable $data, array $idsLoja = []): array
    {
        $sql = 'SELECT * FROM rota86.visita_realizada WHERE data_visita = ?';
        $params = [$data->format('Y-m-d')];

        if ($idsLoja !== []) {
            $marcadores = implode(',', array_fill(0, count($idsLoja), '?'));
            $sql .= " AND id_loja IN ($marcadores)";
            $params = array_merge($params, $idsLoja);
        }

        return Database::query($sql, $params);
    }
}
