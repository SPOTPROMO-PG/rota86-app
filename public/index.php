<?php

declare(strict_types=1);

// Autoload próprio (PSR-4 simplificado, sem Composer) — mapeia
// Rota86\Foo\Bar para src/Foo/Bar.php. Ver README.md "Como rodar".
spl_autoload_register(static function (string $classe): void {
    $prefixo = 'Rota86\\';
    if (!str_starts_with($classe, $prefixo)) {
        return;
    }
    $caminhoRelativo = str_replace('\\', '/', substr($classe, strlen($prefixo)));
    $arquivo = dirname(__DIR__) . '/src/' . $caminhoRelativo . '.php';
    if (is_file($arquivo)) {
        require $arquivo;
    }
});

session_start();

use Rota86\Router;
use Rota86\Controllers\AuthController;
use Rota86\Controllers\HojeController;
use Rota86\Controllers\DirecionamentosController;
use Rota86\Controllers\PontuacaoController;
use Rota86\Controllers\EquipeController;
use Rota86\Controllers\RedesController;
use Rota86\Controllers\LojasController;
use Rota86\Controllers\OperacaoController;
use Rota86\Controllers\PerfilController;
use Rota86\Controllers\JustificativaController;

$router = new Router();

$router->get('/login', AuthController::class, 'formulario');
$router->post('/login', AuthController::class, 'autenticar');
$router->get('/logout', AuthController::class, 'sair');

$router->get('/hoje', HojeController::class, 'index');
$router->get('/direcionamentos', DirecionamentosController::class, 'index');
$router->get('/pontuacao', PontuacaoController::class, 'index');
$router->get('/fechamentos', PontuacaoController::class, 'fechamentos');
$router->get('/equipe', EquipeController::class, 'index');
$router->get('/redes', RedesController::class, 'index');
$router->get('/lojas', LojasController::class, 'index');
$router->get('/loja', LojasController::class, 'detalhe');
$router->get('/calculadora-sos', LojasController::class, 'calculadoraSos');
$router->get('/operacao', OperacaoController::class, 'index');
$router->get('/perfil', PerfilController::class, 'index');

$router->post('/api/justificativa', JustificativaController::class, 'salvar');
$router->post('/api/acao-direcionamento', JustificativaController::class, 'registrarAcao');

$router->get('/', LojasController::class, 'index');

$router->despachar($_SERVER['REQUEST_METHOD'], $_SERVER['REQUEST_URI']);
