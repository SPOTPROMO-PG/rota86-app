<?php

declare(strict_types=1);

namespace Rota86\Repositories;

use Rota86\Database;

/**
 * Escreve via rota86.sp_upsert_justificativa (idempotente por
 * id_justificativa — reenvio do mesmo id confirma sem duplicar, mesma
 * regra do Apps Script hoje). Nunca faz INSERT direto na tabela.
 */
final class JustificativaRepository
{
    /** @return array{id_justificativa: string, duplicado: bool} */
    public function upsert(array $dados): array
    {
        $sql = 'EXEC rota86.sp_upsert_justificativa
            @id_justificativa = ?, @tipo = ?, @id_loja = ?, @cod_rota = ?, @cod_pessoa = ?,
            @setor_acesso = ?, @nota_atual = ?, @mes_leitura = ?, @kpi = ?, @categoria = ?,
            @justificativa_texto = ?, @observacao = ?, @data_visita = ?, @setor_promotor = ?,
            @visit_id = ?, @status_visita = ?, @cod_motivo_nao_realizacao = ?, @origem = ?,
            @registrado_em_app = ?';

        $params = [
            $dados['id_justificativa'],
            $dados['tipo'],
            $dados['id_loja'],
            $dados['cod_rota'] ?? null,
            $dados['cod_pessoa'] ?? null,
            $dados['setor_acesso'] ?? null,
            $dados['nota_atual'] ?? null,
            $dados['mes_leitura'] ?? null,
            $dados['kpi'] ?? null,
            $dados['categoria'] ?? null,
            $dados['justificativa_texto'] ?? null,
            $dados['observacao'] ?? null,
            $dados['data_visita'] ?? null,
            $dados['setor_promotor'] ?? null,
            $dados['visit_id'] ?? null,
            $dados['status_visita'] ?? null,
            $dados['cod_motivo_nao_realizacao'] ?? null,
            $dados['origem'] ?? 'site',
            $dados['registrado_em_app'] ?? null,
        ];

        $resultado = Database::queryOne($sql, $params);

        return [
            'id_justificativa' => $resultado['id_justificativa'] ?? $dados['id_justificativa'],
            'duplicado' => (bool) ($resultado['duplicado'] ?? false),
        ];
    }

    /** Últimas justificativas de uma loja (auditoria/consulta). */
    public function daLoja(string $idLoja, int $limite = 50): array
    {
        return Database::query(
            'SELECT TOP (' . (int) $limite . ") * FROM rota86.justificativa
             WHERE id_loja = ? ORDER BY registrado_em_servidor DESC",
            [$idLoja]
        );
    }
}
