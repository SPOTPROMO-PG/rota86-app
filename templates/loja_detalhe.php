<?php
/** @var array $loja */
/** @var array $historico */
/** @var array $direcionamentos */
/** @var array|null $mop */
/** @var array|null $leitura */
declare(strict_types=1);
?>
<h1><?= htmlspecialchars((string) ($loja['nome_loja'] ?? $loja['id_loja'])) ?></h1>
<p class="subtitulo">
    <?= htmlspecialchars((string) ($loja['rede'] ?? '—')) ?> ·
    <?= htmlspecialchars((string) ($loja['cidade_uf'] ?? '—')) ?> ·
    <?= htmlspecialchars((string) ($loja['canal'] ?? '—')) ?> ·
    Setor <?= htmlspecialchars((string) ($loja['setor_promotor'] ?? '—')) ?> ·
    Promotor: <?= htmlspecialchars((string) ($loja['nome_promotor'] ?? 'vaga')) ?>
</p>

<?php if ($leitura !== null): ?>
<section class="cartao">
    <h2>Leitura do mês</h2>
    <p><?= (int) $leitura['leitura_realizada'] ?> de <?= (int) $leitura['target_leitura'] ?> —
       STAR: <span class="etiqueta"><?= htmlspecialchars($leitura['status_star']) ?></span></p>
</section>
<?php endif; ?>

<section class="cartao">
    <h2>Últimas pontuações</h2>
    <table class="tabela">
        <thead><tr><th>Mês</th><th>Total</th><th>SOS</th><th>KBD</th><th>PE</th><th>CKO</th></tr></thead>
        <tbody>
        <?php foreach ($historico as $h): ?>
            <tr>
                <td><?= htmlspecialchars((string) $h['mes_referencia']) ?></td>
                <td><?= $h['score_total'] !== null ? number_format((float) $h['score_total'], 1, ',', '.') : '—' ?></td>
                <td><?= $h['score_sos'] !== null ? number_format((float) $h['score_sos'], 1, ',', '.') : '—' ?></td>
                <td><?= $h['score_kbd'] !== null ? number_format((float) $h['score_kbd'], 1, ',', '.') : '—' ?></td>
                <td><?= $h['score_pe'] !== null ? number_format((float) $h['score_pe'], 1, ',', '.') : '—' ?></td>
                <td><?= $h['score_cko'] !== null ? number_format((float) $h['score_cko'], 1, ',', '.') : '—' ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>

<section class="cartao">
    <h2>Plano da visita — o que falta executar</h2>
    <?php if ($direcionamentos === []): ?>
        <p>Sem pendências nesta competência.</p>
    <?php endif; ?>
    <?php foreach ($direcionamentos as $item): ?>
        <article class="cartao-direcionamento" data-item
            data-id-loja="<?= htmlspecialchars($loja['id_loja']) ?>"
            data-kpi="<?= htmlspecialchars($item['kpi']) ?>"
            data-categoria="<?= htmlspecialchars((string) $item['categoria']) ?>"
            data-componente="<?= htmlspecialchars((string) $item['componente']) ?>"
            data-ordem-mes="<?= htmlspecialchars((string) $item['ordem_mes']) ?>">
            <header>
                <span class="etiqueta"><?= htmlspecialchars($item['kpi']) ?></span>
                <span class="pontos">+<?= number_format((float) $item['pontos_faltantes'], 1, ',', '.') ?> pts</span>
            </header>
            <p><?= htmlspecialchars((string) $item['categoria']) ?> — <?= htmlspecialchars((string) $item['acao_sugerida']) ?></p>
            <footer class="acoes">
                <button class="acao-tratativa" data-status="feita">Executei</button>
                <button class="acao-tratativa" data-status="impedida">Impedimento</button>
                <button class="acao-tratativa" data-status="ajuda">Preciso de ajuda</button>
                <?php if ($item['kpi'] === 'SOS'): ?>
                    <a href="/calculadora-sos?id=<?= urlencode($loja['id_loja']) ?>">Calcular SOS</a>
                <?php endif; ?>
            </footer>
        </article>
    <?php endforeach; ?>
</section>

<?php if ($mop !== null): ?>
<section class="cartao">
    <h2>MOP — orientações de execução</h2>
    <p><?= htmlspecialchars((string) $mop['mop_type']) ?> ·
       Visita: <?= htmlspecialchars((string) $mop['frequencia_visita']) ?> ·
       Leitura: <?= htmlspecialchars((string) $mop['frequencia_leitura']) ?></p>
    <ul>
    <?php foreach ($mop['itens'] as $item): ?>
        <li><strong><?= htmlspecialchars((string) $item['kpi']) ?></strong> —
            <?= htmlspecialchars((string) $item['categoria']) ?>:
            <?= htmlspecialchars((string) $item['item']) ?>
            (<?= htmlspecialchars((string) $item['objetivo']) ?>)</li>
    <?php endforeach; ?>
    </ul>
</section>
<?php endif; ?>
