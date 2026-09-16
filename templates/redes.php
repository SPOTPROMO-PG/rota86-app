<?php
/** @var array $grupos */
/** @var string $aba */
declare(strict_types=1);
?>
<h1>Redes e Cidades</h1>

<nav class="filtros">
    <?php foreach (['rede' => 'Rede', 'cidade' => 'Cidade', 'canal' => 'Canal'] as $chave => $rotulo): ?>
        <a href="?aba=<?= $chave ?>" class="<?= $aba === $chave ? 'ativo' : '' ?>"><?= $rotulo ?></a>
    <?php endforeach; ?>
</nav>

<table class="tabela">
    <thead><tr><th><?= ucfirst($aba) ?></th><th>Lojas</th><th>Nota média</th></tr></thead>
    <tbody>
    <?php foreach ($grupos as $g): ?>
        <tr>
            <td><?= htmlspecialchars((string) $g['nome']) ?></td>
            <td><?= $g['n'] ?? 0 ?></td>
            <td><?= $g['media'] !== null ? number_format($g['media'], 1, ',', '.') : '—' ?></td>
        </tr>
    <?php endforeach; ?>
    </tbody>
</table>
