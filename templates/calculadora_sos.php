<?php
/** @var string $idLoja */
/** @var array $opcoes */
declare(strict_types=1);
?>
<h1>Calculadora SOS</h1>
<p>Loja: <?= htmlspecialchars($idLoja) ?></p>

<p class="aviso">
    O cálculo é feito no navegador e salvo só neste aparelho
    (<code>localStorage</code>), igual ao app atual — não é enviado ao
    servidor. Ver <code>docs/TELAS_E_REGRAS.md</code> para a decisão em
    aberto sobre persistir essa medição.
</p>

<form id="form-calculadora-sos">
    <label>Categoria
        <select name="categoria">
            <?php foreach ($opcoes as $o): ?>
                <option value="<?= htmlspecialchars((string) $o['categoria']) ?>">
                    <?= htmlspecialchars((string) $o['categoria']) ?> (meta <?= htmlspecialchars((string) $o['objetivo']) ?>%)
                </option>
            <?php endforeach; ?>
        </select>
    </label>
    <label>Espaço P&amp;G (cm) <input type="number" name="pg" step="0.1" min="0"></label>
    <label>Espaço total da categoria (cm) <input type="number" name="universo" step="0.1" min="0"></label>
    <output id="resultado-sos"></output>
</form>
