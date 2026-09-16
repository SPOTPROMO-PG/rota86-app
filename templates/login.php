<?php
/** @var string|null $erro */
declare(strict_types=1);
?>
<section class="cartao cartao-login">
    <h1>ROTA86</h1>
    <?php if ($erro): ?>
        <p class="alerta">Login ou senha inválidos.</p>
    <?php endif; ?>
    <form method="post" action="/login">
        <label>Usuário<br><input type="text" name="login" required autofocus></label>
        <label>Senha<br><input type="password" name="senha" required></label>
        <button type="submit">Entrar</button>
    </form>
</section>
