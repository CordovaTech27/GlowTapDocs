const fs = require('fs');
const path = require('path');
const http = require('http');
const { PORTALS, listHtmlFiles, EXPORT_ROOT } = require('./portals');
const serializeDomSource = require('./serialize-dom');

function contentType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  return (
    {
      '.html': 'text/html; charset=utf-8',
      '.js': 'text/javascript; charset=utf-8',
      '.css': 'text/css; charset=utf-8',
      '.svg': 'image/svg+xml',
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.webp': 'image/webp',
      '.woff': 'font/woff',
      '.woff2': 'font/woff2',
    }[ext] || 'application/octet-stream'
  );
}

function startStaticServer() {
  const routes = Object.values(PORTALS).map((p) => ({
    prefix: p.urlPrefix,
    root: p.dir,
  }));

  const server = http.createServer((req, res) => {
    try {
      const u = new URL(req.url, 'http://127.0.0.1');
      let pathname = decodeURIComponent(u.pathname);
      let filePath = null;

      for (const r of routes) {
        if (pathname === r.prefix || pathname === r.prefix + '/') {
          filePath = path.join(r.root, 'dashboard.html');
          break;
        }
        if (pathname.startsWith(r.prefix + '/')) {
          const rel = pathname.slice(r.prefix.length + 1);
          filePath = path.join(r.root, rel);
          break;
        }
      }

      if (!filePath || !fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }

      const data = fs.readFileSync(filePath);
      res.writeHead(200, { 'Content-Type': contentType(filePath) });
      res.end(data);
    } catch (e) {
      res.writeHead(500);
      res.end(String(e));
    }
  });

  return new Promise((resolve) => {
    server.listen(0, '127.0.0.1', () => {
      const { port } = server.address();
      resolve({ server, port, base: `http://127.0.0.1:${port}` });
    });
  });
}

async function inlineImages(page, pack) {
  async function walk(node) {
    if (!node) return;
    if (node.image && node.image.src && !node.image.src.startsWith('data:')) {
      try {
        const dataUrl = await page.evaluate(async (src) => {
          try {
            const res = await fetch(src);
            const blob = await res.blob();
            return await new Promise((resolve) => {
              const reader = new FileReader();
              reader.onload = () => resolve(reader.result);
              reader.onerror = () => resolve(null);
              reader.readAsDataURL(blob);
            });
          } catch (e) {
            return null;
          }
        }, node.image.src);
        if (dataUrl) node.image.dataUrl = dataUrl;
      } catch (e) {
        /* ignore */
      }
    }
    for (const c of node.children || []) await walk(c);
  }
  if (pack.tree) await walk(pack.tree);
  for (const m of pack.modals || []) await walk(m.node);
}

function buildPrototypeIndex(portalId, files) {
  const screens = {};
  for (const f of files) {
    screens[f] = {
      frameKey: `${portalId}/${f.replace(/\.html$/i, '')}`,
      file: f,
    };
  }
  return screens;
}

function attachPrototypeTargets(pack, portalId, screens) {
  const reactions = [];
  for (const link of pack.links || []) {
    let href = link.href || '';
    if (href.startsWith('#')) {
      reactions.push({
        type: 'OPEN_OVERLAY',
        trigger: 'ON_CLICK',
        targetModalId: href.slice(1),
        hotspot: { x: link.x, y: link.y, w: link.w, h: link.h },
        label: link.text,
      });
      continue;
    }
    const clean = href.split('?')[0].split('#')[0];
    const base = path.basename(clean);
    if (screens[base]) {
      reactions.push({
        type: 'NAVIGATE',
        trigger: 'ON_CLICK',
        targetFrameKey: screens[base].frameKey,
        hotspot: { x: link.x, y: link.y, w: link.w, h: link.h },
        label: link.text,
      });
    }
  }
  pack.reactions = reactions;
  pack.frameKey = `${portalId}/${pack.file.replace(/\.html$/i, '')}`;
  return pack;
}

function resolveChromePath() {
  if (process.env.PUPPETEER_EXECUTABLE_PATH) return process.env.PUPPETEER_EXECUTABLE_PATH;
  const candidates = [
    process.env.LOCALAPPDATA && path.join(process.env.LOCALAPPDATA, 'Google/Chrome/Application/chrome.exe'),
    process.env.PROGRAMFILES && path.join(process.env.PROGRAMFILES, 'Google/Chrome/Application/chrome.exe'),
    process.env['PROGRAMFILES(X86)'] && path.join(process.env['PROGRAMFILES(X86)'], 'Google/Chrome/Application/chrome.exe'),
    'C:/Program Files/Google/Chrome/Application/chrome.exe',
    'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
  ].filter(Boolean);
  for (const c of candidates) {
    if (fs.existsSync(c)) return c;
  }
  return null;
}

