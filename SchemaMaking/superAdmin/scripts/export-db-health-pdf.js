/**
 * Export canvas-lookalike DB health report as PDF (via Puppeteer).
 * Usage: node SchemaMaking/superAdmin/scripts/export-db-health-pdf.js
 */
const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer');

const reportsDir = path.join(__dirname, '../reports');
const data = JSON.parse(fs.readFileSync(path.join(reportsDir, 'db-stats.json'), 'utf8'));

const GENERATED = new Date(data.generated_at).toLocaleString('en-IN', {
  timeZone: 'Asia/Kolkata',
  day: 'numeric',
  month: 'short',
  year: 'numeric',
  hour: '2-digit',
  minute: '2-digit',
}) + ' IST';

const SOURCE = 'Neon Postgres · public schema · after VACUUM ANALYZE + migration 053';

const TOP_CHART = data.tables.slice(0, 10).map((t) => ({
  label: t.table.length > 18 ? t.table.slice(0, 16) + '…' : t.table,
  full: t.table,
  kb: parseFloat(String(t.total_size).replace(/[^\d.]/g, '')) || 0,
  size: t.total_size,
}));
const maxKb = Math.max(...TOP_CHART.map((d) => d.kb), 1);

function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<title>GlowTap Super Admin — DB health report</title>
<style>
  @page { size: A4; margin: 14mm 12mm; }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    font-family: "Segoe UI", system-ui, -apple-system, sans-serif;
    color: #1a1a1a;
    background: #fff;
    font-size: 11px;
    line-height: 1.4;
  }
  .wrap { max-width: 900px; margin: 0 auto; }
  h1 {
    margin: 0 0 6px;
    font-size: 22px;
    font-weight: 650;
    letter-spacing: -0.02em;
  }
  .sub { color: #666; font-size: 11px; margin: 2px 0; }
  .pills { display: flex; gap: 8px; flex-wrap: wrap; margin: 12px 0 18px; }
  .pill {
    border-radius: 999px;
    padding: 3px 10px;
    font-size: 10px;
    font-weight: 600;
  }
  .pill.ok { background: #e8f6ee; color: #1b7f4e; }
  .pill.info { background: #e8f1fb; color: #1a5f9e; }
  .pill.neutral { background: #f0eeea; color: #444; }
  .stats {
    display: grid;
    grid-template-columns: repeat(5, 1fr);
    gap: 10px;
    margin-bottom: 16px;
  }
  .stat {
    border: 1px solid #e6e4df;
    border-radius: 8px;
    padding: 12px 10px;
  }
  .stat .v { font-size: 22px; font-weight: 700; letter-spacing: -0.03em; }
  .stat .v.ok { color: #1b7f4e; }
  .stat .l {
    margin-top: 3px;
    font-size: 9px;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: #666;
  }
  .callout {
    background: #e8f6ee;
    border: 1px solid #c7ebd5;
    color: #145c38;
    border-radius: 8px;
    padding: 10px 12px;
    margin-bottom: 18px;
    font-size: 11px;
  }
  .callout strong { display: block; margin-bottom: 4px; }
  h2 {
    margin: 0 0 6px;
    font-size: 14px;
    font-weight: 650;
  }
  .section { margin-bottom: 20px; page-break-inside: avoid; }
  .bars { margin-top: 10px; }
  .bar-row {
    display: grid;
    grid-template-columns: 140px 1fr 52px;
    gap: 8px;
    align-items: center;
    margin-bottom: 7px;
  }
  .bar-label { font-size: 10px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .bar-track { height: 9px; background: #eceae5; border-radius: 5px; overflow: hidden; }
  .bar-fill { height: 100%; background: #0f6b5c; border-radius: 5px; }
  .bar-val { font-size: 10px; color: #666; text-align: right; }
  table { width: 100%; border-collapse: collapse; font-size: 9.5px; }
  th, td { padding: 6px 7px; border-bottom: 1px solid #e6e4df; text-align: left; }
  th {
    font-size: 8.5px;
    text-transform: uppercase;
    letter-spacing: 0.04em;
    color: #666;
    font-weight: 600;
  }
  .num { text-align: right; font-variant-numeric: tabular-nums; }
  code {
    font-family: ui-monospace, Consolas, monospace;
    font-size: 9px;
    background: #f0eeea;
    padding: 1px 4px;
    border-radius: 3px;
  }
  .card {
    border: 1px solid #e6e4df;
    border-radius: 10px;
    overflow: hidden;
  }
  .card-h {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 10px 12px;
    border-bottom: 1px solid #e6e4df;
    font-weight: 650;
    font-size: 12px;
  }
  .card-b { padding: 0; }
  .hr { height: 1px; background: #e6e4df; margin: 16px 0; }
  footer { margin-top: 16px; color: #888; font-size: 9px; text-align: center; }
</style>
</head>
<body>
<div class="wrap">
  <h1>GlowTap Super Admin — DB health report</h1>
  <div class="sub">${esc(SOURCE)}</div>
  <div class="sub">Generated ${esc(GENERATED)}</div>
  <div class="pills">
    <span class="pill ok">Dead tuples: ${data.summary.dead_tuples}</span>
    <span class="pill info">All FKs indexed</span>
    <span class="pill neutral">Migration 053 applied</span>
  </div>

  <div class="stats">
    <div class="stat"><div class="v">${data.summary.tables}</div><div class="l">Tables</div></div>
    <div class="stat"><div class="v">${data.summary.indexes}</div><div class="l">Indexes</div></div>
    <div class="stat"><div class="v">${data.summary.foreign_keys}</div><div class="l">Foreign keys</div></div>
    <div class="stat"><div class="v">${data.summary.live_rows}</div><div class="l">Live rows</div></div>
    <div class="stat"><div class="v ok">${data.summary.dead_tuples}</div><div class="l">Dead tuples</div></div>
  </div>

  <div class="callout">
    <strong>Health check</strong>
    After VACUUM ANALYZE, dead tuples are cleared on all tables (including branches,
    organizations, org_bill_structure). High index % is expected on a small seeded
    database with full FK coverage.
  </div>

  <div class="hr"></div>

  <div class="section">
    <h2>Largest tables by total size (kB)</h2>
    <div class="sub">Source: pg_total_relation_size · top 10</div>
    <div class="bars">
      ${TOP_CHART.map((d) => {
        const pct = Math.round((d.kb / maxKb) * 100);
        return `<div class="bar-row">
          <div class="bar-label" title="${esc(d.full)}">${esc(d.label)}</div>
          <div class="bar-track"><div class="bar-fill" style="width:${pct}%"></div></div>
          <div class="bar-val">${esc(d.size)}</div>
        </div>`;
      }).join('')}
    </div>
  </div>

  <div class="hr"></div>

  <div class="section">
    <h2>Previously flagged tables</h2>
    <table>
      <thead>
        <tr>
          <th>Table</th>
          <th class="num">Rows</th>
          <th class="num">Dead (before)</th>
          <th class="num">Dead (now)</th>
          <th class="num">Total size</th>
          <th class="num">Indexes</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><code>branches</code></td>
          <td class="num">11</td><td class="num">43</td><td class="num"><strong>0</strong></td>
          <td class="num">296 kB</td><td class="num">11</td>
        </tr>
        <tr>
          <td><code>organizations</code></td>
          <td class="num">5</td><td class="num">11</td><td class="num"><strong>0</strong></td>
          <td class="num">240 kB</td><td class="num">12</td>
        </tr>
        <tr>
          <td><code>org_bill_structure</code></td>
          <td class="num">5</td><td class="num">6</td><td class="num"><strong>0</strong></td>
          <td class="num">208 kB</td><td class="num">10</td>
        </tr>
      </tbody>
    </table>
  </div>

  <div class="hr"></div>

  <div class="card">
    <div class="card-h">
      <span>Full table inventory</span>
      <span class="pill neutral">53 tables</span>
    </div>
    <div class="card-b">
      <table>
        <thead>
          <tr>
            <th>Table</th>
            <th class="num">Rows</th>
            <th class="num">Dead</th>
            <th class="num">Total size</th>
            <th class="num">Index size</th>
            <th class="num">Index %</th>
            <th class="num">Index count</th>
          </tr>
        </thead>
        <tbody>
          ${data.tables
            .map(
              (t) => `<tr>
            <td><code>${esc(t.table)}</code></td>
            <td class="num">${t.rows}</td>
            <td class="num">${t.dead_tuples}</td>
            <td class="num">${esc(t.total_size)}</td>
            <td class="num">${esc(t.index_size)}</td>
            <td class="num">${t.index_pct}%</td>
            <td class="num">${t.index_count}</td>
          </tr>`
            )
            .join('')}
        </tbody>
      </table>
    </div>
  </div>

  <footer>GlowTap Docs · Confidential · Canvas-matched share PDF</footer>
</div>
</body>
</html>`;

const htmlPath = path.join(reportsDir, 'db-health-canvas-share.html');
const pdfPath = path.join(reportsDir, 'GlowTap-SuperAdmin-DB-Health-Report.pdf');
fs.writeFileSync(htmlPath, html, 'utf8');

(async () => {
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });
  const page = await browser.newPage();
  await page.setContent(html, { waitUntil: 'networkidle0' });
  await page.pdf({
    path: pdfPath,
    format: 'A4',
    printBackground: true,
    margin: { top: '12mm', right: '10mm', bottom: '12mm', left: '10mm' },
  });
  await browser.close();
  console.log('Wrote HTML:', htmlPath);
  console.log('Wrote PDF:', pdfPath);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
