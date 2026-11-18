#!/bin/bash
# Condições comerciais do site batem com tests/condicoes.json (a fonte única, que
# tests/paridade.py confere com a Gaby). Duas listas explícitas:
#   proibido = frase de condição vencida que não pode voltar
#   exigido  = página × fato, com o valor lido do JSON (mudou o JSON, o teste
#              aponta as páginas que ficaram sem o número novo)
#   so_valores = prazo, parcela e nº de cores: TODA ocorrência tem de trazer um
#              valor vigente (um parágrafo esquecido com o número velho falha)
# Limite: quantidade de peças só tem o exigido, porque "N peças" aparece em
# exemplos legítimos; um parágrafo solto com a quantidade velha não é pego.
#   tests/condicoes.sh
cd "$(dirname "$0")/.." || exit 2
J=tests/condicoes.json
command -v jq >/dev/null || { echo "precisa do jq" >&2; exit 2; }
PAGINAS=($(ls *.html | grep -v privacidade) llms.txt)
falhas=0
proibido() { # <descrição> <regex>
  local achou
  achou=$(grep -n -i -E "$2" "${PAGINAS[@]}" | grep -v -E '^[^:]+:[0-9]+:[[:space:]]*<!--')
  if [[ -n "$achou" ]]; then echo "VENCIDO — $1:"; echo "$achou" | cut -c1-160; falhas=1; fi
}
exigido() { # <descrição> <regex> <arquivo>...
  local d="$1" r="$2" f; shift 2
  for f in "$@"; do grep -q -i -E "$r" "$f" || { echo "FALTA — $d em $f"; falhas=1; }; done
}
so_valores() { # <descrição> <regex do que vem depois do número> <valor permitido>...
  local d="$1" sufixo="$2" linha numero; shift 2
  while IFS= read -r linha; do
    numero=$(sed -E 's/^[^:]+:[0-9]+:[^0-9]*([0-9]+).*/\1/' <<<"$linha")
    [[ " $* " == *" $numero "* ]] || { echo "VALOR FORA DO VIGENTE — $d: $linha"; falhas=1; }
  done < <(grep -n -o -i -E "(até )?[0-9]+ ?$sufixo" "${PAGINAS[@]}")
}
g() { jq -er ".gaby.$1" "$J"; }
unidade() { local u; u=$(g "UNIDADE_PRAZO.$1"); [[ "$u" == "dias" ]] && u="dias corridos"; echo "$u"; }
N='(^|[^0-9,.])'   # o número não pode ser o fim de outro ("5 dias" dentro de "15 dias")
reais() { printf 'R\\$ %d,%02d' $(( $1 / 100 )) $(( $1 % 100 )); }   # centavos → "R\$ 100,00" (regex)

PARCELAS=$(g MAX_PARCELAS_CARTAO); PARCELA_MIN=$(( $(g PARCELA_MINIMA_CENTAVOS) / 100 ))
WL=$(g MINIMO_WHITE_LABEL_TOTAL); ATACADO=$(g MINIMO_TABELA_ATACADO)
PLC=$(g MINIMO_PRIVATE_CATALOGO_POR_MODELO_COR); PLD=$(g MINIMO_DESENVOLVIMENTO_POR_MODELO)
PLD_COR=$(g MINIMO_DESENVOLVIMENTO_POR_COR)
DTF=$(reais "$(g DTF_CENTAVOS_POR_APLICACAO)"); ETIQUETA=$(reais "$(g ETIQUETA_CENTAVOS_POR_APLICACAO)")
IMPRESSAO=$(reais "$(g IMPRESSAO_DTF_CENTAVOS)"); VETOR=$(reais "$(g VETORIZACAO_LOGO_CENTAVOS)")
P_WL=$(g PRAZO_DIAS.white_label); P_PLC=$(g PRAZO_DIAS.private_catalogo); P_DTF=$(g PRAZO_DIAS.personalizacao_dtf)
P_PERS=$(g PRAZO_DIAS.personalizacao)
U_WL=$(unidade white_label); U_PLC=$(unidade private_catalogo); U_DTF=$(unidade personalizacao_dtf); U_PERS=$(unidade personalizacao)
CORES_DTF=$(g MAX_CORES_LOGO_DTF); CORES_PLD=$(g MAXIMO_CORES_DESENVOLVIMENTO)
VALIDADE_ORCAMENTO=30   # "orçamento vale 30 dias corridos": regra do prompt da Gaby, sem constante
INICIAL=$(jq -er .erp.private_catalogo_investimento_inicial_reais "$J")
DESENV=$(jq -er '.erp.desenvolvimento_investimento_minimo_reais | if . % 1000 == 0 then . / 1000 else error("o site escreve esse valor em mil cheio") end' "$J") || exit 2
MODALIDADES=(index.html white-label.html private-label.html desenvolvimento.html)

