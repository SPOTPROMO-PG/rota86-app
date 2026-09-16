<?php

declare(strict_types=1);

namespace Rota86\Controllers;

use Rota86\Repositories\CarteiraRepository;
use Rota86\Repositories\PontuacaoRepository;

/**
 * Tela "Equipe" (só não-Promotor) — agrupa a carteira por coordenador ou
 * executivo (a "dimensão equipe" do perfil logado) e calcula média, %
 * abaixo do gate (77) e contagem em risco. Cálculo em PHP sobre o dado já
 * filtrado por escopo — mesma lógica do M.grupo() do v3, sem tabela AGG.
 */
final class EquipeController extends Controller
{
    public function index(): void
    {
        $usuario = $this->exigirLogin();
        $carteira = (new CarteiraRepository())->carteiraDoUsuario($usuario);
        $idsLoja = array_column($carteira, 'id_loja');

        $pontuacao = (new PontuacaoRepository())->atualComTendencia($idsLoja);
        $pontuacaoPorLoja = array_column($pontuacao, null, 'id_loja');

        $perfil = strtoupper((string) ($usuario['perfil'] ?? ''));
        $campoDimensao = match ($perfil) {
            'COORDENADOR' => 'nome_executivo',
            default => 'nome_coordenador_regional',
        };

        $grupos = [];
        foreach ($carteira as $loja) {
            $chave = $loja[$campoDimensao] ?? '(sem responsável)';
            $p = $pontuacaoPorLoja[$loja['id_loja']] ?? null;

            $grupos[$chave]['nome'] ??= $chave;
            $grupos[$chave]['n'] = ($grupos[$chave]['n'] ?? 0) + 1;
            if ($p !== null && $p['nota_atual'] !== null) {
                $grupos[$chave]['soma'] = ($grupos[$chave]['soma'] ?? 0) + (float) $p['nota_atual'];
                $grupos[$chave]['comNota'] = ($grupos[$chave]['comNota'] ?? 0) + 1;
                if ((float) $p['nota_atual'] < 77) {
                    $grupos[$chave]['abaixoGate'] = ($grupos[$chave]['abaixoGate'] ?? 0) + 1;
                }
            } else {
                $grupos[$chave]['semLeitura'] = ($grupos[$chave]['semLeitura'] ?? 0) + 1;
            }
            if ($p !== null && (int) ($p['risco'] ?? 0) >= 2) {
                $grupos[$chave]['risco'] = ($grupos[$chave]['risco'] ?? 0) + 1;
            }
        }

        foreach ($grupos as &$g) {
            $g['media'] = ($g['comNota'] ?? 0) > 0 ? round($g['soma'] / $g['comNota'], 1) : null;
        }
        unset($g);

        uasort($grupos, static fn ($a, $b) => ($a['media'] ?? 999) <=> ($b['media'] ?? 999));

        $this->render('equipe', ['grupos' => $grupos]);
    }
}
