<?php
/** @var array|null $usuario */
/** @var int $totalLojas */
/** @var array|null $ultimoLote */
declare(strict_types=1);
$usuario = \Rota86\Auth::usuarioLogado();
?>
<h1>Perfil</h1>

<section class="cartao">
    <p><strong>Login:</strong> <?= htmlspecialchars((string) ($usuario['login'] ?? '')) ?></p>
    <p><strong>Perfil:</strong> <?= htmlspecialchars((string) ($usuario['perfil'] ?? '')) ?></p>
    <p><strong>Lojas no escopo:</strong> <?= $totalLojas ?></p>
</section>

<section class="cartao">
    <h2>Fonte e data da última carga</h2>
    <?php if ($ultimoLote !== null): ?>
        <p><?= htmlspecialchars((string) $ultimoLote['origem']) ?> —
           competência <?= htmlspecialchars((string) $ultimoLote['competencia']) ?> —
           carregado em <?= htmlspecialchars((string) $ultimoLote['finalizado_em']) ?></p>
    <?php else: ?>
        <p>Nenhum lote de carga concluído registrado em <code>rota86.lote_carga</code> ainda.</p>
    <?php endif; ?>
</section>
