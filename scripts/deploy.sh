#!/bin/bash
# Deploy do site numa chamada, DEPOIS do OK do Lorenzo. É o único caminho:
# testa exatamente o que vai subir (a main remota, que é de onde o Easypanel
# constrói), confere os números com a Gaby, sobe e prova no ar.
#
#   scripts/deploy.sh               # sobe a main remota
#   scripts/deploy.sh --seco [ref]  # só testa (a main remota ou outra ref); nada sobe
#
# Recusa subir se um teste falhar ou se a paridade com a Gaby não puder ser
# conferida. A prova no ar é cada página servida igual, byte a byte, à da main.
set -uo pipefail

SECO=0; REF=origin/main
if [[ "${1:-}" == "--seco" ]]; then SECO=1; REF="${2:-origin/main}"; fi
URL="https://mafprivatelabel.com.br"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
# Árvore principal do site (este script pode rodar de um worktree) → credenciais do workspace
PRINCIPAL="$(dirname "$(git -C "$REPO" rev-parse --path-format=absolute --git-common-dir)")"
SHARED="${SHARED_CREDS:-$PRINCIPAL/../../.credentials/shared.env}"
get() { grep "^$1=" "$SHARED" | head -1 | cut -d= -f2- | sed -e 's/^"//' -e 's/"$//'; }

git -C "$REPO" fetch --quiet origin || { echo "não consegui buscar a main remota do site" >&2; exit 1; }
SHA=$(git -C "$REPO" rev-parse --short "$REF") || exit 1
COPIA=$(mktemp -d) && git -C "$REPO" worktree add --quiet --detach "$COPIA/site" "$REF" || exit 1
trap 'git -C "$REPO" worktree remove --force "$COPIA/site"; rmdir "$COPIA"' EXIT

echo "== testes em $REF ($SHA)"
for teste in tests/imagem.sh tests/condicoes.sh tests/paginas.sh "python3 tests/test_paridade.py" tests/paridade.py; do
  saida=$(cd "$COPIA/site" && $teste 2>&1); codigo=$?
  echo "$saida" | grep -v -E '^(\.+|-+|Ran [0-9]+ tests.*|OK)?$'
  [[ $codigo -eq 0 ]] || { echo "PAROU — $teste falhou; nada subiu" >&2; exit 1; }
done
[[ $SECO -eq 1 ]] && { echo "(--seco: nada subiu)"; exit 0; }

[[ -f "$SHARED" ]] || { echo "credenciais não encontradas ($SHARED)" >&2; exit 2; }
echo "== deploy"
codigo=$(curl -sS --max-time 60 -o /dev/null -w '%{http_code}' -X POST \
  "$(get EASYPANEL_URL)/api/trpc/services.app.deployService" \
  -H "Authorization: Bearer $(get EASYPANEL_API_KEY)" -H "Content-Type: application/json" \
  --data '{"json":{"projectName":"redis","serviceName":"maf-app","forceRebuild":true}}')
[[ "$codigo" == "200" ]] || { echo "o Easypanel respondeu $codigo ao deploy" >&2; exit 1; }

echo "== prova no ar (até 6 min)"
no_ar() { # cada página servida = a da main; internos fechados; medição respondendo
  local f rota
  for f in "$COPIA"/site/*.html "$COPIA/site/llms.txt"; do
    rota="/$(basename "$f" .html)"; [[ "$rota" == "/index" ]] && rota="/"
    curl -s --max-time 15 "$URL$rota" | cmp -s - "$f" || { echo "$rota ainda não é a da main"; return 1; }
  done
  for rota in /Dockerfile /PEDIDOS-MAF.md /nginx-default.conf /tests/condicoes.json /scripts/deploy.sh; do
    [[ "$(curl -s -o /dev/null --max-time 15 -w '%{http_code}' "$URL$rota")" == "404" ]] || { echo "$rota está aberto no domínio"; return 1; }
  done
  [[ "$(curl -s -o /dev/null --max-time 15 -w '%{http_code}' "$URL/w/deploy?p=/&o=smoke")" == "204" ]] || { echo "/w/ não respondeu 204"; return 1; }
}
for _ in $(seq 1 36); do
  motivo=$(no_ar) && { echo "no ar: $SHA"; exit 0; }
  sleep 10
done
echo "NÃO PROVADO em 6 min — $motivo" >&2
exit 1
