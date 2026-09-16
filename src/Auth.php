<?php

declare(strict_types=1);

namespace Rota86;

/**
 * Login real por pessoa (substitui a senha única compartilhada do v3 —
 * ver docs/ARQUITETURA.md, seção "Acesso/login"). Perfil vem de
 * dbo.bi_d_pessoa.PERFIL via rota86.vw_usuario_perfil, não é reinventado.
 */
final class Auth
{
    public static function tentarLogin(string $login, string $senha): bool
    {
        $usuario = Database::queryOne(
            'SELECT id, login, senha_hash, ativo FROM rota86.usuario WHERE login = ? AND ativo = 1',
            [$login]
        );

        if ($usuario === null || $usuario['senha_hash'] === null) {
            return false;
        }

        // senha_hash é VARBINARY no banco; PDO sqlsrv devolve como string binária.
        $hash = is_resource($usuario['senha_hash']) ? stream_get_contents($usuario['senha_hash']) : $usuario['senha_hash'];

        if (!password_verify($senha, $hash)) {
            return false;
        }

        $perfil = Database::queryOne(
            'SELECT usuario_id, login, cod_pessoa, perfil, cod_perfil FROM rota86.vw_usuario_perfil WHERE usuario_id = ?',
            [$usuario['id']]
        );

        $escopos = Database::query(
            'SELECT tipo_escopo, cod_pessoa_ref, valor_texto FROM rota86.usuario_escopo WHERE usuario_id = ?',
            [$usuario['id']]
        );

        Database::execute('UPDATE rota86.usuario SET ultimo_login_em = SYSUTCDATETIME() WHERE id = ?', [$usuario['id']]);

        $_SESSION['rota86_usuario'] = [
            'id' => $usuario['id'],
            'login' => $usuario['login'],
            'cod_pessoa' => $perfil['cod_pessoa'] ?? null,
            'perfil' => $perfil['perfil'] ?? null,
            'escopos' => $escopos,
        ];

        return true;
    }

    public static function logout(): void
    {
        unset($_SESSION['rota86_usuario']);
        session_regenerate_id(true);
    }

    public static function usuarioLogado(): ?array
    {
        return $_SESSION['rota86_usuario'] ?? null;
    }

    public static function exigirLogin(): array
    {
        $usuario = self::usuarioLogado();
        if ($usuario === null) {
            header('Location: /login');
            exit;
        }
        return $usuario;
    }

    /** Perfil normalizado usado nas decisões de visibilidade (ver docs/TELAS_E_REGRAS.md). */
    public static function ehPromotor(array $usuario): bool
    {
        return strtoupper((string) ($usuario['perfil'] ?? '')) === 'PROMOTOR';
    }
}
