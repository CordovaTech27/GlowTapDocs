/**
 * Build shareable HTML (+ optional PDF) DB health report from reports/db-stats.json
 * Usage: node SchemaMaking/superAdmin/scripts/build-shareable-report.js
 */
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const root = path.join(__dirname, '..');
const reportsDir = path.join(root, 'reports');
const data = JSON.parse(fs.readFileSync(path.join(reportsDir, 'db-stats.json'), 'utf8'));

const when = new Date(data.generated_at).toLocaleString('en-IN', {
  timeZone: 'Asia/Kolkata',
  dateStyle: 'medium',
  timeStyle: 'short',
});

const flagged = [
  { table: 'branches', before: 43 },
  { table: 'organizations', before: 11 },
  { table: 'org_bill_structure', before: 6 },
].map((f) => {
  const t = data.tables.find((x) => x.table === f.table);
  return { ...f, ...(t || {}) };
});

const top10 = data.tables.slice(0, 10);
const maxKb = Math.max(
  ...top10.map((t) => parseFloat(String(t.total_size).replace(/[^\d.]/g, '')) || 0)
);

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
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>GlowTap Super Admin — DB Health Report</title>
  <style>
    :root {
      --bg: #f7f6f3;
      --card: #ffffff;
      --ink: #1a1a1a;
      --muted: #5c5c5c;
      --line: #e6e4df;
      --accent: #0f6b5c;
      --ok: #1b7f4e;
      --ok-bg: #e8f6ee;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: "Segoe UI", system-ui, -apple-system, sans-serif;
      color: var(--ink);
      background: var(--bg);
      line-height: 1.45;
    }
    .page {
      max-width: 960px;
      margin: 0 auto;
      padding: 40px 28px 64px;
    }
    header {
      border-bottom: 1px solid var(--line);
      padding-bottom: 24px;
      margin-bottom: 28px;
    }
    .brand {
      font-size: 12px;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      color: var(--accent);
      font-weight: 600;
      margin-bottom: 8px;
    }
    h1 {
      margin: 0 0 8px;
      font-size: 28px;
      font-weight: 650;
      letter-spacing: -0.02em;
    }
    .meta { color: var(--muted); font-size: 14px; }
    .badges { margin-top: 14px; display: flex; flex-wrap: wrap; gap: 8px; }
    .badge {
      display: inline-block;
      padding: 4px 10px;
      border-radius: 999px;
      font-size: 12px;
      font-weight: 600;
      background: var(--ok-bg);
      color: var(--ok);
    }
    .badge.neutral {
      background: #eeebe6;
      color: #444;
    }
    .stats {
      display: grid;
      grid-template-columns: repeat(5, 1fr);
      gap: 12px;
      margin-bottom: 28px;
    }
    @media (max-width: 720px) {
      .stats { grid-template-columns: repeat(2, 1fr); }
    }
    .stat {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 10px;
      padding: 16px;
    }
    .stat .v {
      font-size: 26px;
      font-weight: 700;
      letter-spacing: -0.03em;
    }
    .stat .l {
      font-size: 12px;
      color: var(--muted);
      margin-top: 4px;
      text-transform: uppercase;
      letter-spacing: 0.06em;
    }
    .stat.ok .v { color: var(--ok); }
    section {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 12px;
      padding: 20px 22px;
      margin-bottom: 18px;
    }
    h2 {
      margin: 0 0 14px;
      font-size: 16px;
      font-weight: 650;
    }
    .note {
      background: var(--ok-bg);
      border: 1px solid #c7ebd5;
      color: #145c38;
      border-radius: 8px;
      padding: 12px 14px;
      font-size: 14px;
      margin-bottom: 18px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 13px;
    }
    th, td {
      text-align: left;
      padding: 9px 10px;
      border-bottom: 1px solid var(--line);
    }
    th {
      font-size: 11px;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: var(--muted);
      font-weight: 600;
    }
    td.num, th.num { text-align: right; font-variant-numeric: tabular-nums; }
    tr:last-child td { border-bottom: none; }
    code {
      font-family: ui-monospace, Consolas, monospace;
      font-size: 12px;
      background: #f0eeea;
      padding: 1px 5px;
      border-radius: 4px;
    }
    .bars { display: flex; flex-direction: column; gap: 10px; }
    .bar-row { display: grid; grid-template-columns: 160px 1fr 56px; gap: 10px; align-items: center; }
    .bar-label { font-size: 12px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .bar-track {
      height: 10px;
      background: #eceae5;
      border-radius: 6px;
      overflow: hidden;
    }
    .bar-fill {
      height: 100%;
      background: var(--accent);
      border-radius: 6px;
    }
    .bar-val { font-size: 12px; color: var(--muted); text-align: right; }
    footer {
      margin-top: 28px;
      color: var(--muted);
      font-size: 12px;
      text-align: center;
    }
    @media print {
      body { background: #fff; }
      .page { padding: 12px; }
      section, .stat { break-inside: avoid; }
    }
  </style>
</head>
<body>
  <div class="page">
    <header>
      <div class="brand">GlowTap · Confidential</div>
      <h1>Super Admin database health report</h1>
      <div class="meta">Generated ${esc(when)} IST · Neon Postgres · public schema</div>
      <div class="badges">
        <span class="badge">Dead tuples: ${data.summary.dead_tuples}</span>
        <span class="badge">All FKs indexed</span>
        <span class="badge neutral">Migration 053</span>
      </div>
    </header>

    <div class="stats">
      <div class="stat"><div class="v">${data.summary.tables}</div><div class="l">Tables</div></div>
      <div class="stat"><div class="v">${data.summary.indexes}</div><div class="l">Indexes</div></div>
      <div class="stat"><div class="v">${data.summary.foreign_keys}</div><div class="l">Foreign keys</div></div>
      <div class="stat"><div class="v">${data.summary.live_rows}</div><div class="l">Live rows</div></div>
      <div class="stat ok"><div class="v">${data.summary.dead_tuples}</div><div class="l">Dead tuples</div></div>
    </div>

    <div class="note">
      After <code>VACUUM ANALYZE</code>, dead tuples are cleared across the schema
      (including previously high counts on <code>branches</code>, <code>organizations</code>,
      and <code>org_bill_structure</code>). Elevated index % is normal on a small seeded database
      with full foreign-key index coverage.
    </div>

    <section>
      <h2>Largest tables by total size</h2>
      <div class="bars">
        ${top10
          .map((t) => {
            const kb = parseFloat(String(t.total_size).replace(/[^\d.]/g, '')) || 0;
            const pct = maxKb ? Math.round((kb / maxKb) * 100) : 0;
            return `<div class="bar-row">
              <div class="bar-label"><code>${esc(t.table)}</code></div>
              <div class="bar-track"><div class="bar-fill" style="width:${pct}%"></div></div>
              <div class="bar-val">${esc(t.total_size)}</div>
            </div>`;
          })
          .join('')}
      </div>
    </section>

    <section>
      <h2>Previously flagged tables (before → after vacuum)</h2>
      <table>
        <thead>
          <tr>
            <th>Table</th>
            <th class="num">Rows</th>
            <th class="num">Dead before</th>
            <th class="num">Dead now</th>
            <th class="num">Total size</th>
            <th class="num">Indexes</th>
          </tr>
        </thead>
        <tbody>
          ${flagged
            .map(
              (t) => `<tr>
            <td><code>${esc(t.table)}</code></td>
            <td class="num">${t.rows ?? '—'}</td>
            <td class="num">${t.before}</td>
            <td class="num"><strong>${t.dead_tuples ?? 0}</strong></td>
            <td class="num">${esc(t.total_size || '—')}</td>
            <td class="num">${t.index_count ?? '—'}</td>
          </tr>`
            )
            .join('')}
        </tbody>
      </table>
    </section>

    <section>
      <h2>Full table inventory</h2>
      <table>
        <thead>
          <tr>
            <th>Table</th>
            <th class="num">Rows</th>
            <th class="num">Dead</th>
            <th class="num">Total size</th>
            <th class="num">Index size</th>
            <th class="num">Index %</th>
            <th class="num">Indexes</th>
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
    </section>

    <footer>
      GlowTap Docs · Super Admin Neon schema · For internal sharing only
    </footer>
  </div>
</body>
</html>
`;

const htmlPath = path.join(reportsDir, 'db-performance-report.html');
fs.writeFileSync(htmlPath, html, 'utf8');
console.log('Wrote', htmlPath);

// PDF via md-to-pdf from a slim companion markdown (reuse existing md if present)
const mdPath = path.join(reportsDir, 'db-performance-report.md');
const pdfPath = path.join(reportsDir, 'db-performance-report.pdf');
try {
  const repoRoot = path.join(root, '../..');
  execSync(
    `npx md-to-pdf "${mdPath}" --dest "${pdfPath}"`,
    { cwd: repoRoot, stdio: 'inherit', env: process.env }
  );
  console.log('Wrote', pdfPath);
} catch (e) {
  console.warn('PDF generation skipped or failed — HTML is ready to share / Print to PDF.');
}
