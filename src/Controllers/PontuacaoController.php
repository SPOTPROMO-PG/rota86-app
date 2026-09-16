<?php

declare(strict_types=1);

namespace Rota86\Controllers;

use Rota86\Repositories\CarteiraRepository;
use Rota86\Repositories\PontuacaoRepository;

/** Telas "Pontuação" e "Fechamentos" — série histórica agregada da carteira. */
final class PontuacaoController extends Controller
{
    public function index(): void
    {
        $usuario = $this->exigirLogin();
        $carteira = (new CarteiraRepository())->carteiraDoUsuario($usuario);
        $idsLoja = array_column($carteira, 'id_loja');

        $pontuacaoRepo = new PontuacaoRepository();
        $atual = $pontuacaoRepo->atualComTendencia($idsLoja);

        $historicoPorMes = [];
        foreach ($idsLoja as $idLoja) {
            foreach ($pontuacaoRepo->historicoDaLoja($idLoja) as $linha) {
                $mes = $linha['ordem_mes'];
                $historicoPorMes[$mes]['soma'] = ($historicoPorMes[$mes]['soma'] ?? 0) + (float) ($linha['score_total'] ?? 0);
                $historicoPorMes[$mes]['n'] = ($historicoPorMes[$mes]['n'] ?? 0) + 1;
                $historicoPorMes[$mes]['mes_referencia'] = $linha['mes_referencia'];
            }
        }
        ksort($historicoPorMes);
        $serieFechamento = array_map(
            static fn (array $m) => [
                'mes_referencia' => $m['mes_referencia'],
                'media' => $m['n'] > 0 ? round($m['soma'] / $m['n'], 1) : null,
                'n' => $m['n'],
            ],
            $historicoPorMes
        );

        $this->render('pontuacao', [
            'atual' => $atual,
            'serieFechamento' => array_values($serieFechamento),
        ]);
    }

    public function fechamentos(): void
    {
        $this->index(); // mesma fonte de dado; tela separada só reorganiza a visão
    }
}
