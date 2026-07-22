/* =========================================================
   MAF PRIVATE LABEL — script.js
   Vanilla, no dependencies. Progressive enhancement.
========================================================= */

// =====================================================================
//  ⚠️  TODO MAF — substituir pelo número dedicado da Gaby quando fornecido.
//  Por ora, aponta para o número comercial atual (Fe): +55 71 99159-6177.
//  Quando o número da Gaby chegar, mudar SÓ esta constante.
//  Todos os CTAs WhatsApp do site leem este valor em runtime.
// =====================================================================
const GABY_WPP = '5571991596177';

const GABY_MSG = {
  default:  'Olá! Vi o site da MAF e quero falar sobre private label.',
  catalogo: 'Quero receber o catálogo completo da MAF.',
  briefing: 'Quero iniciar o briefing da minha coleção.',
  plc:      'Tenho interesse em Private Label Catálogo.',
  pld:      'Quero desenvolver uma coleção exclusiva.',
  wl:       'Tenho interesse em White Label.',
};

function gabyLink(msgKey) {
  const key = msgKey && GABY_MSG[msgKey] ? msgKey : 'default';
  return `https://wa.me/${GABY_WPP}?text=${encodeURIComponent(GABY_MSG[key])}`;
}

/* ---- Hydrate every WhatsApp CTA (refines prefilled message) ---- */
function hydrateGabyLinks() {
  document.querySelectorAll('[data-gaby]').forEach((el) => {
    const key = el.getAttribute('data-gaby') || 'default';
    el.setAttribute('href', gabyLink(key));
    el.setAttribute('target', '_blank');
    el.setAttribute('rel', 'noopener');
  });
}

/* ---- Smoke check: catch any wa.me anchor that lost its data-gaby
       attribute (would otherwise silently drift from GABY_WPP if the
       const is rotated). Warns only — never blocks rendering. ---- */
function checkOrphanWppLinks() {
  const EXPECTED = `https://wa.me/${GABY_WPP}`;
  document.querySelectorAll('a[href^="https://wa.me/"]').forEach((a) => {
    if (!a.dataset.gaby) {
      console.warn('[MAF] wa.me link sem data-gaby:', a);
    } else if (a.getAttribute('href') !== EXPECTED && !a.getAttribute('href').startsWith(EXPECTED)) {
      console.warn('[MAF] wa.me link com número divergente do GABY_WPP:', a);
    }
  });
}

/* ---- Reduced-motion + touch detection ---- */
const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
const isCoarse = window.matchMedia('(pointer: coarse)').matches;

/* ---- Scroll reveal ---- */
function initReveal() {
  const targets = document.querySelectorAll('.reveal');
  if (prefersReduced || !('IntersectionObserver' in window)) {
    targets.forEach((el) => el.classList.add('is-visible'));
    return;
  }
  const io = new IntersectionObserver((entries, obs) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('is-visible');
        obs.unobserve(entry.target);
      }
    });
  }, { threshold: 0.15, rootMargin: '0px 0px -10% 0px' });
  targets.forEach((el) => io.observe(el));
}

/* ---- FAQ accordion a11y ----
   Native <details>/<summary> handles toggle and keyboard.
   We sync aria-expanded for AT consistency and close siblings for a tidy UX. */
function initAccordion() {
  const items = document.querySelectorAll('.acc-item');
  items.forEach((item) => {
    const summary = item.querySelector('.acc-summary');
    if (!summary) return;
    summary.setAttribute('role', 'button');
    summary.setAttribute('aria-expanded', item.hasAttribute('open') ? 'true' : 'false');

    item.addEventListener('toggle', () => {
      summary.setAttribute('aria-expanded', item.hasAttribute('open') ? 'true' : 'false');
    });

    summary.addEventListener('click', (e) => {
      // Close siblings (one-open accordion)
      items.forEach((other) => {
        if (other !== item && other.hasAttribute('open')) {
          other.removeAttribute('open');
          const s = other.querySelector('.acc-summary');
          if (s) s.setAttribute('aria-expanded', 'false');
        }
      });
    });
  });
}

/* ---- Sticky WhatsApp: pulse only when hero in viewport;
       mobile bottom bar appears after hero leaves. ---- */
function initStickyWpp() {
  const fab = document.querySelector('.wpp-fab');
  const sentinel = document.getElementById('hero-sentinel');
  if (!fab) return;

  if (sentinel && 'IntersectionObserver' in window) {
    const sentinelIo = new IntersectionObserver((entries) => {
      const heroVisible = entries[0].isIntersecting;
      // Pulse ring cycles only when hero is in view
      fab.classList.toggle('is-pulsing', heroVisible && !prefersReduced);
      // Mobile bar visibility: hide while hero is on screen
      if (window.matchMedia('(max-width: 767px)').matches) {
        fab.classList.toggle('is-visible', !heroVisible);
      } else {
        fab.classList.add('is-visible');
      }
    }, { threshold: 0 });
    sentinelIo.observe(sentinel);
  } else {
    fab.classList.add('is-visible');
  }
}

/* ---- Hero parallax fallback (rAF-throttled) when CSS scroll-timeline unsupported,
       only desktop + motion-ok. ---- */
function initParallax() {
  if (prefersReduced) return;
  if (window.matchMedia('(max-width: 767px)').matches) return;
  // Skip if native scroll-timeline is supported — CSS handles it.
  if (window.CSS && CSS.supports('animation-timeline: scroll()')) return;

  const heroImg = document.querySelector('.hero-img');
  const hero = document.querySelector('.hero');
  if (!heroImg || !hero) return;

  let ticking = false;
  const onScroll = () => {
    if (ticking) return;
    ticking = true;
    requestAnimationFrame(() => {
      const rect = hero.getBoundingClientRect();
      const progress = Math.max(0, Math.min(1, -rect.top / rect.height));
      heroImg.style.transform = `translateY(${progress * 12}%) scale(1.05)`;
      ticking = false;
    });
  };
  window.addEventListener('scroll', onScroll, { passive: true });
}

/* ---- Smooth-scroll polish for in-page anchors (respects reduced motion) ---- */
function initSmoothScroll() {
  if (prefersReduced) return;
  document.querySelectorAll('a[href^="#"]').forEach((a) => {
    a.addEventListener('click', (e) => {
      const id = a.getAttribute('href');
      if (!id || id === '#') return;
      const target = document.querySelector(id);
      if (!target) return;
      e.preventDefault();
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      history.replaceState(null, '', id);
    });
  });
}

/* ---- Boot ---- */
document.addEventListener('DOMContentLoaded', () => {
  hydrateGabyLinks();
  checkOrphanWppLinks();
  initReveal();
  initAccordion();
  initStickyWpp();
  initParallax();
  initSmoothScroll();
});
