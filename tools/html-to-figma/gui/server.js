/**
 * Local GUI + API for Figma plugin to fetch packs.
 * http://127.0.0.1:3847  (falls back to 3848–3852 if busy)
 */
const http = require('http');
const fs = require('fs');
const path = require('path');
const { EXPORT_ROOT, PORTALS, resolvePortal } = require('../src/portals');

const PREFERRED_PORT = Number(process.env.H2F_PORT || 3847);
const GUI_DIR = __dirname;

function send(res, code, body, type = 'text/plain; charset=utf-8') {
  res.writeHead(code, {
    'Content-Type': type,
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
  });
  res.end(body);
}

function readPack(portalId) {
  const dir = path.join(EXPORT_ROOT, portalId);
  const packFile = path.join(dir, portalId + '.gt2f-pack.json');
  if (fs.existsSync(packFile)) {
    return fs.readFileSync(packFile, 'utf8');
  }
  const manifestPath = path.join(dir, 'manifest.json');
  if (!fs.existsSync(manifestPath)) {
    throw new Error('No capture found for ' + portalId + '. Run: npm run capture -- --portal ' + portalId);
  }
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  const screens = [];
  for (const s of manifest.screens || []) {
    if (!s.json) continue;
    const p = path.join(dir, s.json);
    if (fs.existsSync(p)) screens.push(JSON.parse(fs.readFileSync(p, 'utf8')));
  }
  return JSON.stringify({
    version: 1,
    format: 'gt2f-pack-embedded',
    portal: manifest.portal,
    viewport: manifest.viewport,
    screens,
  });
}

function createServer() {
  return http.createServer((req, res) => {
    if (req.method === 'OPTIONS') {
      send(res, 204, '');
      return;
    }

    const u = new URL(req.url, 'http://127.0.0.1');

    if (u.pathname === '/api/pack') {
      try {
        const portal = resolvePortal(u.searchParams.get('portal') || 'subadmin');
        if (!portal) {
          send(res, 400, JSON.stringify({ error: 'bad portal' }), 'application/json');
          return;
        }
        const json = readPack(portal.id);
        send(res, 200, json, 'application/json; charset=utf-8');
      } catch (e) {
        send(res, 404, JSON.stringify({ error: e.message }), 'application/json');
      }
      return;
    }

    if (u.pathname === '/api/status') {
      const status = {};
      for (const p of Object.values(PORTALS)) {
        const pack = path.join(EXPORT_ROOT, p.id, p.id + '.gt2f-pack.json');
        const man = path.join(EXPORT_ROOT, p.id, 'manifest.json');
        status[p.id] = {
          name: p.name,
          hasPack: fs.existsSync(pack),
          hasManifest: fs.existsSync(man),
        };
      }
      send(res, 200, JSON.stringify({ exportRoot: EXPORT_ROOT, portals: status }, null, 2), 'application/json');
      return;
    }

    let file = u.pathname === '/' ? '/index.html' : u.pathname;
    const fp = path.join(GUI_DIR, path.normalize(file).replace(/^(\.\.[/\\])+/, ''));
    if (!fp.startsWith(GUI_DIR) || !fs.existsSync(fp)) {
      send(res, 404, 'Not found');
      return;
    }
    const ext = path.extname(fp);
    const type =
      ext === '.html' ? 'text/html; charset=utf-8' : ext === '.js' ? 'text/javascript' : 'text/plain';
    send(res, 200, fs.readFileSync(fp), type);
  });
}

function listen(port) {
  return new Promise((resolve, reject) => {
    const server = createServer();
    server.once('error', reject);
    server.listen(port, 'localhost', () => resolve({ server, port }));
  });
}

async function probeExisting(port) {
  try {
    const res = await fetch(`http://localhost:${port}/api/status`);
    if (!res.ok) return false;
    const data = await res.json();
    return !!(data && data.exportRoot);
  } catch (e) {
    return false;
  }
}

(async () => {
  // If preferred port already serves our API, reuse it
  if (await probeExisting(PREFERRED_PORT)) {
    console.log(`GlowTap HTML→Figma GUI already running on http://localhost:${PREFERRED_PORT}`);
    console.log('Open that URL in your browser. No need to start again.');
    console.log(`API: http://localhost:${PREFERRED_PORT}/api/pack?portal=subadmin`);
    console.log(`Export folder: ${EXPORT_ROOT}`);
    return;
  }

  const candidates = [PREFERRED_PORT, 3848, 3849, 3850, 3851, 3852];
  let started = null;
  for (const port of candidates) {
    try {
      started = await listen(port);
      break;
    } catch (e) {
      if (e && e.code === 'EADDRINUSE') {
        if (await probeExisting(port)) {
          console.log(`Port ${port} already has GlowTap GUI → http://localhost:${port}`);
          return;
        }
        console.warn(`Port ${port} busy, trying next…`);
        continue;
      }
      throw e;
    }
  }

  if (!started) {
    console.error('Could not bind ports 3847–3852. Free a port or set H2F_PORT=####');
    process.exit(1);
  }

  const { port } = started;
  console.log(`GlowTap HTML→Figma GUI  http://localhost:${port}`);
  console.log(`API pack example        http://localhost:${port}/api/pack?portal=subadmin`);
  console.log(`Export folder           ${EXPORT_ROOT}`);
  console.log('Keep this running while importing from the Figma plugin.');
  if (port !== PREFERRED_PORT) {
    console.log(`NOTE: Plugin default is localhost:3847. For this port, use file-drop import.`);
  }
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
