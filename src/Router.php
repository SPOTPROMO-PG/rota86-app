<?php

declare(strict_types=1);

namespace Rota86;

/**
 * Roteador mínimo próprio (sem dependência externa) — array de rotas para
 * [Controller::class, 'metodo']. Suficiente para o tamanho deste app; troque
 * por algo mais robusto só se o projeto crescer muito além destas telas.
 */
final class Router
{
    /** @var array<string, array<string, array{0: class-string, 1: string}>> */
    private array $rotas = ['GET' => [], 'POST' => []];

    public function get(string $caminho, string $controller, string $metodo): void
    {
        $this->rotas['GET'][$caminho] = [$controller, $metodo];
    }

    public function post(string $caminho, string $controller, string $metodo): void
    {
        $this->rotas['POST'][$caminho] = [$controller, $metodo];
    }

    public function despachar(string $metodoHttp, string $uri): void
    {
        $caminho = parse_url($uri, PHP_URL_PATH) ?: '/';
        $caminho = rtrim($caminho, '/');
        if ($caminho === '') {
            $caminho = '/';
        }

        $rota = $this->rotas[$metodoHttp][$caminho] ?? null;
        if ($rota === null) {
            http_response_code(404);
            echo '404 — rota não encontrada: ' . htmlspecialchars($caminho);
            return;
        }

        [$controllerClasse, $metodo] = $rota;
        $controller = new $controllerClasse();
        $controller->$metodo();
    }
}
