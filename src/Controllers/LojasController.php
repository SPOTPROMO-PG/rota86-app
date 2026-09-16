<?php

declare(strict_types=1);

namespace Rota86\Controllers;

use Rota86\Auth;
use Rota86\Repositories\CarteiraRepository;
use Rota86\Repositories\PontuacaoRepository;
use Rota86\Repositories\DirecionamentoRepository;
use Rota86\Repositories\MopRepository;
use Rota86\Repositories\RoteiroRepository;
use Rota86\Repositories\OperacaoRepository;

final class LojasController extends Controller
{
    /** Catálogo — lista completa (não-Promotor) ou carteira do promotor ordenada pelo roteiro. */
    public function index(): void
    {
        $usuario = $this->exigirLogin();
        $carteira = (new CarteiraRepository())->carteiraDoUsuario($usuario);
        $idsLoja = array_column($carteira, 'id_loja');

        $pontuacao = (new PontuacaoRepository())->atualComTendencia($idsLoja);
        $pontuacaoPorLoja = array_column($pontuacao, null, 'id_loja');

        foreach ($carteira as &$loja) {
            $loja['pontuacao'] = $pontuacaoPorLoja[$loja['id_loja']] ?? null;
        }
        unset($loja);

        $minhaSemana = null;
        if (Auth::ehPromotor($usuario)) {
            $setor = $carteira[0]['setor_promotor'] ?? null;
            if ($setor !== null) {
                $minhaSemana = (new RoteiroRepository())->semanaDoSetor($setor, date('Y-m'));
            }
            // ordena a carteira do promotor pela ordem do roteiro de hoje
            $roteiroHoje = $setor !== null
                ? (new RoteiroRepository())->doDiaParaSetor(new \DateTimeImmutable(), $setor)
                : [];
            $ordemPorLoja = array_column($roteiroHoje, 'ordem_sort', 'id_loja');
            usort($carteira, static function (array $a, array $b) use ($ordemPorLoja) {
                $oa = $ordemPorLoja[$a['id_loja']] ?? PHP_INT_MAX;
                $ob = $ordemPorLoja[$b['id_loja']] ?? PHP_INT_MAX;
                return $oa <=> $ob ?: strcmp((string) $a['nome_loja'], (string) $b['nome_loja']);
            });
        } else {
            // filtros de catálogo (não-Promotor) — busca simples por nome/rede/cidade/ID
            $busca = trim((string) ($_GET['q'] ?? ''));
            if ($busca !== '') {
                $buscaLower = mb_strtolower($busca);
                $carteira = array_values(array_filter($carteira, static function (array $l) use ($buscaLower) {
                    foreach (['nome_loja', 'rede', 'cidade', 'id_loja'] as $campo) {
                        if (str_contains(mb_strtolower((string) ($l[$campo] ?? '')), $buscaLower)) {
                            return true;
                        }
                    }
                    return false;
                }));
            }
        }

        $pagina = max(1, (int) ($_GET['pagina'] ?? 1));
        $porPagina = 25;
        $total = count($carteira);
        $paginado = array_slice($carteira, ($pagina - 1) * $porPagina, $porPagina);

        $this->render('lojas', [
            'lojas' => $paginado,
            'total' => $total,
            'pagina' => $pagina,
            'porPagina' => $porPagina,
            'minhaSemana' => $minhaSemana,
            'ehPromotor' => Auth::ehPromotor($usuario),
        ]);
    }

    /** Detalhe da loja: cabeçalho, histórico, plano de visita (MOP + direcionamentos), leitura. */
    public function detalhe(): void
    {
        $this->exigirLogin();
        $idLoja = (string) ($_GET['id'] ?? '');

        $loja = (new CarteiraRepository())->porLoja($idLoja);
        if ($loja === null) {
            http_response_code(404);
            echo 'Loja não encontrada.';
            return;
        }

        $historico = (new PontuacaoRepository())->historicoDaLoja($idLoja);
        $direcionamentos = (new DirecionamentoRepository())->daLoja($idLoja);
        $mop = (new MopRepository())->daLoja($idLoja);
        $leitura = (new OperacaoRepository())->leituraStar([$idLoja], date('Y-m'));

        $this->render('loja_detalhe', [
            'loja' => $loja,
            'historico' => $historico,
            'direcionamentos' => $direcionamentos,
            'mop' => $mop,
            'leitura' => $leitura[0] ?? null,
        ]);
    }

    /**
     * Calculadora SOS — só Promotor. Cálculo é puramente client-side (JS),
     * igual ao v3 hoje; persistência da medição continua fora de escopo
     * (decisão em aberto, ver docs/TELAS_E_REGRAS.md). Esta rota só entrega
     * as opções de categoria SOS pendentes da loja.
     */
    public function calculadoraSos(): void
    {
        $this->exigirLogin();
        $idLoja = (string) ($_GET['id'] ?? '');
        $opcoes = (new DirecionamentoRepository())->porKpi($idLoja, 'SOS');

        $this->render('calculadora_sos', [
            'idLoja' => $idLoja,
            'opcoes' => $opcoes,
        ]);
    }
}
