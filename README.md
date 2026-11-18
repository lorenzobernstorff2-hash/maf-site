# MAF Private Label — Site (estático)

Site institucional + páginas de modalidade da **MAF Private Label** (marca da **GLOBAL TEXTIL IND. DE CONFEÇÃO LTDA**, CNPJ 66.401.083/0001-39). Vanilla HTML + CSS + JS, **zero build step**, servido por nginx (container) no Easypanel.

## Estrutura

```
site/
├── index.html            # Home: hero split, lookbook, modalidades, comparativo, prova social, FAQ
├── white-label.html      # Página de modalidade (URL limpa /white-label via nginx try_files)
├── private-label.html    # Página de modalidade (/private-label)
├── desenvolvimento.html  # Página de modalidade (/desenvolvimento)
├── privacidade.html      # Política de privacidade (LGPD)
├── contato.html / sobre.html   # Páginas institucionais (/contato, /sobre)
├── guias.html            # Índice dos guias de conteúdo (/guias)
├── como-criar-marca-de-roupa-fitness.html, white-label-ou-private-label.html,
│   fornecedor-moda-fitness-marca-propria.html, private-label-beachwear.html   # Guias (busca orgânica)
├── llms.txt              # Resumo do site pra assistentes de IA (73% das visitas vêm do ChatGPT)
├── tests/                # condicoes.json (fonte única dos números), condicoes.sh, paridade.py (× Gaby), paginas.sh, imagem.sh
├── scripts/deploy.sh     # único caminho de deploy
├── styles.css            # Tokens, tipo, layout, motion, a11y, consent bar, page-hero
├── script.js             # GABY_WPP, gabyLink(), reveal, accordion, sticky, medição (GA4+Pixel)
├── nginx-default.conf    # URLs limpas, redirect www→apex, gzip, cache headers
├── Dockerfile            # nginx:alpine + conf + arquivos
├── robots.txt / sitemap.xml
├── assets/               # JPGs originais + variantes WebP (.wNNN.webp) + favicon + og-cover
├── materiais/            # PDFs de catálogo e de etiqueta DTF (enviados pela Gaby via link direto)
├── PEDIDOS-MAF.md        # Insumos pendentes do cliente (fotos, depoimentos, catálogos)
└── README.md             # Este arquivo
```

## Preview local

```bash
cd "/Users/lorenzobernstorff/TESTE CLAUDE/maf/site"
python3 -m http.server 8080
# abre http://localhost:8080
```

Nota: URLs limpas (`/white-label`) só funcionam via nginx (Docker); no `http.server` use `/white-label.html`.

## Stack

- HTML5 semântico, CSS3 vanilla, JS vanilla (sem frameworks, sem npm).
- Google Fonts: **Fraunces** (display) e **Inter** (body), `preconnect` + `display: swap`.
- Imagens: `<picture>` com **WebP responsivo** (`.w640/.w960/.w1280` ou full-width) + fallback JPG; `width`/`height` declarados (CLS). Lookbook em **proporção natural 11:15** — não forçar ratios que decapitem as fotos verticais.
- SEO: canonical, OG/Twitter com `og:image` **absoluta** (`assets/og-cover.jpg` 1200×630), JSON-LD (Organization + FAQPage), robots.txt, sitemap.xml.
- Acessibilidade: skip-link, focus-visible, `aria-expanded` no accordion, alt-text PT-BR, `prefers-reduced-motion`.

## Número do WhatsApp (GABY_WPP)

**Desde o go-live de 17/11/2026 o site aponta para a Gaby (automação), +55 71 98301-7311.** Até lá apontava para o comercial humano (Fe), +55 71 99159-6177 (decisão de 2026-09-10). Para trocar: editar `GABY_WPP` no topo de `script.js` **e** os `href` estáticos de fallback (`https://wa.me/…`) em todos os HTMLs.

Mensagens pré-preenchidas (`GABY_MSG` em `script.js`), via `data-gaby="<chave>"`:

