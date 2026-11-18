#!/bin/bash
# A imagem só leva o que é público. Em 18/11/2026 o `COPY .` servia no domínio o
# PEDIDOS-MAF.md (pendências internas do cliente), o Dockerfile e a conf do nginx.
#   tests/imagem.sh
cd "$(dirname "$0")/.." || exit 2
falhas=0
if grep -n -E '^COPY +\. ' Dockerfile; then echo "FALHA — Dockerfile copia a pasta inteira pro site"; falhas=1; fi
for interno in PEDIDOS-MAF.md README.md Dockerfile nginx-default.conf tests scripts; do
  grep -E '^COPY ' Dockerfile | grep -v 'nginx-default.conf /etc/nginx' | grep -q -w -- "$interno" &&
    { echo "FALHA — Dockerfile leva $interno pro site"; falhas=1; }
done
for f in *.html styles.css script.js robots.txt sitemap.xml; do
  [[ -f "$f" ]] || { echo "FALHA — o Dockerfile copia $f e ele não existe"; falhas=1; }
done
[[ $falhas -eq 0 ]] && echo "imagem: ok"
exit $falhas
