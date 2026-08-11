/**
 * GlowTap HTML → Figma plugin
 * Imports .gt2f-pack.json with Auto Layout frames + prototype links.
 */
figma.showUI(__html__, { width: 420, height: 560 });

const FONT_STACK = [
  { family: 'Inter', style: 'Regular' },
  { family: 'Inter', style: 'Medium' },
  { family: 'Inter', style: 'Semi Bold' },
  { family: 'Inter', style: 'Bold' },
];

async function loadFonts() {
  for (const f of FONT_STACK) {
    try {
      await figma.loadFontAsync(f);
    } catch (e) {
      /* skip */
    }
  }
}

function fontForWeight(weight) {
  const w = weight || 400;
  if (w >= 700) return { family: 'Inter', style: 'Bold' };
  if (w >= 600) return { family: 'Inter', style: 'Semi Bold' };
  if (w >= 500) return { family: 'Inter', style: 'Medium' };
  return { family: 'Inter', style: 'Regular' };
}

function paintFromColor(c) {
  if (!c) return null;
  return {
    type: 'SOLID',
    color: { r: c.r, g: c.g, b: c.b },
    opacity: c.a == null ? 1 : c.a,
  };
}

function applyRadius(node, radius) {
  if (!radius || !('cornerRadius' in node)) return;
  if (radius.type === 'uniform') {
    node.cornerRadius = radius.value || 0;
  } else if (radius.type === 'mixed') {
    node.topLeftRadius = radius.topLeft || 0;
    node.topRightRadius = radius.topRight || 0;
    node.bottomRightRadius = radius.bottomRight || 0;
    node.bottomLeftRadius = radius.bottomLeft || 0;
  }
}

function applyEffects(node, effects) {
  if (!effects || !effects.length || !('effects' in node)) return;
  node.effects = effects.map((e) => ({
    type: e.type,
    visible: true,
    color: {
      r: e.color.r,
      g: e.color.g,
      b: e.color.b,
      a: e.color.a == null ? 0.25 : e.color.a,
    },
    offset: e.offset || { x: 0, y: 4 },
    radius: e.radius || 8,
    spread: e.spread || 0,
    blendMode: 'NORMAL',
  }));
}

async function createText(node, parent) {
  const t = figma.createText();
  const font = fontForWeight(node.styles && node.styles.fontWeight);
  try {
    await figma.loadFontAsync(font);
    t.fontName = font;
  } catch (e) {
    await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
    t.fontName = { family: 'Inter', style: 'Regular' };
  }
  t.characters = String(node.text || '').slice(0, 5000) || ' ';
  t.fontSize = (node.styles && node.styles.fontSize) || 14;
  if (node.styles && node.styles.color) {
    const p = paintFromColor(node.styles.color);
    if (p) t.fills = [p];
  }
  if (node.styles && node.styles.letterSpacing) {
    t.letterSpacing = { unit: 'PIXELS', value: node.styles.letterSpacing };
  }
  const align = (node.styles && node.styles.textAlign) || 'left';
  t.textAlignHorizontal = align === 'center' ? 'CENTER' : align === 'right' ? 'RIGHT' : 'LEFT';
  t.name = node.name || 'Text';
  t.resize(Math.max(8, node.width || 40), Math.max(8, node.height || 16));
  parent.appendChild(t);
  if (parent.layoutMode && parent.layoutMode !== 'NONE') {
    try {
      t.layoutSizingHorizontal = 'FILL';
      t.layoutSizingVertical = 'HUG';
    } catch (e) {
      /* ignore */
    }
  } else {
    t.x = node.x || 0;
    t.y = node.y || 0;
  }
  return t;
}