proibido "PIX com 5% (hoje 3%, e só se o cliente pergunta)" 'PIX com 5%|5% de desconto'
proibido "desconto do PIX no site (só se fala quando o cliente pergunta)" 'PIX[^.<]{0,60}[0-9] ?%|[0-9] ?%[^.<]{0,40}PIX'
proibido "cartão em 3x (hoje até ${PARCELAS}x)" '3x sem juros'
proibido "etiqueta costurada (não existe, é pendurada)" 'etiqueta costurada'
proibido "compra teste de 1 a 5 peças (saiu de linha em 30/10)" 'compra teste|\+20%'
proibido "percentual da composição do tecido (os catálogos somam 101%)" '85% poliamida|16% elastano'
proibido "desconto de volume em percentual (preço vem da tabela)" '7,5%|15%'
proibido "cliente envia o DTF impresso (a MAF imprime a partir da logo)" 'arte impressa|impressa em DTF'
proibido "DTF sem custo no Private Label (só a etiqueta é isenta)" 'DTF (e|\+) etiqueta[^.<]*sem custo'

exigido "cartão em até ${PARCELAS}x" "até (<strong>)?${PARCELAS}x sem juros" "${MODALIDADES[@]}" llms.txt como-criar-marca-de-roupa-fitness.html white-label-ou-private-label.html fornecedor-moda-fitness-marca-propria.html private-label-beachwear.html
exigido "parcela mínima de R\$ ${PARCELA_MIN}" "parcela mínima de R\\\$ ${PARCELA_MIN}(\\.?[^0-9.]|\\.?$)" "${MODALIDADES[@]}" llms.txt
exigido "White Label a partir de ${WL} peças" "${N}${WL} (peças|unidades)" index.html white-label.html llms.txt como-criar-marca-de-roupa-fitness.html white-label-ou-private-label.html fornecedor-moda-fitness-marca-propria.html sobre.html
exigido "tabela de atacado a partir de ${ATACADO} peças" "(a partir de|é) ${ATACADO}([^0-9]|$)" white-label.html llms.txt como-criar-marca-de-roupa-fitness.html
exigido "pedido reduzido uma vez por CPF ou CNPJ" 'uma vez por CPF ou CNPJ' index.html white-label.html llms.txt como-criar-marca-de-roupa-fitness.html
exigido "Private Catálogo com ${PLC} por modelo e cor" "${N}${PLC} (peças|unidades|un)" index.html private-label.html llms.txt como-criar-marca-de-roupa-fitness.html white-label-ou-private-label.html private-label-beachwear.html
exigido "Desenvolvimento com ${PLD} por modelo" "${N}${PLD} (peças|unidades|un)" index.html desenvolvimento.html llms.txt como-criar-marca-de-roupa-fitness.html private-label-beachwear.html
exigido "Desenvolvimento com mínimo de ${PLD_COR} por cor" "${N}${PLD_COR} (peças )?por cor" index.html desenvolvimento.html llms.txt
exigido "DTF a ${DTF} por aplicação" "${DTF}[^<]{0,12}aplicação" index.html white-label.html private-label.html llms.txt
exigido "impressão do DTF a ${IMPRESSAO} por cor" "${IMPRESSAO}[^<]*por cor" index.html white-label.html private-label.html llms.txt
exigido "vetorização a ${VETOR}" "${VETOR}" index.html white-label.html llms.txt
exigido "etiqueta pendurada a ${ETIQUETA}" "${ETIQUETA}" index.html white-label.html llms.txt
exigido "White Label a partir de ${P_WL} ${U_WL}" "${N}${P_WL} ${U_WL}" index.html white-label.html llms.txt
exigido "Private Catálogo a partir de ${P_PLC} ${U_PLC}" "${N}${P_PLC} ${U_PLC}" index.html private-label.html llms.txt como-criar-marca-de-roupa-fitness.html
exigido "DTF a partir de ${P_DTF} ${U_DTF}" "${N}${P_DTF} ${U_DTF}" white-label.html llms.txt
exigido "Private Catálogo a partir de ≈ R\$ ${INICIAL}" "R\\\$ ${INICIAL}(\\.?[^0-9.]|\\.?$)" index.html private-label.html llms.txt
exigido "Desenvolvimento a partir de R\$ ${DESENV} mil" "R\\\$ ${DESENV} mil" index.html desenvolvimento.html llms.txt
exigido "etiqueta pendurada a partir de ${P_PERS} ${U_PERS}" "${N}${P_PERS} ${U_PERS}" white-label.html llms.txt
exigido "logo do DTF em até ${CORES_DTF} cores" "até ${CORES_DTF} cores" index.html white-label.html llms.txt
exigido "Desenvolvimento em até ${CORES_PLD} cores" "até ${CORES_PLD} cores" index.html desenvolvimento.html llms.txt

so_valores "prazo em dias corridos" 'dias corridos' "$P_WL" "$VALIDADE_ORCAMENTO"
so_valores "prazo em dias úteis" 'dias úteis' "$P_PLC" "$P_DTF" "$P_PERS"
so_valores "parcelas no cartão" 'x sem juros' "$PARCELAS"
so_valores "número de cores" 'cores' "$CORES_DTF" "$CORES_PLD"
[[ $falhas -eq 0 ]] && echo "condições: ok"
exit $falhas
