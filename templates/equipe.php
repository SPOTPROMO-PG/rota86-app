<?php
/** @var array $grupos */
declare(strict_types=1);
?>
<h1>Equipe</h1>

<table class="tabela">
    <thead><tr><th>Responsável</th><th>Lojas</th><th>Nota média</th><th>Abaixo do gate (77)</th><th>Sem leitura</th><th>Em risco</th></tr></thead>
    <tbody>
    <?php foreach ($grupos as $g): ?>
        <tr>
            <td><a href="/lojas?q=<?= urlencode((string) $g['nome']) ?>"><?= htmlspecialchars((string) $g['nome']) ?></a></td>
            <td><?= $g['n'] ?? 0 ?></td>
            <td><?= $g['media'] !== null ? number_format($g['media'], 1, ',', '.') : '—' ?></td>
            <td><?= $g['abaixoGate'] ?? 0 ?></td>
            <td><?= $g['semLeitura'] ?? 0 ?></td>
            <td><?= $g['risco'] ?? 0 ?></td>
        </tr>
    <?php endforeach; ?>
    </tbody>
</table>
