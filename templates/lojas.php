<?php
/** @var array $lojas */
/** @var int $total */
/** @var int $pagina */
/** @var int $porPagina */
/** @var array|null $minhaSemana */
/** @var bool $ehPromotor */
declare(strict_types=1);
?>
<h1><?= $ehPromotor ? 'Minhas lojas' : 'Lojas' ?></h1>

<?php if (!$ehPromotor): ?>
<form method="get" class="busca">
    <input type="text" name="q" placeholder="Buscar por nome, rede, cidade ou ID" value="<?= htmlspecialchars((string) ($_GET['q'] ?? '')) ?>">
    <button type="submit">Buscar</button>
</form>
<?php endif; ?>

<?php if ($minhaSemana !== null): ?>
<section class="cartao">
    <h2>Minha semana</h2>
    <p>Roteiro recorrente da carteira (mesma agenda usada no cálculo do roteiro do dia).</p>
    <table class="tabela">
        <thead><tr><th>Dia</th><th>Loja</th><th>Ordem</th><th>Horas</th></tr></thead>
        <tbody>
        <?php $dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom']; ?>
        <?php foreach ($minhaSemana as $v): ?>
            <tr>
                <td><?= $dias[(int) $v['dia_idx']] ?? '?' ?></td>
                <td><?= htmlspecialchars($v['id_loja']) ?></td>
                <td><?= htmlspecialchars((string) $v['ordem']) ?></td>
                <td><?= $v['horas'] !== null ? number_format((float) $v['horas'], 1, ',', '.') : '—' ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php endif; ?>

<table class="tabela">
    <thead><tr><th>Loja</th><th>Rede</th><th>Cidade</th><th>Nota</th><th>Tendência</th></tr></thead>
    <tbody>
    <?php foreach ($lojas as $l): ?>
        <?php $p = $l['pontuacao'] ?? null; ?>
        <tr>
            <td><a href="/loja?id=<?= urlencode($l['id_loja']) ?>"><?= htmlspecialchars((string) ($l['nome_loja'] ?? $l['id_loja'])) ?></a></td>
            <td><?= htmlspecialchars((string) ($l['rede'] ?? '—')) ?></td>
            <td><?= htmlspecialchars((string) ($l['cidade_uf'] ?? '—')) ?></td>
            <td><?= $p && $p['nota_atual'] !== null ? number_format((float) $p['nota_atual'], 1, ',', '.') : '—' ?></td>
            <td><?= $p && $p['slope'] !== null ? number_format((float) $p['slope'], 2, ',', '.') : '—' ?></td>
        </tr>
    <?php endforeach; ?>
    </tbody>
</table>

<?php $totalPaginas = (int) ceil($total / $porPagina); if ($totalPaginas > 1): ?>
<nav class="paginacao">
    <?php for ($i = 1; $i <= $totalPaginas; $i++): ?>
        <a href="?pagina=<?= $i ?>" class="<?= $i === $pagina ? 'ativo' : '' ?>"><?= $i ?></a>
    <?php endfor; ?>
</nav>
<?php endif; ?>
