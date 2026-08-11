/**
 * Generate HTML + PDF for industry standard benchmark report.
 *   node scripts/generate-standard-benchmark-report.js
 */
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..', '..', '..');
const reportsDir = path.join(__dirname, '..', 'reports');
const mdPath = path.join(reportsDir, 'Standard-DB-Performance-Benchmark.md');
const htmlPath = path.join(reportsDir, 'Standard-DB-Performance-Benchmark.html');
const pdfPath = path.join(reportsDir, 'Standard-DB-Performance-Benchmark.pdf');

function mdToSimpleHtml(md) {
  const escape = (s) =>
    s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

  const lines = md.split(/\r?\n/);
  const out = [];
  let inTable = false;
  let inCode = false;
  let inBq = false;

  function closeTable() {
    if (inTable) {
      out.push('</tbody></table>');
      inTable = false;
    }
  }
  function closeBq() {
    if (inBq) {
      out.push('</blockquote>');
      inBq = false;
    }
  }

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    if (line.startsWith('```')) {
      closeTable();
      closeBq();
      if (!inCode) {
        out.push('<pre><code>');
        inCode = true;
      } else {
        out.push('</code></pre>');
        inCode = false;
      }
      continue;
    }
    if (inCode) {
      out.push(escape(line));
      continue;
    }

    if (line.startsWith('|') && line.includes('|')) {
      const cells = line
        .split('|')
        .slice(1, -1)
        .map((c) => c.trim());
      if (cells.every((c) => /^:?-+:?$/.test(c))) continue;
      if (!inTable) {
        closeBq();
        out.push('<table><thead><tr>');
        cells.forEach((c) => out.push(`<th>${inline(c)}</th>`));
        out.push('</tr></thead><tbody>');
        inTable = true;
      } else {
        out.push('<tr>');
        cells.forEach((c) => out.push(`<td>${inline(c)}</td>`));
        out.push('</tr>');
      }
      continue;
    } else {
      closeTable();
    }

    if (line.startsWith('> ')) {
      if (!inBq) {
        out.push('<blockquote>');
        inBq = true;
      }
      out.push(`<p>${inline(line.slice(2))}</p>`);
      continue;
    } else {
      closeBq();
    }

    if (line.startsWith('# ')) {
      out.push(`<h1>${inline(line.slice(2))}</h1>`);
    } else if (line.startsWith('## ')) {
      out.push(`<h2>${inline(line.slice(3))}</h2>`);
    } else if (line.startsWith('### ')) {
      out.push(`<h3>${inline(line.slice(4))}</h3>`);
    } else if (line.trim() === '---') {
      out.push('<hr/>');
    } else if (line.trim() === '') {
      // skip
    } else if (/^\d+\.\s/.test(line.trim())) {
      out.push(`<p>${inline(line)}</p>`);
    } else if (line.startsWith('- ')) {
      out.push(`<li>${inline(line.slice(2))}</li>`);
    } else {
      out.push(`<p>${inline(line)}</p>`);
    }
  }
  closeTable();
  closeBq();
  if (inCode) out.push('</code></pre>');

  function inline(s) {
    return escape(s)
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      .replace(/`([^`]+)`/g, '<code>$1</code>')
      .replace(/\*(.+?)\*/g, '<em>$1</em>');
  }

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>GlowTap — Standard Database Performance Benchmark</title>
<link rel="preconnect" href="https://fonts.googleapis.com"/>
<link href="https://fonts.googleapis.com/css2?family=Sora:wght@500;600;700&family=IBM+Plex+Sans:wght@400;500;600&display=swap" rel="stylesheet"/>
<style>
  :root { --ink:#12201c; --muted:#5c726a; --line:#d7e3dc; --teal:#0f766e; --bg:#f3f8f5; }
  body {
    margin:0; font-family:"IBM Plex Sans",system-ui,sans-serif; color:var(--ink);
    background: radial-gradient(900px 500px at 0% 0%, rgba(20,184,166,.12), transparent 55%),
                linear-gradient(180deg,#eef6f2,#f7faf8 40%,#eef2f0);
    line-height:1.5;
  }
  .wrap { max-width:980px; margin:0 auto; padding:32px 20px 64px; }
  .hero {
    background: linear-gradient(135deg,#0b3d38,#0f766e 55%,#0e7490);
    color:#f4fffb; border-radius:22px; padding:32px 36px; margin-bottom:24px;
    box-shadow:0 12px 40px rgba(18,32,28,.12);
  }
  .hero .brand { font-family:Sora,sans-serif; font-size:.75rem; letter-spacing:.14em; text-transform:uppercase; opacity:.85; }
  .hero h1 { font-family:Sora,sans-serif; margin:8px 0 6px; font-size:clamp(1.6rem,3vw,2.2rem); letter-spacing:-.02em; }
  .hero p { margin:0; opacity:.9; font-size:.95rem; }
  .card {
    background:#fff; border:1px solid var(--line); border-radius:18px; padding:22px 26px;
    box-shadow:0 10px 30px rgba(18,32,28,.06); margin-bottom:18px;
  }
  h2 { font-family:Sora,sans-serif; font-size:1.15rem; margin:1.4rem 0 .6rem; color:var(--teal); }
  h3 { font-family:Sora,sans-serif; font-size:1rem; margin:1.1rem 0 .45rem; }
  p,li { font-size:.95rem; }
  hr { border:none; border-top:1px solid var(--line); margin:1.5rem 0; }
  table { width:100%; border-collapse:collapse; font-size:.86rem; margin:10px 0 16px; }
  th,td { border-bottom:1px solid var(--line); padding:8px 10px; text-align:left; vertical-align:top; }
  th { background:var(--bg); color:var(--muted); font-size:.7rem; text-transform:uppercase; letter-spacing:.04em; font-family:Sora,sans-serif; }
  td:nth-child(n+2) { text-align:right; font-variant-numeric:tabular-nums; }
  th:nth-child(n+2) { text-align:right; }
  blockquote {
    margin:12px 0; padding:12px 16px; border-left:4px solid var(--teal);
    background:var(--bg); border-radius:0 12px 12px 0; color:var(--muted);
  }
  code { background:#e7f2ee; padding:1px 6px; border-radius:6px; font-size:.88em; }
  pre { background:#10241f; color:#d7ebe4; padding:14px; border-radius:12px; overflow:auto; }
  footer { text-align:center; color:var(--muted); font-size:.8rem; margin-top:28px; }
  .chip {
    display:inline-block; margin:6px 6px 0 0; padding:4px 10px; border-radius:999px;
    background:rgba(255,255,255,.16); font-size:.78rem;
  }
</style>
</head>
<body>
<div class="wrap">
  <header class="hero">
    <div class="brand">GlowTap</div>
    <h1>Standard Database Performance Benchmark</h1>
    <p>Industry latency SLOs &amp; standard test-data volumes for OLTP SaaS (bookings / dashboards / writes).</p>
    <div>
      <span class="chip">Industry norms only</span>
      <span class="chip">6 Aug 2026</span>
      <span class="chip">Postgres OLTP</span>
    </div>
  </header>
  <div class="card">
${out.join('\n').replace(/^<h1>[\s\S]*?<\/h1>/, '')}
  </div>
  <footer>GlowTap · Standard Database Performance Benchmark · Confidential</footer>
</div>
</body>
</html>`;
}

