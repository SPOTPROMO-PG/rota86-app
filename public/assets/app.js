// ROTA86 — JS mínimo, sem framework. Cobre só as duas ações de escrita que
// o app tem hoje: registrar tratativa de direcionamento e (fora deste
// arquivo, formulário nativo) enviar justificativa.
// Ver src/Controllers/JustificativaController.php para os endpoints.

document.addEventListener('click', async (evento) => {
    const botao = evento.target.closest('.acao-tratativa');
    if (!botao) return;

    const item = botao.closest('[data-item]');
    if (!item) return;

    const status = botao.dataset.status;
    const payload = {
        id_loja: item.dataset.idLoja,
        kpi: item.dataset.kpi,
        categoria: item.dataset.categoria || null,
        componente: item.dataset.componente || null,
        ordem_mes: parseInt(item.dataset.ordemMes, 10),
        status,
    };

    if (status === 'impedida' || status === 'ajuda') {
        const motivo = prompt(status === 'impedida' ? 'Motivo do impedimento:' : 'O que você precisa?');
        if (motivo === null) return; // cancelou
        payload.motivo = motivo;
    }

    botao.disabled = true;
    try {
        const resposta = await fetch('/api/acao-direcionamento', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
        });
        if (!resposta.ok) {
            throw new Error('Falha ao registrar (' + resposta.status + ')');
        }
        const statusEl = item.querySelector('.status-atual');
        if (statusEl) statusEl.textContent = 'Status: ' + status;
    } catch (erro) {
        alert('Não foi possível registrar agora. Tente novamente. (' + erro.message + ')');
    } finally {
        botao.disabled = false;
    }
});

// Calculadora SOS — cálculo local, sem envio ao servidor (ver
// templates/calculadora_sos.php e docs/TELAS_E_REGRAS.md).
const formSos = document.getElementById('form-calculadora-sos');
if (formSos) {
    const saida = document.getElementById('resultado-sos');
    const recalcular = () => {
        const dados = new FormData(formSos);
        const pg = parseFloat(dados.get('pg')) || 0;
        const universo = parseFloat(dados.get('universo')) || 0;
        if (universo <= 0) {
            saida.textContent = '';
            return;
        }
        const pct = (pg / universo) * 100;
        saida.textContent = pct.toFixed(1) + '% de SOS (' + pg.toFixed(1) + ' de ' + universo.toFixed(1) + ' cm)';

        try {
            const categoria = dados.get('categoria');
            const chave = 'rota86_sos_calculadora_v1';
            const armazenado = JSON.parse(localStorage.getItem(chave) || '{}');
            armazenado[categoria] = { pg, universo, atualizadoEm: new Date().toISOString() };
            localStorage.setItem(chave, JSON.stringify(armazenado));
        } catch (e) {
            // localStorage indisponível (modo privado, etc.) — segue sem persistir.
        }
    };
    formSos.addEventListener('input', recalcular);
}