async function createFrameFromNode(node, parent, ctx) {
  if (!node) return null;

  if (node.type === 'TEXT' || (node.text && (!node.children || !node.children.length))) {
    return createText(node, parent);
  }

  const frame = figma.createFrame();
  frame.name = (node.name || node.tag || 'Frame').slice(0, 100);
  frame.clipsContent = !!(node.overflow || (node.classes || []).includes('modal-box'));

  const w = Math.max(1, node.width || 1);
  const h = Math.max(1, node.height || 1);
  frame.resize(w, h);

  const fills = [];
  if (node.styles && node.styles.fill) {
    const p = paintFromColor(node.styles.fill);
    if (p) fills.push(p);
  }
  if (!fills.length) {
    fills.push({ type: 'SOLID', color: { r: 1, g: 1, b: 1 }, opacity: 0 });
  }
  frame.fills = fills;

  if (node.styles && node.styles.stroke) {
    const sp = paintFromColor(node.styles.stroke.color);
    if (sp) {
      frame.strokes = [sp];
      frame.strokeWeight = node.styles.stroke.weight || 1;
    }
  }

  applyRadius(frame, node.styles && node.styles.radius);
  applyEffects(frame, node.styles && node.styles.effects);

  if (node.styles && node.styles.opacity != null && node.styles.opacity < 1) {
    frame.opacity = node.styles.opacity;
  }

  // Auto Layout from flex/grid inference
  const layout = node.layout;
  if (layout && layout.mode) {
    frame.layoutMode = layout.mode;
    frame.itemSpacing = layout.gap || 0;
    frame.paddingTop = (layout.padding && layout.padding.top) || 0;
    frame.paddingRight = (layout.padding && layout.padding.right) || 0;
    frame.paddingBottom = (layout.padding && layout.padding.bottom) || 0;
    frame.paddingLeft = (layout.padding && layout.padding.left) || 0;
    frame.primaryAxisAlignItems = layout.primaryAxisAlign || 'MIN';
    frame.counterAxisAlignItems = layout.counterAxisAlign === 'STRETCH' ? 'MIN' : layout.counterAxisAlign || 'MIN';
    if (layout.layoutWrap === 'WRAP') {
      try {
        frame.layoutWrap = 'WRAP';
      } catch (e) {
        /* older API */
      }
    }
    frame.primaryAxisSizingMode = 'FIXED';
    frame.counterAxisSizingMode = 'FIXED';
  } else {
    frame.layoutMode = 'NONE';
  }

  if (node.overflow === 'vertical') {
    frame.overflowDirection = 'VERTICAL';
  } else if (node.overflow === 'horizontal') {
    frame.overflowDirection = 'HORIZONTAL';
  }

  parent.appendChild(frame);

  if (parent.layoutMode && parent.layoutMode !== 'NONE') {
    try {
      frame.layoutSizingHorizontal = 'FILL';
      frame.layoutSizingVertical = 'HUG';
    } catch (e) {
      frame.layoutSizingHorizontal = 'FIXED';
      frame.layoutSizingVertical = 'FIXED';
    }
  } else {
    frame.x = node.x || 0;
    frame.y = node.y || 0;
  }

  // Track for prototype
  if (node.href && ctx) {
    ctx.linkNodes.push({ node: frame, href: node.href, screenKey: ctx.screenKey });
  }
  if (node.id && ctx) {
    ctx.idMap[node.id] = frame;
  }

  for (const child of node.children || []) {
    await createFrameFromNode(child, frame, ctx);
  }

  return frame;
}

async function ensurePage(name) {
  let page = figma.root.children.find((p) => p.name === name);
  if (!page) {
    page = figma.createPage();
    page.name = name;
  }
  await figma.setCurrentPageAsync(page);
  return page;
}

function clearPage(page) {
  const kids = [...page.children];
  for (const k of kids) k.remove();
}

