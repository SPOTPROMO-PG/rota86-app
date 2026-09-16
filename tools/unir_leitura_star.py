"""
Motor de uniao: leitura_por_loja.csv + lojs_star.csv -> retailx_leituras.csv
=============================================================================

Hoje a extracao de leitura (BASES/retailx/leitura_por_loja.csv) e a de
situacao STAR (BASES/retailx/lojs_star.csv) chegam como dois arquivos
separados. Este script une os dois por ID LOJA numa unica tabela, no
formato que rota86.stg_leitura_star_loja espera (ver
MIGRACAO_BANCO/sql/07_visitas_e_leituras.sql).

DECISAO IMPORTANTE (confirmada nos dados reais em 16/09/2026):
    leitura_por_loja.csv tem ~2.937 lojas; lojs_star.csv tem só ~24.
    A maioria das lojas NAO aparece no arquivo de STAR -- isso significa
    "nunca entrou na lista de pendencia STAR daquela competencia", nao
    "esta pendente" (NOK). Por isso o merge e um LEFT JOIN a partir da
    leitura (a base maior e mais completa), e loja sem linha em
    lojs_star.csv fica com status_star = None (NULL), nao 'NOK'.

    Isso corrige uma decisao anterior errada na procedure SQL
    rota86.sp_carregar_leitura_star, que tratava ausencia de STAR como
    NOK por padrao -- essa suposicao valia para um cenario de extracao ja
    unificada do Power BI (uma linha por loja sempre com status), que nao
    e o que os arquivos reais mostram hoje.

Uso:
    python unir_leitura_star.py
        (le os arquivos em BASES/retailx/, grava BASES/retailx/retailx_leituras.csv)

    python unir_leitura_star.py --leitura CAMINHO --star CAMINHO --saida CAMINHO
        (para apontar para outros arquivos/competencia)

Por enquanto isto e uma ferramenta solta, nao esta plugada no pipeline
principal (gerar_rota85.py) nem na carga do banco -- rodar manualmente
quando for preciso conferir/gerar o arquivo unificado.
"""
from __future__ import annotations

import argparse
import csv
from pathlib import Path


def normalizar_id(valor: str) -> str:
    return valor.strip().strip('"')


def normalizar_star(valor: str) -> str | None:
    v = valor.strip().strip('"').upper()
    if v in ("OK", "SIM"):
        return "OK"
    if v in ("NOK", "NÃO", "NAO"):
        return "NOK"
    return None


def ler_leitura(caminho: Path) -> dict[str, dict]:
    linhas: dict[str, dict] = {}
    with caminho.open(encoding="utf-8-sig", newline="") as f:
        leitor = csv.reader(f)
        cabecalho = next(leitor)
        assert len(cabecalho) == 3, f"Cabecalho inesperado em {caminho}: {cabecalho}"
        for linha in leitor:
            if not linha or not linha[0].strip():
                continue
            id_loja = normalizar_id(linha[0])
            linhas[id_loja] = {
                "id_loja": id_loja,
                "target_leitura": normalizar_id(linha[1]),
                "leitura_realizada": normalizar_id(linha[2]),
            }
    return linhas


def ler_star(caminho: Path) -> dict[str, str | None]:
    valores: dict[str, str | None] = {}
    with caminho.open(encoding="utf-8-sig", newline="") as f:
        leitor = csv.reader(f)
        cabecalho = next(leitor)
        assert len(cabecalho) == 2, f"Cabecalho inesperado em {caminho}: {cabecalho}"
        for linha in leitor:
            if not linha or not linha[0].strip():
                continue
            id_loja = normalizar_id(linha[0])
            valores[id_loja] = normalizar_star(linha[1])
    return valores


def unir(leitura: dict[str, dict], star: dict[str, str | None]) -> list[dict]:
    saida = []
    for id_loja, dados in leitura.items():
        saida.append(
            {
                "ID_LOJA": id_loja,
                "TARGET_LEITURA": dados["target_leitura"],
                "LEITURA_REALIZADA": dados["leitura_realizada"],
                "STATUS_STAR": star.get(id_loja) or "",
            }
        )

    # Lojas que só existem no arquivo de STAR (fora do catálogo de leitura
    # do momento) -- preservadas para não perder a informação, com leitura
    # em branco. Isso já era um caso conhecido (documentado em
    # 01_MAPA_ATUAL.md: "973 fora do catálogo atual").
    ids_leitura = set(leitura.keys())
    for id_loja, status in star.items():
        if id_loja not in ids_leitura:
            saida.append(
                {
                    "ID_LOJA": id_loja,
                    "TARGET_LEITURA": "",
                    "LEITURA_REALIZADA": "",
                    "STATUS_STAR": status or "",
                }
            )

    saida.sort(key=lambda r: r["ID_LOJA"])
    return saida


def gravar(saida: list[dict], caminho: Path) -> None:
    caminho.parent.mkdir(parents=True, exist_ok=True)
    with caminho.open("w", encoding="utf-8-sig", newline="") as f:
        escritor = csv.DictWriter(f, fieldnames=["ID_LOJA", "TARGET_LEITURA", "LEITURA_REALIZADA", "STATUS_STAR"])
        escritor.writeheader()
        escritor.writerows(saida)


def main() -> None:
    raiz = Path(__file__).resolve().parents[1] / "BASES" / "retailx"

    parser = argparse.ArgumentParser(description="Une leitura_por_loja.csv + lojs_star.csv por ID LOJA")
    parser.add_argument("--leitura", default=str(raiz / "leitura_por_loja.csv"))
    parser.add_argument("--star", default=str(raiz / "lojs_star.csv"))
    parser.add_argument("--saida", default=str(raiz / "retailx_leituras.csv"))
    args = parser.parse_args()

    leitura = ler_leitura(Path(args.leitura))
    star = ler_star(Path(args.star))
    unificado = unir(leitura, star)
    gravar(unificado, Path(args.saida))

    com_star = sum(1 for r in unificado if r["STATUS_STAR"])
    so_star = sum(1 for r in unificado if not r["TARGET_LEITURA"])
    print(f"Leitura: {len(leitura)} lojas | STAR: {len(star)} lojas")
    print(f"Unificado: {len(unificado)} linhas ({com_star} com status STAR, {so_star} só existiam no arquivo de STAR)")
    print(f"Gravado em: {args.saida}")


if __name__ == "__main__":
    main()
