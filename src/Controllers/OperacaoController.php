<?php

declare(strict_types=1);

namespace Rota86\Controllers;

use Rota86\Repositories\CarteiraRepository;
use Rota86\Repositories\OperacaoRepository;
use Rota86\Repositories\RoteiroRepository;

/** Tela "Operação/Execução" (só não-Promotor) — visitas e leitura do escopo do usuário. */
final class OperacaoController extends Controller
{
    public function index(): void
    {
        $usuario = $this->exigirLogin();
        $carteira = (new CarteiraRepository())->carteiraDoUsuario($usuario);
        $idsLoja = array_column($carteira, 'id_loja');
        $anoMes = date('Y-m');

        $operacaoRepo = new OperacaoRepository();
        $visitasMensal = $operacaoRepo->visitasMensal($idsLoja, $anoMes);
        $leituraStar = $operacaoRepo->leituraStar($idsLoja, $anoMes);
        $visitasHoje = $operacaoRepo->visitasRealizadasDoDia(new \DateTimeImmutable(), $idsLoja);

        $roteiroHoje = (new RoteiroRepository())->doDia(new \DateTimeImmutable());
        $roteiroHoje = array_values(array_filter(
            $roteiroHoje,
            static fn (array $r) => in_array($r['id_loja'], $idsLoja, true)
        ));

        $previstoTotal = array_sum(array_column($visitasMensal, 'previsto_total'));
        $executadoTotal = array_sum(array_column($visitasMensal, 'executado_total'));

        // status_star é NULL quando a loja não está na lista de STAR da
        // competência (ausência de registro, não pendência — ver
        // docs/ORIGEM_DOS_DADOS.md). Só conta OK/NOK quando há status real.
        $starOk = count(array_filter($leituraStar, static fn (array $l) => $l['status_star'] === 'OK'));
        $starNok = count(array_filter($leituraStar, static fn (array $l) => $l['status_star'] === 'NOK'));

        $this->render('operacao', [
            'previstoTotal' => $previstoTotal,
            'executadoTotal' => $executadoTotal,
            'roteiroHoje' => $roteiroHoje,
            'visitasHoje' => $visitasHoje,
            'starOk' => $starOk,
            'starNok' => $starNok,
        ]);
    }
}