async function main() {
  const md = fs.readFileSync(mdPath, 'utf8');
  const html = mdToSimpleHtml(md);
  fs.writeFileSync(htmlPath, html);
  console.log('Wrote', htmlPath);

  try {
    const puppeteer = require(path.join(root, 'node_modules', 'puppeteer'));
    const browser = await puppeteer.launch({
      headless: 'new',
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
    });
    const page = await browser.newPage();
    await page.goto('file:///' + htmlPath.replace(/\\/g, '/'), { waitUntil: 'networkidle0' });
    await page.pdf({
      path: pdfPath,
      format: 'A4',
      printBackground: true,
      margin: { top: '12mm', bottom: '14mm', left: '12mm', right: '12mm' },
      displayHeaderFooter: true,
      headerTemplate: `<div style="width:100%;font-size:8px;padding:0 12mm;color:#5c726a;font-family:sans-serif;display:flex;justify-content:space-between;"><span style="color:#0f766e;font-weight:700;">GlowTap</span><span>Standard DB Performance Benchmark</span></div>`,
      footerTemplate: `<div style="width:100%;font-size:8px;padding:0 12mm;color:#5c726a;font-family:sans-serif;display:flex;justify-content:space-between;"><span>Confidential</span><span>Page <span class="pageNumber"></span> / <span class="totalPages"></span></span></div>`,
    });
    await browser.close();
    console.log('Wrote', pdfPath);
  } catch (e) {
    console.log('PDF skipped:', e.message);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
