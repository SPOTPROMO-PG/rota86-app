<?php
/** @var array $atual */
/** @var array $serieFechamento */
declare(strict_types=1);
?>
<h1>Pontuação</h1>

<section class="cartao">
    <h2>Série histórica da carteira</h2>
    <table class="tabela">
        <thead><tr><th>Mês</th><th>Nota média</th><th>Lojas com nota</th></tr></thead>
        <tbody>
        <?php foreach ($serieFechamento as $m): ?>
            <tr>
                <td><?= htmlspecialchars((string) $m['mes_referencia']) ?></td>
                <td><?= $m['media'] !== null ? number_format($m['media'], 1, ',', '.') : '—' ?></td>
                <td><?= $m['n'] ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>

<section class="cartao">
    <h2>Situação atual por loja</h2>
    <table class="tabela">
        <thead><tr><th>Loja</th><th>Nota</th><th>Tendência (slope)</th><th>Risco</th></tr></thead>
        <tbody>
        <?php foreach ($atual as $p): ?>
            <tr>
                <td><?= htmlspecialchars($p['id_loja']) ?></td>
                <td><?= $p['nota_atual'] !== null ? number_format((float) $p['nota_atual'], 1, ',', '.') : '—' ?></td>
                <td><?= $p['slope'] !== null ? number_format((float) $p['slope'], 2, ',', '.') : '—' ?></td>
                <td><?= (int) $p['risco'] ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
