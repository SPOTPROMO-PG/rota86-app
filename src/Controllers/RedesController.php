<?php

declare(strict_types=1);

namespace Rota86\Controllers;

use Rota86\Repositories\CarteiraRepository;
use Rota86\Repositories\PontuacaoRepository;

/** Tela "Redes e Cidades" (só não-Promotor) — mesmo agrupamento genérico da Equipe, por outra dimensão. */
final class RedesController extends Controller
{
    public function index(): void
    {
        $usuario = $this->exigirLogin();
        $carteira = (new CarteiraRepository())->carteiraDoUsuario($usuario);
        $idsLoja = array_column($carteira, 'id_loja');

        $pontuacao = (new PontuacaoRepository())->atualComTendencia($idsLoja);
        $pontuacaoPorLoja = array_column($pontuacao, null, 'id_loja');

        $aba = $_GET['aba'] ?? 'rede'; // rede | cidade | canal
        $campo = match ($aba) {
            'cidade' => 'cidade_uf',
            'canal' => 'canal',
            default => 'rede',
        };

        $grupos = [];
        foreach ($carteira as $loja) {
            $chave = $loja[$campo] ?? '(não informado)';
            $p = $pontuacaoPorLoja[$loja['id_loja']] ?? null;
            $grupos[$chave]['nome'] ??= $chave;
            $grupos[$chave]['n'] = ($grupos[$chave]['n'] ?? 0) + 1;
            if ($p !== null && $p['nota_atual'] !== null) {
                $grupos[$chave]['soma'] = ($grupos[$chave]['soma'] ?? 0) + (float) $p['nota_atual'];
                $grupos[$chave]['comNota'] = ($grupos[$chave]['comNota'] ?? 0) + 1;
            }
        }
        foreach ($grupos as &$g) {
            $g['media'] = ($g['comNota'] ?? 0) > 0 ? round($g['soma'] / $g['comNota'], 1) : null;
        }
        unset($g);

        $this->render('redes', ['grupos' => $grupos, 'aba' => $aba]);
    }
}
