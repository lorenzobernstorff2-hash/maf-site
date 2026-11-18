#!/bin/bash
# Condições comerciais do site batem com o que a Gaby pratica (fonte: kb/modalidades.md
# do repo maf-private-label). Falha se uma condição vencida voltar a aparecer.
#   tests/condicoes.sh
cd "$(dirname "$0")/.." || exit 2
PAGINAS=($(ls *.html | grep -v privacidade) llms.txt)
falhas=0
proibido() { # <descrição> <regex>
  local achou
  achou=$(grep -n -i -E "$2" "${PAGINAS[@]}" | grep -v -E '^[^:]+:[0-9]+:[[:space:]]*<!--')
  if [[ -n "$achou" ]]; then echo "VENCIDO — $1:"; echo "$achou" | cut -c1-160; falhas=1; fi
}
exigido() { # <descrição> <arquivo> <regex>
  grep -q -i -E "$3" "$2" || { echo "FALTA — $1 em $2"; falhas=1; }
}
proibido "PIX com 5% (hoje 3%, e só se o cliente pergunta)" 'PIX com 5%|5% de desconto'
proibido "cartão em 3x (hoje até 4x, parcela mínima R\$ 200)" '3x sem juros'
proibido "etiqueta costurada (não existe, é pendurada)" 'etiqueta costurada'
proibido "compra teste de 1 a 5 peças (saiu de linha em 30/10)" 'compra teste|\+20%'
proibido "desconto de volume em percentual (preço vem da tabela)" '7,5%|15%'
proibido "cliente envia o DTF impresso (a MAF imprime a partir da logo)" 'arte impressa|impressa em DTF'
proibido "DTF sem custo no Private Label (só a etiqueta é isenta)" 'DTF (e|\+) etiqueta[^.<]*sem custo'
for p in index.html white-label.html private-label.html desenvolvimento.html; do exigido "cartão em até 4x" "$p" 'até (<strong>)?4x sem juros'; done
exigido "parcela mínima de R\$ 200" index.html 'parcela mínima de R\$ 200'
exigido "impressão do DTF R\$ 100 por cor" white-label.html 'R\$ 100,00[^<]*por cor'
exigido "vetorização R\$ 30" white-label.html 'R\$ 30,00'
exigido "pedido reduzido uma vez por CPF ou CNPJ" white-label.html 'uma vez por CPF ou CNPJ'
exigido "prazo do Private Catálogo em dias úteis" private-label.html '60 dias úteis'
exigido "prazo do Private Catálogo em dias úteis" index.html '60 dias úteis'
[[ $falhas -eq 0 ]] && echo "condições: ok"
exit $falhas
