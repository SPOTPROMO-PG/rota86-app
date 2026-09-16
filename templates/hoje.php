<?php
/** @var int $totalLojas */
/** @var float|null $notaMedia */
/** @var array $lojasEmRisco */
/** @var array $topPerdas */
declare(strict_types=1);
?>
<h1>Hoje</h1>

<section class="grade-cartoes">
    <div class="cartao">
        <span class="rotulo">Lojas na carteira</span>
        <span class="valor"><?= $totalLojas ?></span>
    </div>
    <div class="cartao">
        <span class="rotulo">Nota média</span>
        <span class="valor"><?= $notaMedia !== null ? number_format($notaMedia, 1, ',', '.') : '—' ?></span>
    </div>
    <div class="cartao <?= count($lojasEmRisco) > 0 ? 'cartao-alerta' : '' ?>">
        <span class="rotulo">Lojas em risco (crítica/parada)</span>
        <span class="valor"><?= count($lojasEmRisco) ?></span>
    </div>
</section>

<section class="cartao">
    <h2>Onde estamos perdendo mais pontos</h2>
    <?php if ($topPerdas === []): ?>
        <p>Sem direcionamentos pendentes na competência atual.</p>
    <?php else: ?>
        <table class="tabela">
            <thead><tr><th>KPI / Categoria</th><th>Pontos faltantes (soma da carteira)</th></tr></thead>
            <tbody>
            <?php foreach ($topPerdas as $chave => $pontos): ?>
                <tr>
                    <td><?= htmlspecialchars($chave) ?></td>
                    <td><?= number_format($pontos, 1, ',', '.') ?></td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    <?php endif; ?>
</section>
