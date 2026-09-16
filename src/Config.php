<?php

declare(strict_types=1);

namespace Rota86;

/**
 * Lê configuração de .env sem depender de nenhuma lib externa.
 * .env nunca é commitado (ver .gitignore); .env.example documenta as chaves.
 */
final class Config
{
    private static ?array $values = null;

    public static function get(string $key, ?string $default = null): ?string
    {
        self::load();
        return self::$values[$key] ?? $default;
    }

    private static function load(): void
    {
        if (self::$values !== null) {
            return;
        }
        self::$values = [];

        $path = dirname(__DIR__) . '/.env';
        if (!is_file($path)) {
            return;
        }

        foreach (file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
            $line = trim($line);
            if ($line === '' || str_starts_with($line, '#')) {
                continue;
            }
            [$key, $value] = array_pad(explode('=', $line, 2), 2, '');
            $key = trim($key);
            $value = trim($value);
            $value = trim($value, "\"'");
            self::$values[$key] = $value;
        }
    }
}
