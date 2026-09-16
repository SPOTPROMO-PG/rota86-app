<?php

declare(strict_types=1);

namespace Rota86\Controllers;

use Rota86\Auth;

final class AuthController extends Controller
{
    public function formulario(): void
    {
        if (Auth::usuarioLogado() !== null) {
            header('Location: /hoje');
            return;
        }
        $this->render('login', ['erro' => $_GET['erro'] ?? null]);
    }

    public function autenticar(): void
    {
        $login = trim((string) ($_POST['login'] ?? ''));
        $senha = (string) ($_POST['senha'] ?? '');

        if ($login === '' || $senha === '' || !Auth::tentarLogin($login, $senha)) {
            header('Location: /login?erro=1');
            return;
        }

        $usuario = Auth::usuarioLogado();
        $destino = Auth::ehPromotor($usuario) ? '/lojas' : '/hoje';
        header('Location: ' . $destino);
    }

    public function sair(): void
    {
        Auth::logout();
        header('Location: /login');
    }
}
