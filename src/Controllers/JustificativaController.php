<?php

declare(strict_types=1);

namespace Rota86\Controllers;

use Rota86\Repositories\JustificativaRepository;
use Rota86\Repositories\AcaoDirecionamentoRepository;

/**
 * Endpoints de escrita chamados via fetch() do front-end (mesmo padrão do
 * v3: salva local primeiro, confirma com o servidor depois — ver
 * templates/assets/app.js). Sempre JSON.
 */
final class JustificativaController extends Controller
{
    /** POST /api/justificativa */
    public function salvar(): void
    {
        $usuario = $this->exigirLoginJson();
        $dados = $this->corpoJson();

        foreach (['id_justificativa', 'tipo', 'id_loja'] as $campo) {
            if (empty($dados[$campo])) {
                $this->renderJson(['erro' => "Campo obrigatório ausente: {$campo}"], 422);
                return;
            }
        }

        $dados['cod_pessoa'] ??= $usuario['cod_pessoa'];
        $dados['setor_acesso'] ??= $usuario['perfil'];
        $dados['origem'] ??= 'site';
        $dados['registrado_em_app'] ??= (new \DateTimeImmutable())->format('Y-m-d\TH:i:s');

        $resultado = (new JustificativaRepository())->upsert($dados);
        $this->renderJson($resultado);
    }

    /** POST /api/acao-direcionamento — "Executei"/"Reabrir"/"Impedimento"/"Ajuda" */
    public function registrarAcao(): void
    {
        $usuario = $this->exigirLoginJson();
        $dados = $this->corpoJson();

        foreach (['id_loja', 'kpi', 'status', 'ordem_mes'] as $campo) {
            if (empty($dados[$campo]) && $dados[$campo] !== 0) {
                $this->renderJson(['erro' => "Campo obrigatório ausente: {$campo}"], 422);
                return;
            }
        }

        $dados['cod_pessoa'] ??= $usuario['cod_pessoa'];

        (new AcaoDirecionamentoRepository())->registrar($dados);
        $this->renderJson(['ok' => true]);
    }
}
