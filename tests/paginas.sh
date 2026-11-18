#!/bin/bash
# Estrutura do site: toda URL do sitemap existe e tem o básico de SEO, todo link
# interno resolve, e os arquivos que robôs e navegadores pedem na raiz respondem.
#   tests/paginas.sh
cd "$(dirname "$0")/.." || exit 2
falhas=0
erro() { echo "FALHA — $1"; falhas=1; }
BASE='https://mafprivatelabel.com.br'

urls=$(grep -o '<loc>[^<]*' sitemap.xml | sed 's/<loc>//')
for u in $urls; do
  caminho="${u#$BASE}"; arq="${caminho#/}"; [[ -z "$arq" ]] && arq="index"
  f="$arq.html"
  [[ -f "$f" ]] || { erro "sitemap aponta pra $caminho e $f não existe"; continue; }
  grep -q "<link rel=\"canonical\" href=\"$u\"" "$f" || erro "$f: canonical diferente de $u"
  [[ $(grep -c '<h1' "$f") -eq 1 ]] || erro "$f: precisa de exatamente um h1"
  grep -q '<title>[^<]\{20,\}' "$f" || erro "$f: sem title"
  grep -q '<meta name="description" content="[^"]\{70,\}' "$f" || erro "$f: sem description"
done
grep -q '<lastmod>' sitemap.xml || erro "sitemap sem lastmod"

for f in *.html; do
  grep -q "<loc>$BASE/$( [[ $f == index.html ]] || echo "${f%.html}")</loc>" sitemap.xml || erro "$f fora do sitemap"
  for l in $(grep -o 'href="/[a-z0-9-]*"' "$f" | sed 's/href="\///; s/"//' | sort -u); do
    [[ -z "$l" || -f "$l.html" ]] || erro "$f: link interno /$l não existe"
  done
done

for p in contato sobre guias como-criar-marca-de-roupa-fitness white-label-ou-private-label fornecedor-moda-fitness-marca-propria private-label-beachwear; do
  [[ -f "$p.html" ]] || erro "falta a página /$p"
done
for f in white-label.html private-label.html desenvolvimento.html; do
  grep -q '"@type": "FAQPage"' "$f" || erro "$f: sem perguntas e respostas estruturadas"
done
[[ -s llms.txt ]] || erro "falta o llms.txt"
for regra in 'location = /favicon.ico' 'location = /apple-touch-icon.png' '/fale-conosco' '/politica-de-privacidade'; do
  grep -q -- "$regra" nginx-default.conf || erro "nginx sem a regra: $regra"
done
[[ $falhas -eq 0 ]] && echo "páginas: ok"
exit $falhas