async function capturePortal(portal, options = {}) {
  const puppeteer = require('puppeteer');
  const includeAuth = !!options.includeAuth;
  let files = listHtmlFiles(portal, { includeAuth });
  if (options.file) {
    const only = options.file.endsWith('.html') ? options.file : options.file + '.html';
    files = files.includes(only) ? [only] : [only];
  }
  if (!files.length) {
    console.warn(`[skip] No HTML in ${portal.dir}`);
    return { portal: portal.id, files: 0 };
  }

  const outDir = path.join(EXPORT_ROOT, portal.id);
  fs.mkdirSync(outDir, { recursive: true });

  const { server, base } = await startStaticServer();
  const chromePath = resolveChromePath();
  const launchOpts = {
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--font-render-hinting=none'],
  };
  if (chromePath) {
    launchOpts.executablePath = chromePath;
    console.log('  Using Chrome:', chromePath);
  }
  const browser = await puppeteer.launch(launchOpts);

  const screens = buildPrototypeIndex(portal.id, files);
  const manifest = {
    version: 1,
    format: 'gt2f-pack',
    portal: { id: portal.id, name: portal.name, figmaPage: portal.figmaPage },
    viewport: { width: options.width || 1440, height: options.height || 900 },
    screens: [],
    createdAt: new Date().toISOString(),
  };

  const page = await browser.newPage();
  await page.setViewport({
    width: options.width || 1440,
    height: options.height || 900,
    deviceScaleFactor: 1,
  });

  const serializeSrc = serializeDomSource();

  for (let i = 0; i < files.length; i++) {
    const file = files[i];
    const url = `${base}${portal.urlPrefix}/${encodeURIComponent(file)}?figma=1`;
    process.stdout.write(`  [${i + 1}/${files.length}] ${file} ... `);
    try {
      await page.goto(url, { waitUntil: 'networkidle0', timeout: 60000 });
      await page.waitForTimeout?.(400).catch(() => {});
      await new Promise((r) => setTimeout(r, 400));

      const pack = await page.evaluate(serializeSrc);
      pack.portalId = portal.id;
      pack.portalName = portal.name;
      pack.file = file;
      pack.sourceUrl = url;
      attachPrototypeTargets(pack, portal.id, screens);
      await inlineImages(page, pack);

      const shotPath = path.join(outDir, file.replace(/\.html$/i, '') + '.png');
      await page.screenshot({ path: shotPath, fullPage: false });
      pack.screenshot = path.basename(shotPath);

      const jsonPath = path.join(outDir, file.replace(/\.html$/i, '') + '.gt2f.json');
      fs.writeFileSync(jsonPath, JSON.stringify(pack));
      manifest.screens.push({
        file,
        frameKey: pack.frameKey,
        frameName: pack.frameName,
        json: path.basename(jsonPath),
        screenshot: pack.screenshot,
        nodeCount: pack.nodeCount,
        modals: (pack.modals || []).map((m) => m.id),
        reactions: (pack.reactions || []).length,
      });
      console.log(`ok (${pack.nodeCount} nodes, ${(pack.modals || []).length} modals)`);
    } catch (err) {
      console.log('FAIL');
      console.error('   ', err.message);
      manifest.screens.push({ file, error: err.message });
    }
  }

  await browser.close();
  server.close();

  const manifestPath = path.join(outDir, 'manifest.json');
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));

  // One-file pack for Figma plugin drag/drop (embeds screen JSON)
  const packScreens = [];
  for (const s of manifest.screens) {
    if (s.error || !s.json) continue;
    const full = path.join(outDir, s.json);
    if (!fs.existsSync(full)) continue;
    packScreens.push(JSON.parse(fs.readFileSync(full, 'utf8')));
  }
  const packPath = path.join(outDir, portal.id + '.gt2f-pack.json');
  fs.writeFileSync(
    packPath,
    JSON.stringify(
      {
        version: 1,
        format: 'gt2f-pack-embedded',
        portal: manifest.portal,
        viewport: manifest.viewport,
        screens: packScreens,
        createdAt: new Date().toISOString(),
      },
      null,
      0
    )
  );

  return { portal: portal.id, files: files.length, outDir, manifestPath, packPath };
}

async function captureAll(options = {}) {
  fs.mkdirSync(EXPORT_ROOT, { recursive: true });
  const results = [];
  for (const portal of Object.values(PORTALS)) {
    console.log(`\n▶ Capturing ${portal.name} (${portal.dir})`);
    results.push(await capturePortal(portal, options));
  }

  const rootManifest = {
    version: 1,
    format: 'gt2f-root',
    exportRoot: EXPORT_ROOT,
    portals: results,
    createdAt: new Date().toISOString(),
    importInstructions:
      'Open Figma → Plugins → Development → GlowTap HTML to Figma → Import figma-export/<portal>/manifest.json',
  };
  fs.writeFileSync(path.join(EXPORT_ROOT, 'manifest.json'), JSON.stringify(rootManifest, null, 2));
  return rootManifest;
}

module.exports = {
  capturePortal,
  captureAll,
  startStaticServer,
  EXPORT_ROOT,
};
