<?php

declare(strict_types=1);

namespace Rota86;

use PDO;
use PDOException;

/**
 * Wrapper fino sobre PDO (driver sqlsrv, extensão oficial da Microsoft:
 * https://learn.microsoft.com/sql/connect/php/microsoft-php-driver-for-sql-server).
 * Nunca usado diretamente pelos Controllers — só pelos Repositories.
 * Toda query passa por prepared statement; nenhuma interpolação de string.
 */
final class Database
{
    private static ?PDO $instance = null;

    public static function connection(): PDO
    {
        if (self::$instance !== null) {
            return self::$instance;
        }

        $server = Config::get('DB_SERVER', '172.18.0.59');
        $database = Config::get('DB_DATABASE', 'bi_pg_promotores');
        $user = Config::get('DB_USER');
        $password = Config::get('DB_PASSWORD');

        $dsn = "sqlsrv:Server={$server};Database={$database}";

        try {
            if ($user !== null && $user !== '') {
                // Autenticação SQL — usuário técnico dedicado (ver docs/ORIGEM_DOS_DADOS.md).
                self::$instance = new PDO($dsn, $user, $password, [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                ]);
            } else {
                // Sem usuário/senha configurados: tenta autenticação integrada
                // (só funciona se o processo PHP rodar sob uma identidade
                // Windows com acesso ao SQL Server — típico em IIS com App
                // Pool dedicado, não em hosting compartilhado Linux).
                self::$instance = new PDO($dsn, null, null, [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                ]);
            }
        } catch (PDOException $e) {
            throw new PDOException(
                'Falha ao conectar no SQL Server. Confira DB_SERVER/DB_DATABASE/DB_USER/DB_PASSWORD ' .
                'no .env e se a extensão pdo_sqlsrv está habilitada (ver README.md). Detalhe: ' . $e->getMessage(),
                (int) $e->getCode()
            );
        }

        return self::$instance;
    }

    /** @return array<int, array<string, mixed>> */
    public static function query(string $sql, array $params = []): array
    {
        $stmt = self::connection()->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll();
    }

    /** @return array<string, mixed>|null */
    public static function queryOne(string $sql, array $params = []): ?array
    {
        $rows = self::query($sql, $params);
        return $rows[0] ?? null;
    }

    public static function execute(string $sql, array $params = []): int
    {
        $stmt = self::connection()->prepare($sql);
        $stmt->execute($params);
        return $stmt->rowCount();
    }
}
