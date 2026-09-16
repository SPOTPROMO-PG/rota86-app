<?php

declare(strict_types=1);

namespace Rota86\Repositories;

use Rota86\Database;

/**
 * Lê rota86.pontuacao_loja_mes (histórico único, não é 1 tabela por mês —
 * ver docs/ORIGEM_DOS_DADOS.md) e rota86.vw_pontuacao_slope_risco
 * (tendência calculada, substitui o np.polyfit do gerador antigo).
 */
final class PontuacaoRepository
{
    /** Nota + tendência mais recente, para uma lista de lojas (telas Hoje/Lojas/Equipe). */
    public function atualComTendencia(array $idsLoja): array
    {
        if ($idsLoja === []) {
            return [];
        }
        $marcadores = implode(',', array_fill(0, count($idsLoja), '?'));
        return Database::query(
            "SELECT * FROM rota86.vw_pontuacao_slope_risco WHERE id_loja IN ($marcadores)",
            $idsLoja
        );
    }

    /** Série histórica de uma loja (tela Pontuação/Fechamentos, gráfico de linha). */
    public function historicoDaLoja(string $idLoja): array
    {
        return Database::query(
            'SELECT ordem_mes, mes_referencia, score_total, score_total_objetivo,
                    score_sos, score_sos_objetivo, score_kbd, score_kbd_objetivo,
                    score_pe, score_pe_objetivo, score_cko, score_cko_objetivo, ultima_leitura
             FROM rota86.pontuacao_loja_mes
             WHERE id_loja = ?
             ORDER BY ordem_mes',
            [$idLoja]
        );
    }

    /** Nota do mês mais recente de um conjunto de lojas (usado pela tela Equipe para agregação). */
    public function ultimaCompetencia(array $idsLoja): array
    {
        if ($idsLoja === []) {
            return [];
        }
        $marcadores = implode(',', array_fill(0, count($idsLoja), '?'));
        return Database::query(
            "SELECT p.* FROM rota86.pontuacao_loja_mes p
             INNER JOIN (
                 SELECT id_loja, MAX(ordem_mes) AS ordem_mes
                 FROM rota86.pontuacao_loja_mes
                 WHERE id_loja IN ($marcadores)
                 GROUP BY id_loja
             ) ult ON ult.id_loja = p.id_loja AND ult.ordem_mes = p.ordem_mes",
            $idsLoja
        );
    }
}
