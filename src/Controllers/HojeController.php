<?php

declare(strict_types=1);

namespace Rota86\Controllers;

use Rota86\Repositories\CarteiraRepository;
use Rota86\Repositories\PontuacaoRepository;
use Rota86\Repositories\DirecionamentoRepository;

/**
 * Tela "Hoje" (só perfis não-Promotor). Reproduz o essencial de
 * renderHoje() do v3: nota média da carteira, lojas em risco, top
 * categorias com mais pontos perdidos. Ver docs/TELAS_E_REGRAS.md para o
 * que ficou simplificado em relação ao JS original (agregados de
 * "concentração de perda"/"tendência" completos podem ser expandidos
 * depois sem mudar o schema).
 */
final class HojeController extends Controller
{
    public function index(): void
    {
        $usuario = $this->exigirLogin();

        $carteira = (new CarteiraRepository())->carteiraDoUsuario($usuario);
        $idsLoja = array_column($carteira, 'id_loja');

        $pontuacao = (new PontuacaoRepository())->atualComTendencia($idsLoja);
        $pontuacaoPorLoja = [];
        foreach ($pontuacao as $linha) {
            $pontuacaoPorLoja[$linha['id_loja']] = $linha;
        }

        $notas = array_filter(array_map(
            static fn (array $p) => $p['nota_atual'] ?? null,
            $pontuacaoPorLoja
        ), static fn ($v) => $v !== null);

        $notaMedia = $notas === [] ? null : array_sum($notas) / count($notas);
        $emRisco = array_filter($pontuacaoPorLoja, static fn (array $p) => (int) ($p['risco'] ?? 0) >= 2);

        $direcionamentos = (new DirecionamentoRepository())->deLojas($idsLoja);
        $pontosPorCategoria = [];
        foreach ($direcionamentos as $d) {
            $chave = $d['kpi'] . ' — ' . $d['categoria'];
            $pontosPorCategoria[$chave] = ($pontosPorCategoria[$chave] ?? 0) + (float) $d['pontos_faltantes'];
        }
        arsort($pontosPorCategoria);
        $topPerdas = array_slice($pontosPorCategoria, 0, 5, true);

        $this->render('hoje', [
            'totalLojas' => count($carteira),
            'notaMedia' => $notaMedia,
            'lojasEmRisco' => $emRisco,
            'topPerdas' => $topPerdas,
        ]);
    }
}
