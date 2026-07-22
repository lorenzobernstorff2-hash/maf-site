# MAF Private Label — Site (estático)

Site institucional da **MAF Private Label** (marca da **GLOBAL TEXTIL IND. DE CONFEÇÃO LTDA**, CNPJ 66.401.083/0001-39). Vanila HTML + CSS + JS, **zero build step**, deployável como estático no Easypanel (nginx static).

## Estrutura

```
site/
├── index.html         # 12 seções + footer institucional + sticky WhatsApp
├── styles.css         # Tokens, tipo, layout, motion, a11y, reduced-motion
├── script.js          # GABY_WPP, gabyLink(), reveal, accordion, sticky, parallax
├── assets/            # 12 imagens extraídas do IG MAF (JPEG)
└── README.md          # Este arquivo
```

## Preview local

```bash
cd "/Users/lorenzobernstorff/TESTE CLAUDE/maf/site"
python3 -m http.server 8080
# abre http://localhost:8080
```

Qualquer servidor estático serve (`nginx`, `caddy file-server`, etc.). Não há build.

## Stack

- HTML5 semântico, CSS3 vanilla, JS vanilla (sem frameworks, sem npm).
- Google Fonts via `<link>` com `preconnect` + `font-display: swap`: **Fraunces** (display) e **Inter** (body).
- Imagens: JPEG em `/assets`, `loading="lazy"` + `decoding="async"` abaixo da dobra; hero com `loading="eager"` + `fetchpriority="high"`. `aspect-ratio` declarado no CSS para CLS < 0.1.
- Acessibilidade: skip-link, focus-visible ring (sage `--accent-2` 2px), `aria-expanded` no accordion, alt-text PT-BR descritivo, `prefers-reduced-motion` honrado em todas as animações.
- Meta tags: Open Graph, canonical, theme-color, favicon inline SVG.

## Deploy no Easypanel (nginx static)

1. Criar service **Static Site** no Easypanel no projeto desejado.
2. Source: apontar para este diretório `site/` (ou repo git contendo só estes arquivos).
3. Build command: **nenhum**. Publish directory: raiz (`/`).
4. Easypanel serve automaticamente via nginx. HTTPS via Let's Encrypt habilitado pelo painel.

### DNS (quando o João liberar acesso ao registro.br)

Apontar ambos os records para a VPS da MAF (**31.97.163.58**):

| Tipo | Nome | Valor |
|---|---|---|
| A    | `@`         | `31.97.163.58` |
| A    | `www`       | `31.97.163.58` |
| CNAME | `mafprivatelabel.com.br.` (apex) | — (já coberto pelo A record acima) |

Configurar domínio no Easypanel (Settings → Domains) com HTTPS On. O nginx do Easypanel emite certificado Let's Encrypt automaticamente.

## Trocar o número do WhatsApp (GABY_WPP)

Quando o João fornecer o número dedicado da **Gaby** (atendente IA), editar **uma única linha** no topo de `script.js`:

```js
// ⚠️  TODO MAF — substituir pelo número dedicado da Gaby quando fornecido.
const GABY_WPP = '5571991596177';  // ← trocar só aqui
```

Formato: DDI+DDD+número, só dígitos (ex.: `5571XXXXXXXXX`). Todos os botões WhatsApp (nav, hero, cards, CTA band, sticky FAB, footer) leem esta constante em runtime via `data-gaby` e a função `gabyLink()`. Os `href` estáticos no HTML (fallback caso JS falhe) também apontam para o número atual — atualizar ambos ao rotacionar.

### Mensagens pré-preenchidas

Definidas em `GABY_MSG` (`script.js`), usadas por chave via `data-gaby="<chave>"`:

| `data-gaby` | gatilho |
|---|---|
| `default`  | CTAs genéricos (nav, hero, footer) |
| `catalogo` | "Solicitar catálogo completo" |
| `briefing` | "Iniciar meu briefing" (processo) |
| `plc`      | Card Private Label Catálogo |
| `pld`      | Card Private Label Desenvolvimento |

## Verificação Meta Business Manager

O rodapé institucional foi desenhado para passar revisão humana da Meta sem esforço. Bloco `.footer-legal` contém, em texto **não-colapsável**, peso 500/600, fundo `--ink` sobre texto `--bg` (contraste 14:1):

- Razão social (peso 600, **GLOBAL TEXTIL INDÚSTRIA DE CONFEÇÃO LTDA**)
- CNPJ (66.401.083/0001-39) e nome fantasia (MAF WHITE E PRIVATE LABEL)
- Endereço completo em uma linha (Av. Luiz Tarquínio Pontes, 2729 — Loja 06, Pitangueiras, Lauro de Freitas/BA, CEP 42701-450)
- E-mails comercial@ e financeiro@
- Instagram @mafprivatelabel e domínio

**Não há accordion, toggle, opacidade < 1 ou cinza miúdo** neste bloco. O mesmo conteúdo aparece compactado no mini-trust da seção História — redundância intencional (feature, não bug).

## Pendências conhecidas (não bloqueiam go-live)

- **Foto da fundadora Mariana:** o founder block em `#historia` é composição CSS/SVG (monograma + quote + nome). Substituir por `<img>` portrait quando a MAF fornecer. Não usar stock.
- **Masters high-res dos produtos-âncora:** flaggear como pendência com a MAF.
- **Depoimentos reais com foto + nome + marca:** slots prontos na seção "Cases". Hoje exibimos apenas o card âncora `@eusouliv` + card-CTA. Não inventar depoimentos.
- **Logos de clientes:** intencionalmente ausentes. Card textual `@eusouliv` é o único case público citado.

## Performance esperada

- LCP < 2.5s (hero JPEG otimizado, `fetchpriority="high"`).
- CLS < 0.1 (`aspect-ratio` declarado em todas as imagens).
- Page weight inicial < 1.5 MB (12 imagens, mas só hero eager; resto lazy).
- JS < 4 KB, sem dependências.