| `data-gaby` | gatilho |
|---|---|
| `default`  | CTAs genéricos (nav, hero, footer) |
| `catalogo` | "Solicitar catálogo" |
| `briefing` | "Iniciar meu briefing" (processo) |
| `wl`       | CTAs da página/modalidade White Label |
| `plc`      | CTAs da página/modalidade Private Label Catálogo |
| `pld`      | CTAs da página/modalidade Desenvolvimento |

O evento de medição `whatsapp_click` usa a mesma chave como `section` — dá pra saber de qual página/seção veio o clique.

## Medição (GA4 + Meta Pixel)

No topo de `script.js`: `GA4_ID` e `META_PIXEL_ID` (vazios hoje). **Sem IDs, nada carrega e a barra de consentimento não aparece.** Com IDs: barra LGPD pergunta antes de carregar qualquer script (aceitar/recusar persiste em `localStorage`, chave `maf_consent_v1`). Eventos: `whatsapp_click` (com seção), `scroll_75`, `PageView`.

Para ativar: criar Pixel no Gerenciador de Eventos da BM (1540666449372240) + propriedade GA4, preencher as duas consts e deployar.

## Dados comerciais exibidos

Quem manda nas condições é a Gaby (repo `maf-private-label`). O site só repete.

- `tests/condicoes.json` é a fonte única dos números que o site mostra, cada um com a origem (constante do `pricing.ts` da Gaby ou tabela do ERP). Fica em `tests/` porque carrega o desconto do PIX, que o site não mostra.
- Mudou uma condição: mudar no JSON e rodar `tests/condicoes.sh`. Ele aponta as páginas que ficaram com o número velho.
- `tests/paridade.py` compara o JSON com a main remota da Gaby. Falha em número divergente, em constante nova ou extinta e quando não consegue ler a Gaby. Texto livre dela (base, prompt, abertura) e preço do ERP não dão pra comparar por máquina: viram aviso. Depois de reler o texto, `tests/paridade.py --gravar-prosa`; depois de conferir a tabela do ERP, atualizar `erp.conferido_em`.
- A mesma paridade roda no fim do deploy da Gaby (`gaby/scripts/deploy.sh`), como aviso.

## Medição própria do clique de WhatsApp

Sem cookie e sem login. A cada clique num botão de WhatsApp o `script.js` avisa `/w/<chave>?p=<página>&o=<origem>`; o nginx responde 204 e a linha fica no log de acesso. A origem é o `utm_source` ou o site de onde a visita veio (`direto` quando não há), guardada só na aba.

Ler os cliques (por botão, página e origem):

```bash
for c in $(ssh orion-vps 'docker ps -a --filter name=redis_maf-app -q'); do ssh orion-vps "docker logs $c 2>&1"; done \
  | grep -o 'GET /w/[^ ]*' | sort | uniq -c | sort -rn
```

Limite: o log vive nos containers. Os parados guardam o histórico, mas o Docker só mantém os últimos; sem volume próprio, o que for mais antigo que alguns deploys se perde.

## Deploy no Easypanel

Serviço `redis/maf-app`, build a partir da `main` deste repo. **Sempre com confirmação do Lorenzo**, e por um caminho só:

```bash
scripts/deploy.sh          # testa a main remota, confere com a Gaby, sobe e prova no ar
scripts/deploy.sh --seco   # só testa; nada sobe
```

Ele recusa subir se um teste falhar ou se a paridade não puder ser conferida. A prova é cada página servida igual à da main, os arquivos internos respondendo 404 e o `/w/` respondendo 204. O `Dockerfile` copia só o que é público, por lista: arquivo novo que deva ir ao ar entra nela (e em `tests/imagem.sh`). HTTPS via proxy do Easypanel; o nginx do container só trata roteamento e redirects.

## Regras inegociáveis

- **Bloco legal do footer é canônico** — não alterar razão social/CNPJ/endereço/emails sem confirmar com o cliente (revisor da Meta BM visita e confere).
- **Não inventar prova social** — depoimentos só com autorização escrita; slots marcados no HTML aguardam insumo (ver `PEDIDOS-MAF.md`).
- **Sufixo `cd3d79`** dos PDFs em `materiais/`: trocar catálogo sem atualizar o mapa da tool `enviar_material` = link morto silencioso.
