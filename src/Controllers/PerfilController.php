<?php

declare(strict_types=1);

namespace Rota86\Controllers;

use Rota86\Database;
use Rota86\Repositories\CarteiraRepository;

final class PerfilController extends Controller
{
    public function index(): void
    {
        $usuario = $this->exigirLogin();
        $carteira = (new CarteiraRepository())->carteiraDoUsuario($usuario);

        $ultimoLote = Database::queryOne(
            'SELECT TOP 1 origem, competencia, finalizado_em, status
             FROM rota86.lote_carga
             WHERE status = ?
             ORDER BY finalizado_em DESC',
            ['concluido']
        );

        $this->render('perfil', [
            'totalLojas' => count($carteira),
            'ultimoLote' => $ultimoLote,
        ]);
    }
}
