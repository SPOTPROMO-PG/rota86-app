<?php
/** @var array $itens */
/** @var string $filtro */
/** @var int $ordemMes */
declare(strict_types=1);
?>
<h1>Direcionamentos</h1>

<nav class="filtros">
    <?php foreach (['abertos' => 'Abertos', 'todos' => 'Todos', 'feitas' => 'Feitas', 'impedidas' => 'Impedidas', 'ajuda' => 'Pediu ajuda'] as $chave => $rotulo): ?>
        <a href="?status=<?= $chave ?>" class="<?= $filtro === $chave ? 'ativo' : '' ?>"><?= $rotulo ?></a>
    <?php endforeach; ?>
</nav>

<?php if ($itens === []): ?>
    <p>Nenhum direcionamento nesse filtro.</p>
<?php endif; ?>

<?php foreach ($itens as $item): ?>
    <article class="cartao cartao-direcionamento" data-item
        data-id-loja="<?= htmlspecialchars($item['id_loja']) ?>"
        data-kpi="<?= htmlspecialchars($item['kpi']) ?>"
        data-categoria="<?= htmlspecialchars((string) $item['categoria']) ?>"
        data-componente="<?= htmlspecialchars((string) $item['componente']) ?>"
        data-ordem-mes="<?= $ordemMes ?>">
        <header>
            <strong><?= htmlspecialchars($item['loja']['nome_loja'] ?? $item['id_loja']) ?></strong>
            <span class="etiqueta"><?= htmlspecialchars($item['kpi']) ?></span>
            <span class="pontos">+<?= number_format((float) $item['pontos_faltantes'], 1, ',', '.') ?> pts</span>
        </header>
        <p><?= htmlspecialchars((string) $item['categoria']) ?> — <?= htmlspecialchars((string) $item['acao_sugerida']) ?></p>
        <p class="regra"><?= htmlspecialchars((string) $item['regra_mop']) ?></p>
        <footer class="acoes">
            <button class="acao-tratativa" data-status="feita">Executei</button>
            <button class="acao-tratativa" data-status="impedida">Impedimento</button>
            <button class="acao-tratativa" data-status="ajuda">Preciso de ajuda</button>
            <span class="status-atual">Status: <?= htmlspecialchars($item['status_tratativa']) ?></span>
        </footer>
    </article>
<?php endforeach; ?>