async function importPack(pack, options) {
  await loadFonts();
  const pageName = (pack.portal && pack.portal.figmaPage) || 'Imported';
  const page = await ensurePage(pageName);
  if (options.replace) clearPage(page);

  const frameMap = {}; // frameKey → FrameNode
  const modalMap = {}; // `${frameKey}#id` → FrameNode
  const allLinkNodes = [];
  const created = [];

  const screens = pack.screens || (pack.tree ? [pack] : []);
  let xCursor = 0;
  const gap = 80;

  for (const screen of screens) {
    const ctx = { linkNodes: [], idMap: {}, screenKey: screen.frameKey || screen.file };
    const root = figma.createFrame();
    root.name = screen.frameName || screen.file || 'Screen';
    const vw = (pack.viewport && pack.viewport.width) || 1440;
    const vh = (pack.viewport && pack.viewport.height) || 900;
    root.resize(vw, vh);
    root.fills = [{ type: 'SOLID', color: { r: 0.98, g: 0.97, b: 1 } }];
    root.x = xCursor;
    root.y = 0;
    root.clipsContent = true;
    page.appendChild(root);
    created.push(root.id);

    if (screen.tree) {
      // Reset tree position to fill root
      const tree = JSON.parse(JSON.stringify(screen.tree));
      tree.x = 0;
      tree.y = 0;
      tree.width = vw;
      tree.height = Math.max(vh, tree.height || vh);
      await createFrameFromNode(tree, root, ctx);
    }

    const key = screen.frameKey || `${pack.portal && pack.portal.id}/${(screen.file || '').replace(/\.html$/i, '')}`;
    frameMap[key] = root;
    frameMap[screen.file] = root;

    // Modals as overlay frames to the right of screen
    let modalY = 0;
    for (const modal of screen.modals || []) {
      const mFrame = figma.createFrame();
      mFrame.name = `Modal / ${modal.name || modal.id}`;
      mFrame.x = xCursor + vw + 40;
      mFrame.y = modalY;
      const mw = (modal.node && modal.node.width) || 480;
      const mh = (modal.node && modal.node.height) || 320;
      mFrame.resize(Math.max(320, mw), Math.max(200, mh));
      mFrame.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
      mFrame.cornerRadius = 16;
      page.appendChild(mFrame);
      created.push(mFrame.id);
      if (modal.node) {
        const mNode = JSON.parse(JSON.stringify(modal.node));
        mNode.x = 0;
        mNode.y = 0;
        await createFrameFromNode(mNode, mFrame, { linkNodes: [], idMap: {}, screenKey: key });
      }
      modalMap[`${key}#${modal.id}`] = mFrame;
      modalMap[modal.id] = mFrame;
      modalY += mh + 40;
    }

    for (const ln of ctx.linkNodes) allLinkNodes.push(ln);
    // Also use reactions from pack
    if (screen.reactions) {
      root.setPluginData && null;
      root.setSharedPluginData('glowtap', 'reactions', JSON.stringify(screen.reactions));
      root.setSharedPluginData('glowtap', 'frameKey', key);
    }

    xCursor += vw + gap + 520;
  }

  // Wire prototypes from collected hrefs + reactions
  let wired = 0;
  for (const screen of screens) {
    const key = screen.frameKey || screen.file;
    const source = frameMap[key];
    if (!source) continue;
    const reactions = screen.reactions || [];
    for (const r of reactions) {
      let dest = null;
      let navigation = 'NAVIGATE';
      if (r.type === 'NAVIGATE' && r.targetFrameKey) {
        dest = frameMap[r.targetFrameKey];
      } else if (r.type === 'OPEN_OVERLAY' && r.targetModalId) {
        dest = modalMap[`${key}#${r.targetModalId}`] || modalMap[r.targetModalId];
        navigation = 'OVERLAY';
      }
      if (!dest) continue;

      // Create invisible hotspot on source screen
      const hs = figma.createRectangle();
      hs.name = `Hotspot / ${r.label || r.type}`;
      hs.resize(Math.max(8, (r.hotspot && r.hotspot.w) || 40), Math.max(8, (r.hotspot && r.hotspot.h) || 24));
      hs.x = (r.hotspot && r.hotspot.x) || 0;
      hs.y = (r.hotspot && r.hotspot.y) || 0;
      hs.fills = [{ type: 'SOLID', color: { r: 0.48, g: 0, b: 1 }, opacity: 0.01 }];
      source.appendChild(hs);
      try {
        hs.reactions = [
          {
            action: {
              type: 'NODE',
              destinationId: dest.id,
              navigation,
              transition: null,
              overlayRelativePosition: { x: 0, y: 0 },
            },
            trigger: { type: 'ON_CLICK' },
          },
        ];
        wired++;
      } catch (e) {
        /* reaction API variant */
        try {
          hs.reactions = [
            {
              actions: [
                {
                  type: 'NODE',
                  destinationId: dest.id,
                  navigation,
                },
              ],
              trigger: { type: 'ON_CLICK' },
            },
          ];
          wired++;
        } catch (e2) {
          /* ignore */
        }
      }
    }
  }

  // Also wire nodes that carry href directly
  for (const ln of allLinkNodes) {
    const href = ln.href || '';
    let dest = null;
    let navigation = 'NAVIGATE';
    if (href.startsWith('#')) {
      dest = modalMap[`${ln.screenKey}#${href.slice(1)}`] || modalMap[href.slice(1)];
      navigation = 'OVERLAY';
    } else {
      const base = href.split('?')[0].split('#')[0].split('/').pop();
      dest = frameMap[base] || frameMap[Object.keys(frameMap).find((k) => k.endsWith('/' + base.replace(/\.html$/i, ''))) ];
    }
    if (!dest) continue;
    try {
      ln.node.reactions = [
        {
          action: { type: 'NODE', destinationId: dest.id, navigation, transition: null },
          trigger: { type: 'ON_CLICK' },
        },
      ];
      wired++;
    } catch (e) {
      /* ignore */
    }
  }

  figma.currentPage.selection = Object.values(frameMap).slice(0, 1);
  figma.viewport.scrollAndZoomIntoView(Object.values(frameMap).slice(0, 1));

  return {
    page: pageName,
    screens: screens.length,
    createdNodeIds: created,
    prototypeLinks: wired,
  };
}

figma.ui.onmessage = async (msg) => {
  try {
    if (msg.type === 'import-pack') {
      const pack = msg.pack;
      if (!pack) throw new Error('No pack payload');
      // Normalize single screen
      if (pack.format === 'gt2f' && pack.tree) {
        const wrapped = {
          version: 1,
          format: 'gt2f-pack-embedded',
          portal: { id: pack.portalId, name: pack.portalName, figmaPage: pack.portalName || 'Imported' },
          viewport: pack.viewport,
          screens: [pack],
        };
        const result = await importPack(wrapped, { replace: !!msg.replace });
        figma.ui.postMessage({ type: 'done', result });
        return;
      }
      const result = await importPack(pack, { replace: !!msg.replace });
      figma.ui.postMessage({ type: 'done', result });
      return;
    }
    if (msg.type === 'fetch-local') {
      const url = msg.url || 'http://127.0.0.1:3847/api/pack?portal=subadmin';
      figma.ui.postMessage({ type: 'fetch', url });
      return;
    }
    if (msg.type === 'close') {
      figma.closePlugin();
    }
  } catch (err) {
    figma.ui.postMessage({ type: 'error', message: String(err && err.message ? err.message : err) });
  }
};
