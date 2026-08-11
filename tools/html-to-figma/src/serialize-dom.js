/**
 * Injected into the page (Puppeteer). Serializes visible DOM → GlowTap .gt2f node tree.
 * Mirrors html.to.design approach: computed styles + flex/grid → Auto Layout hints.
 */
module.exports = function serializeDomSource() {
  return `(() => {
  const MAX_DEPTH = 18;
  const MAX_NODES = 2500;
  let nodeCount = 0;

  function parseColor(str) {
    if (!str || str === 'transparent' || str === 'rgba(0, 0, 0, 0)') return null;
    const m = str.match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)(?:,\\s*([\\d.]+))?\\)/i);
    if (!m) return null;
    const a = m[4] !== undefined ? parseFloat(m[4]) : 1;
    if (a <= 0.01) return null;
    return { r: +m[1] / 255, g: +m[2] / 255, b: +m[3] / 255, a };
  }

  function parsePx(v) {
    const n = parseFloat(v);
    return Number.isFinite(n) ? n : 0;
  }

  function parseRadius(cs) {
    const tl = parsePx(cs.borderTopLeftRadius);
    const tr = parsePx(cs.borderTopRightRadius);
    const br = parsePx(cs.borderBottomRightRadius);
    const bl = parsePx(cs.borderBottomLeftRadius);
    if (!tl && !tr && !br && !bl) return null;
    if (tl === tr && tr === br && br === bl) return { type: 'uniform', value: tl };
    return { type: 'mixed', topLeft: tl, topRight: tr, bottomRight: br, bottomLeft: bl };
  }

  function parseShadow(cs) {
    const raw = cs.boxShadow;
    if (!raw || raw === 'none') return [];
    const effects = [];
    const parts = raw.split(/,(?![^()]*\\))/);
    for (const part of parts) {
      const m = part.trim().match(/^(inset\\s+)?(-?[\\d.]+)px\\s+(-?[\\d.]+)px\\s+(-?[\\d.]+)px(?:\\s+(-?[\\d.]+)px)?\\s+(.+)$/i);
      if (!m) continue;
      const color = parseColor(m[6]) || { r: 0, g: 0, b: 0, a: 0.2 };
      effects.push({
        type: m[1] ? 'INNER_SHADOW' : 'DROP_SHADOW',
        offset: { x: parseFloat(m[2]), y: parseFloat(m[3]) },
        radius: parseFloat(m[4]),
        spread: m[5] ? parseFloat(m[5]) : 0,
        color,
      });
    }
    return effects;
  }

  function parseGradient(bgImage) {
    if (!bgImage || bgImage === 'none') return null;
    const linear = bgImage.match(/linear-gradient\\((.+)\\)/i);
    if (!linear) return null;
    // Simplified: sample endpoints as solid is handled by bgColor; flag gradient for image fallback
    return { type: 'GRADIENT_LINEAR', raw: linear[1].slice(0, 200) };
  }

  function mapAlign(v) {
    const map = {
      'flex-start': 'MIN',
      start: 'MIN',
      left: 'MIN',
      'flex-end': 'MAX',
      end: 'MAX',
      right: 'MAX',
      center: 'CENTER',
      stretch: 'STRETCH',
      baseline: 'MIN',
      'space-between': 'SPACE_BETWEEN',
      'space-around': 'SPACE_BETWEEN',
      'space-evenly': 'SPACE_BETWEEN',
      normal: 'MIN',
    };
    return map[v] || 'MIN';
  }

  function inferLayout(cs) {
    const display = cs.display;
    if (display === 'flex' || display === 'inline-flex') {
      const row = (cs.flexDirection || 'row').startsWith('row');
      return {
        mode: row ? 'HORIZONTAL' : 'VERTICAL',
        gap: parsePx(cs.rowGap || cs.gap) || parsePx(cs.columnGap || cs.gap) || 0,
        padding: {
          top: parsePx(cs.paddingTop),
          right: parsePx(cs.paddingRight),
          bottom: parsePx(cs.paddingBottom),
          left: parsePx(cs.paddingLeft),
        },
        primaryAxisAlign: mapAlign(cs.justifyContent),
        counterAxisAlign: mapAlign(cs.alignItems),
        layoutWrap: (cs.flexWrap || '') === 'wrap' ? 'WRAP' : 'NO_WRAP',
        sizing: {
          horizontal: cs.width === 'auto' || cs.width === '' ? 'HUG' : 'FIXED',
          vertical: cs.height === 'auto' || cs.height === '' ? 'HUG' : 'FIXED',
        },
      };
    }
    if (display === 'grid' || display === 'inline-grid') {
      return {
        mode: 'VERTICAL',
        gap: parsePx(cs.rowGap || cs.gap) || 0,
        padding: {
          top: parsePx(cs.paddingTop),
          right: parsePx(cs.paddingRight),
          bottom: parsePx(cs.paddingBottom),
          left: parsePx(cs.paddingLeft),
        },
        primaryAxisAlign: 'MIN',
        counterAxisAlign: 'MIN',
        layoutWrap: 'NO_WRAP',
        gridHint: true,
      };
    }
    return null;
  }

  function isSkippable(el, cs) {
    if (!el || el.nodeType !== 1) return true;
    const tag = el.tagName.toLowerCase();
    if (['script', 'style', 'link', 'meta', 'noscript', 'svg', 'symbol', 'defs', 'path', 'use', 'title'].includes(tag)) return true;
    if (el.id === 'i-layout-dashboard' || (el.getAttribute && el.getAttribute('aria-hidden') === 'true' && tag === 'svg')) return true;
    if (cs.display === 'none' || cs.visibility === 'hidden' || parseFloat(cs.opacity) === 0) return true;
    return false;
  }

  function textContentDirect(el) {
    let t = '';
    for (const n of el.childNodes) {
      if (n.nodeType === 3) t += n.textContent;
    }
    return t.replace(/\\s+/g, ' ').trim();
  }

  function onlyTextChildren(el) {
    if (!el.childNodes.length) return false;
    for (const n of el.childNodes) {
      if (n.nodeType === 1) return false;
    }
    return true;
  }

  function getName(el) {
    return (
      el.getAttribute('data-figma-layer') ||
      el.getAttribute('data-figma-frame') ||
      el.getAttribute('aria-label') ||
      (el.id ? '#' + el.id : null) ||
      (el.className && typeof el.className === 'string' ? el.className.split(/\\s+/).filter(Boolean).slice(0, 2).join('.') : null) ||
      el.tagName.toLowerCase()
    );
  }

  function captureImageData(el) {
    try {
      if (el.tagName.toLowerCase() === 'img' && el.currentSrc) {
        return { kind: 'img', src: el.currentSrc };
      }
      const bg = getComputedStyle(el).backgroundImage;
      const m = bg && bg.match(/url\\(["']?(.*?)["']?\\)/);
      if (m && m[1] && !m[1].startsWith('data:')) return { kind: 'bg', src: m[1] };
    } catch (e) {}
    return null;
  }

  function serializeEl(el, parentRect, depth) {
    if (nodeCount >= MAX_NODES || depth > MAX_DEPTH) return null;
    const cs = getComputedStyle(el);
    if (isSkippable(el, cs)) return null;

    const rect = el.getBoundingClientRect();
    if (rect.width < 0.5 || rect.height < 0.5) return null;

    nodeCount++;
    const tag = el.tagName.toLowerCase();
    const x = rect.left - (parentRect ? parentRect.left : 0);
    const y = rect.top - (parentRect ? parentRect.top : 0);

    const fill = parseColor(cs.backgroundColor);
    const color = parseColor(cs.color);
    const borderColor = parseColor(cs.borderTopColor);
    const borderW = parsePx(cs.borderTopWidth);
    const layout = inferLayout(cs);
    const overflowAttr = el.getAttribute('data-figma-overflow');
    const overflow =
      overflowAttr ||
      (cs.overflowY === 'auto' || cs.overflowY === 'scroll' ? 'vertical' : null) ||
      (cs.overflowX === 'auto' || cs.overflowX === 'scroll' ? 'horizontal' : null);

    const directText = textContentDirect(el);
    const textOnly = onlyTextChildren(el) && directText.length > 0;

    let href = null;
    if (tag === 'a' && el.getAttribute('href')) href = el.getAttribute('href');

    const node = {
      name: String(getName(el)).slice(0, 80),
      tag,
      role: el.getAttribute('role') || null,
      id: el.id || null,
      classes: typeof el.className === 'string' ? el.className.split(/\\s+/).filter(Boolean).slice(0, 8) : [],
      x: Math.round(x * 100) / 100,
      y: Math.round(y * 100) / 100,
      width: Math.round(rect.width * 100) / 100,
      height: Math.round(rect.height * 100) / 100,
      layout,
      overflow,
      href,
      isModal: !!(el.classList && el.classList.contains('modal')),
      styles: {
        fill,
        color,
        opacity: parseFloat(cs.opacity) || 1,
        radius: parseRadius(cs),
        stroke: borderW > 0.4 && borderColor ? { color: borderColor, weight: borderW } : null,
        effects: parseShadow(cs),
        fontFamily: (cs.fontFamily || '').split(',')[0].replace(/["']/g, '').trim(),
        fontSize: parsePx(cs.fontSize) || 14,
        fontWeight: parseInt(cs.fontWeight, 10) || 400,
        lineHeight: parsePx(cs.lineHeight) || null,
        letterSpacing: parsePx(cs.letterSpacing) || 0,
        textAlign: cs.textAlign || 'left',
        textTransform: cs.textTransform || 'none',
        gradient: parseGradient(cs.backgroundImage),
      },
      text: null,
      image: null,
      children: [],
    };

    if (textOnly) {
      node.type = 'TEXT';
      node.text = directText;
      return node;
    }

    // Leaf inputs / buttons with value text
    if (['input', 'textarea', 'button', 'select'].includes(tag) && !el.children.length) {
      node.type = 'FRAME';
      const label = el.value || el.placeholder || el.textContent || '';
      if (label && String(label).trim()) {
        node.children.push({
          type: 'TEXT',
          name: 'value',
          x: 8,
          y: 8,
          width: Math.max(20, node.width - 16),
          height: Math.max(16, node.height - 16),
          text: String(label).trim().slice(0, 200),
          styles: { ...node.styles, fill: null },
          children: [],
        });
      }
      return node;
    }

    const img = captureImageData(el);
    if (img) node.image = img;

    node.type = 'FRAME';

    // Prefer element children; avoid double-counting text wrappers
    const kids = Array.from(el.children);
    if (!kids.length && directText) {
      node.children.push({
        type: 'TEXT',
        name: 'text',
        x: parsePx(cs.paddingLeft),
        y: parsePx(cs.paddingTop),
        width: Math.max(10, node.width - parsePx(cs.paddingLeft) - parsePx(cs.paddingRight)),
        height: Math.max(12, node.height - parsePx(cs.paddingTop) - parsePx(cs.paddingBottom)),
        text: directText,
        styles: { ...node.styles, fill: null, effects: [] },
        children: [],
      });
      return node;
    }

    for (const child of kids) {
      const c = serializeEl(child, rect, depth + 1);
      if (c) node.children.push(c);
    }

    // Flatten empty decorative wrappers with single child
    if (node.children.length === 1 && !node.styles.fill && !node.styles.stroke && !node.styles.effects.length && !node.image && !layout) {
      const only = node.children[0];
      only.x += node.x;
      only.y += node.y;
      only.name = node.name !== only.tag ? node.name : only.name;
      return only;
    }

    return node;
  }

  const root =
    document.querySelector('.app-screen') ||
    document.querySelector('main') ||
    document.body;

  const rootRect = root.getBoundingClientRect();
  const tree = serializeEl(root, null, 0);

  // Modals (hidden) — capture separately for overlay frames
  const modals = [];
  document.querySelectorAll('.modal').forEach((modal) => {
    const id = modal.id;
    if (!id) return;
    // Temporarily show for measure
    const prev = modal.getAttribute('style') || '';
    modal.style.setProperty('display', 'flex', 'important');
    modal.style.setProperty('position', 'fixed', 'important');
    modal.style.setProperty('inset', '0', 'important');
    modal.style.setProperty('opacity', '1', 'important');
    modal.style.setProperty('visibility', 'visible', 'important');
    const box = modal.querySelector('.modal-box') || modal;
    const serialized = serializeEl(box, null, 0);
    modal.setAttribute('style', prev);
    if (serialized) {
      modals.push({
        id,
        name: (modal.getAttribute('data-figma-frame') || id),
        node: serialized,
      });
    }
  });

  // Prototype candidates
  const links = [];
  document.querySelectorAll('a[href]').forEach((a) => {
    const href = a.getAttribute('href');
    if (!href || href.startsWith('javascript:')) return;
    const r = a.getBoundingClientRect();
    if (r.width < 2 || r.height < 2) return;
    links.push({
      href,
      text: (a.textContent || '').trim().slice(0, 80),
      x: r.left,
      y: r.top,
      w: r.width,
      h: r.height,
    });
  });

  return {
    version: 1,
    format: 'gt2f',
    viewport: { width: window.innerWidth, height: window.innerHeight },
    title: document.title,
    frameName:
      (root.getAttribute && root.getAttribute('data-figma-frame')) ||
      document.title ||
      'Screen',
    nodeCount,
    tree,
    modals,
    links,
    capturedAt: new Date().toISOString(),
  };
})()`;
};
