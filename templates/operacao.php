<?php
/** @var int $previstoTotal */
/** @var int $executadoTotal */
/** @var array $roteiroHoje */
/** @var array $visitasHoje */
/** @var int $starOk */
/** @var int $starNok */
declare(strict_types=1);
?>
<h1>Operação / Execução</h1>

<section class="grade-cartoes">
    <div class="cartao">
        <span class="rotulo">Visitas no mês</span>
        <span class="valor"><?= $executadoTotal ?> / <?= $previstoTotal ?></span>
    </div>
    <div class="cartao">
        <span class="rotulo">STAR OK</span>
        <span class="valor"><?= $starOk ?></span>
    </div>
    <div class="cartao <?= $starNok > 0 ? 'cartao-alerta' : '' ?>">
        <span class="rotulo">STAR NOK (pendente)</span>
        <span class="valor"><?= $starNok ?></span>
    </div>
</section>

<section class="cartao">
    <h2>Roteiro de hoje</h2>
    <table class="tabela">
        <thead><tr><th>Loja</th><th>Setor</th><th>Status</th><th>Horário real</th></tr></thead>
        <tbody>
        <?php foreach ($roteiroHoje as $r): ?>
            <tr>
                <td><?= htmlspecialchars($r['id_loja']) ?></td>
                <td><?= htmlspecialchars((string) $r['setor_promotor']) ?></td>
                <td><span class="etiqueta"><?= htmlspecialchars((string) $r['status_roteiro']) ?></span></td>
                <td><?= htmlspecialchars((string) ($r['actual_start_time'] ?? '—')) ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
