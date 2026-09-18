# PEDIDOS-MAF — insumos pendentes do cliente (João/Mariana)

> Lista única do que falta a MAF fornecer para o site e o bot avançarem.
> Ites marcados ⚡ travam melhorias já preparadas no código (slots prontos).
> Gerado em 2026-09-10 durante a revisão de conversão do site.

## Fotografia / prova social

- ⚡ **Masters em alta resolução** das peças-âncora (as fotos atuais vêm comprimidas do
  Instagram, ~1020-1279px). Ideal: arquivos originais de câmera, 2000px+.
- ⚡ **Depoimentos reais** de clientes: nome + marca + foto (autorização por escrito).
  Slot pronto na seção "Confiança de fábrica" da home — nada é publicado sem autorização.
- ⚡ **Foto portrait da fundadora Mariana** para o bloco de História (hoje é composição tipográfica).
- **Vídeo curto de fábrica (15-30s)** — para o hero da home e/ou anúncios. Aprendido Mercedes:
  o que move resultado são os 2 primeiros segundos.
- **Lista de marcas atendidas** que autorizam citação pública (hoje só @eusouliv é caso público).

## Material comercial

- ⚡ **Catálogo White Label novo** (sem preços, leve — atual tem 16,6MB). Quando sair:
  1. substituir em `materiais/` mantendo o sufixo `cd3d79` OU atualizar o mapa em
     `gaby/src/tools/enviar-material.ts` (gotcha do link morto silencioso);
  2. habilitar a vitrine pública no site (página /catalogo) — decidimos NÃO publicar os
     PDFs atuais porque expõem a tabela de atacado completa.
- **"Tabela genérica"** (imagem "tops a partir de X, leggings a partir de Y") — SPEC §19.3,
  5º slug da tool `enviar_material` (o 4º, a imagem-resumo dos 3 caminhos, já está pronta).
- **Vídeo de boas-vindas** — SPEC §19.1, trava a abertura nova do bot (a imagem-resumo dos 3
  modos já existe: `materiais/resumo-tres-caminhos-cd3d79.png`).

## Confirmações comerciais (meio minuto do João)

- Prazo do **Private Catálogo (60 dias)** e do **Desenvolvimento**: dias úteis ou corridos?
  (White Label = 5 dias **corridos**, confirmado na Ata 01.)
- O número do rodapé dos PDFs de orçamento no ERP já foi editado para o mínimo de 6 peças? (§16.3, pendência antiga)

## Pendências já conhecidas (não são do site)

- **Cartão na Business Manager** — trava templates, followups >24h e escalações do bot.
- Vínculo dos nomes do catálogo beachwear ↔ códigos ERP (§19.2).
