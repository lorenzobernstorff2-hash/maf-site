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
├── styles.css            # Tokens, tipo, layout, motion, a11y, consent bar, page-hero
├── script.js             # GABY_WPP, gabyLink(), reveal, accordion, sticky, medição (GA4+Pixel)
├── nginx-default.conf    # URLs limpas, redirect www→apex, gzip, cache headers
├── Dockerfile            # nginx:alpine + conf + arquivos
├── robots.txt / sitemap.xml
├── assets/               # JPGs originais + variantes WebP (.wNNN.webp) + favicon + og-cover
├── materiais/            # PDFs de catálogo + imagem-resumo (enviados pela Gaby via link direto)
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

**Decisão 2026-09-10 (Lorenzo): o site aponta para o comercial humano (Fe), +55 71 99159-6177, ATÉ a automação (Gaby) estar pronta.** Quando trocar: editar `GABY_WPP` no topo de `script.js` **e** os `href` estáticos de fallback (`https://wa.me/…`) em todos os HTMLs. O número da Gaby é **+55 71 98301-7311**.

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

Fonte canônica: `maf/docs/SPEC.md` §16-§19. Mudou a SPEC → conferir home (comparativo + FAQ) e as 3 páginas de modalidade. Pontos vivos: WL 6 peças mix livre (compra teste 1-5 +20%), prazo WL "a partir de 5 dias corridos", PC 10/cor ≈R$ 600, Desenv 40/modelo a partir de R$ 20 mil (prazo não destacado — decisão Ata 01 §17.1.7), PIX 5% / 3x sem juros, frete cotado no orçamento.

## Deploy no Easypanel

Serviço `redis/maf-app` — build a partir deste repo (GitHub `lorenzobernstorff2-hash/maf-site`), deploy manual (`services.app.deployService`) **com confirmação do Lorenzo**. HTTPS via proxy Easypanel; o container nginx só trata roteamento/redirect www.

## Regras inegociáveis

- **Bloco legal do footer é canônico** — não alterar razão social/CNPJ/endereço/emails sem confirmar com o cliente (revisor da Meta BM visita e confere).
- **Não inventar prova social** — depoimentos só com autorização escrita; slots marcados no HTML aguardam insumo (ver `PEDIDOS-MAF.md`).
- **Sufixo `cd3d79`** dos PDFs em `materiais/`: trocar catálogo sem atualizar o mapa da tool `enviar_material` = link morto silencioso.
