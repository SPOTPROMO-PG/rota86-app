<?php

declare(strict_types=1);

namespace Rota86\Controllers;

use Rota86\Repositories\CarteiraRepository;
use Rota86\Repositories\DirecionamentoRepository;
use Rota86\Repositories\AcaoDirecionamentoRepository;

/** Tela "Direcionamentos" (só Promotor) — fila de ação por loja/KPI/categoria. */
final class DirecionamentosController extends Controller
{
    public function index(): void
    {
        $usuario = $this->exigirLogin();

        $carteira = (new CarteiraRepository())->carteiraDoUsuario($usuario);
        $idsLoja = array_column($carteira, 'id_loja');
        $lojasPorId = array_column($carteira, null, 'id_loja');

        $itens = (new DirecionamentoRepository())->deLojas($idsLoja);

        $ordemMes = (int) date('Ym');
        $statusPorChave = (new AcaoDirecionamentoRepository())->statusAtualDeLojas($idsLoja, $ordemMes);

        foreach ($itens as &$item) {
            $item['loja'] = $lojasPorId[$item['id_loja']] ?? null;
            $chave = implode('|', [$item['id_loja'], $item['kpi'], $item['categoria'] ?? '', $item['componente'] ?? '']);
            $item['status_tratativa'] = $statusPorChave[$chave]['status'] ?? 'aberto';
        }
        unset($item);

        $filtro = $_GET['status'] ?? 'abertos';
        if ($filtro !== 'todos') {
            $mapa = ['abertos' => 'aberto', 'feitas' => 'feita', 'impedidas' => 'impedida', 'ajuda' => 'ajuda'];
            $alvo = $mapa[$filtro] ?? 'aberto';
            $itens = array_values(array_filter($itens, static fn (array $i) => $i['status_tratativa'] === $alvo));
        }

        $this->render('direcionamentos', [
            'itens' => $itens,
            'filtro' => $filtro,
            'ordemMes' => $ordemMes,
        ]);
    }
}
