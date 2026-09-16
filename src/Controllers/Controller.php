<?php

declare(strict_types=1);

namespace Rota86\Controllers;

use Rota86\Auth;

abstract class Controller
{
    /** Renderiza um template dentro da casca comum (templates/layout.php). */
    protected function render(string $template, array $dados = []): void
    {
        $usuario = Auth::usuarioLogado();
        extract($dados, EXTR_SKIP);

        $caminhoConteudo = dirname(__DIR__, 2) . "/templates/{$template}.php";
        $caminhoLayout = dirname(__DIR__, 2) . '/templates/layout.php';

        ob_start();
        require $caminhoConteudo;
        $conteudo = ob_get_clean();

        require $caminhoLayout;
    }

    protected function renderJson(array $dados, int $status = 200): void
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($dados, JSON_UNESCAPED_UNICODE);
    }

    protected function exigirLogin(): array
    {
        return Auth::exigirLogin();
    }

    /** Igual a exigirLogin(), mas responde 401 JSON em vez de redirecionar — para endpoints /api/*. */
    protected function exigirLoginJson(): array
    {
        $usuario = Auth::usuarioLogado();
        if ($usuario === null) {
            $this->renderJson(['erro' => 'Não autenticado.'], 401);
            exit;
        }
        return $usuario;
    }

    protected function corpoJson(): array
    {
        $bruto = file_get_contents('php://input');
        $dados = json_decode($bruto ?: '{}', true);
        return is_array($dados) ? $dados : [];
    }
}
