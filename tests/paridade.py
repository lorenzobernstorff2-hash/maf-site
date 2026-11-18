#!/usr/bin/env python3
"""Confere os números de tests/condicoes.json com os que a Gaby pratica.

A Gaby (repo maf-private-label) é quem manda nas condições comerciais. Entre
30/10 e 17/11/2026 o site ficou prometendo PIX 5% e cartão 3x depois de ela
mudar, e ninguém notou. Aqui a comparação é por máquina:

  tests/paridade.py                  # busca a main remota da Gaby e compara
  tests/paridade.py --gravar-prosa   # depois de reler o texto dela, regrava o hash

Sai 1 quando um número diverge, quando a Gaby ganhou ou perdeu uma constante
que este arquivo não conhece, ou quando não deu pra ler a Gaby (repo ausente,
fetch falhou): nunca passa verde sem ter conferido. Texto livre da Gaby
(base de conhecimento, prompt, abertura) e preço que vem do ERP não dão pra
comparar por máquina: viram AVISO (sai 0) pedindo releitura.

Limite: compara com a main remota da Gaby, que pode estar à frente do que está
no ar. Condição mergeada lá e ainda não deployada: não publicar no site antes.
"""
import datetime
import hashlib
import json
import os
import re
import subprocess
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
CONDICOES = os.path.join(AQUI, "condicoes.json")
PRICING = "src/tenants/maf/pricing.ts"
REPO_GABY = "maf-private-label"
VALIDADE_ERP_DIAS = 45

NUMERO = re.compile(r"^export const ([A-Z][A-Z0-9_]*)(?:\s*:[^=]+)?\s*=\s*([0-9][0-9_]*);", re.M)
BLOCO = r"^(?:export )?const %s\b[^=]*=\s*\{(.*?)^\};"
ITEM = re.compile(r"^\s*([a-z_]+):\s*(?:([0-9][0-9_]*)|'([^']*)'),", re.M)


def ler_pricing(texto):
    """Constantes numéricas exportadas + os registros PRAZO_DIAS e UNIDADE_PRAZO."""
    lido = {nome: int(valor.replace("_", "")) for nome, valor in NUMERO.findall(texto)}
    for registro in ("PRAZO_DIAS", "UNIDADE_PRAZO"):
        bloco = re.search(BLOCO % registro, texto, re.M | re.S)
        if bloco:
            lido[registro] = {
                chave: int(numero.replace("_", "")) if numero else texto_
                for chave, numero, texto_ in ITEM.findall(bloco.group(1))
            }
    return lido


def _achatar(valores):
    plano = {}
    for nome, valor in valores.items():
        if isinstance(valor, dict):
            plano.update({f"{nome}.{chave}": v for chave, v in valor.items()})
        else:
            plano[nome] = valor
    return plano


def comparar(texto_pricing, condicoes):
    """Lista de divergências entre o pricing.ts da Gaby e o condicoes.json."""
    gaby = _achatar(ler_pricing(texto_pricing))
    site = _achatar({k: v for k, v in condicoes["gaby"].items() if not k.startswith("_")})
    ignoradas = condicoes.get("ignoradas", {})
    falhas = []
    for nome in sorted(set(gaby) | set(site)):
        if nome in ignoradas:
            continue
        if nome not in site:
            falhas.append(f"{nome} = {gaby[nome]!r} existe na Gaby e não está no condicoes.json "
                          "(condição nova: pôr em 'gaby' e no site, ou em 'ignoradas' com o motivo)")
        elif nome not in gaby:
            falhas.append(f"{nome} está no condicoes.json e sumiu da Gaby (renomeada ou extinta)")
        elif gaby[nome] != site[nome]:
            falhas.append(f"{nome}: a Gaby pratica {gaby[nome]!r}, o site diz {site[nome]!r}")
    return falhas


def avisos_de_idade(condicoes, hoje=None):
    """Preço que vem do ERP não tem constante: avisa quando a conferência envelhece."""
    hoje = datetime.date.fromisoformat(hoje) if hoje else datetime.date.today()
    data = condicoes.get("erp", {}).get("conferido_em")
    if not data:
        return ["preços do ERP sem data de conferência no condicoes.json"]
    idade = (hoje - datetime.date.fromisoformat(data)).days
    if idade > VALIDADE_ERP_DIAS:
        return [f"preços do ERP conferidos há {idade} dias ({data}): conferir a tabela e atualizar 'conferido_em'"]
    return []


def _git(repo, *args):
    r = subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True, timeout=60)
    if r.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)}: {r.stderr.strip() or r.stdout.strip()}")
    return r.stdout


def achar_gaby():
    """Clone local da Gaby: $GABY_REPO, ou a pasta gaby/ ao lado da árvore principal do site."""
    if os.environ.get("GABY_REPO"):
        return os.environ["GABY_REPO"]
    comum = _git(AQUI, "rev-parse", "--path-format=absolute", "--git-common-dir").strip()
    return os.path.join(os.path.dirname(os.path.dirname(comum)), "gaby")


def main_remota(repo):
    """Atualiza e devolve a ref da main remota da Gaby (só grava a ref de acompanhamento)."""
    if not os.path.isdir(repo):
        raise RuntimeError(f"clone da Gaby não encontrado em {repo} (aponte com GABY_REPO=)")
    remotos = [linha.split()[0] for linha in _git(repo, "remote", "-v").splitlines() if REPO_GABY in linha]
    if not remotos:
        raise RuntimeError(f"{repo} não tem remote do {REPO_GABY}")
    _git(repo, "fetch", "--quiet", remotos[0], "main")
    return f"{remotos[0]}/main"


def hash_prosa(repo, ref, arquivos):
    h = hashlib.sha256()
    for arquivo in arquivos:
        h.update(_git(repo, "show", f"{ref}:{arquivo}").encode())
    return h.hexdigest()


def main(argv):
    with open(CONDICOES, encoding="utf-8") as f:
        condicoes = json.load(f)
    try:
        repo = achar_gaby()
        ref = main_remota(repo)
        pricing = _git(repo, "show", f"{ref}:{PRICING}")
        prosa = hash_prosa(repo, ref, condicoes["prosa"]["arquivos"])
    except (RuntimeError, subprocess.TimeoutExpired, OSError) as erro:
        print(f"PARIDADE NÃO CONFERIDA — {erro}")
        return 1

    if "--gravar-prosa" in argv:
        condicoes["prosa"]["sha256"] = prosa
        condicoes["prosa"]["conferido_em"] = datetime.date.today().isoformat()
        with open(CONDICOES, "w", encoding="utf-8") as f:
            json.dump(condicoes, f, ensure_ascii=False, indent=2)
            f.write("\n")
        print("prosa: hash regravado")

    falhas = comparar(pricing, condicoes)
    avisos = avisos_de_idade(condicoes)
    if prosa != condicoes["prosa"]["sha256"]:
        avisos.append("o texto da Gaby (base, prompt ou abertura) mudou desde "
                      f"{condicoes['prosa']['conferido_em'] or 'sempre'}: reler o diff de "
                      f"{', '.join(condicoes['prosa']['arquivos'])} e rodar com --gravar-prosa")
    for falha in falhas:
        print(f"DIVERGE — {falha}")
    for aviso in avisos:
        print(f"AVISO — {aviso}")
    if not falhas:
        print("paridade com a Gaby: ok" + (f" ({len(avisos)} aviso(s))" if avisos else ""))
    return 1 if falhas else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
