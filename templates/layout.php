<?php
/** @var array|null $usuario */
/** @var string $conteudo */
declare(strict_types=1);
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ROTA86</title>
<link rel="stylesheet" href="/assets/app.css">
</head>
<body>
<?php if ($usuario !== null): ?>
<header class="topbar">
    <div class="topbar-marca">ROTA86</div>
    <div class="topbar-usuario">
        <span><?= htmlspecialchars((string) ($usuario['perfil'] ?? '')) ?></span>
        <a href="/logout">Sair</a>
    </div>
</header>
<nav class="tabbar">
    <?php $ehPromotor = \Rota86\Auth::ehPromotor($usuario); ?>
    <?php if ($ehPromotor): ?>
        <a href="/lojas">Minhas lojas</a>
        <a href="/direcionamentos">Direcionamentos</a>
        <a href="/perfil">Perfil</a>
    <?php else: ?>
        <a href="/hoje">Hoje</a>
        <a href="/pontuacao">Pontuação</a>
        <a href="/equipe">Equipe</a>
        <a href="/redes">Redes e Cidades</a>
        <a href="/lojas">Lojas</a>
        <a href="/operacao">Operação</a>
        <a href="/perfil">Perfil</a>
    <?php endif; ?>
</nav>
<?php endif; ?>
<main class="conteudo">
<?= $conteudo ?>
</main>
<script src="/assets/app.js"></script>
</body>
</html>
