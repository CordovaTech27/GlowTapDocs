/**
 * Build Database-ER-Guide.html + .pdf with Mermaid ER diagrams rendered.
 */
const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer');

const solutionDocsDir = path.join(__dirname, '..', 'Solution docs');
const repoRoot = path.join(__dirname, '..', '..', '..');
const mdPath = path.join(solutionDocsDir, 'Database-ER-Guide.md');
const htmlPath = path.join(solutionDocsDir, 'Database-ER-Guide.html');
const pdfPath = path.join(solutionDocsDir, 'Database-ER-Guide.pdf');

const BRAND = {
  name: 'GlowTap',
  tagline: 'Tap. Book. Glow.',
  primary: '#6C3AED',
  accentPink: '#F472B6',
  lavender: '#DDD6FE',
  grey: '#9CA3AF',
};

function escapeHtml(s) {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function mdInline(text) {
  return escapeHtml(text)
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
    .replace(/\*([^*]+)\*/g, '<em>$1</em>')
    .replace(
      /\[([^\]]+)\]\(([^)]+)\)/g,
      '<a href="$2">$1</a>'
    );
}

function parseMdToBody(md) {
  // Strip title block before first ---
  const stripped = md.replace(/^# [\s\S]*?\n---\n+/m, '');

  const parts = [];
  const fenceRe = /```(\w*)\n([\s\S]*?)```/g;
  let last = 0;
  let m;
  while ((m = fenceRe.exec(stripped)) !== null) {
    if (m.index > last) {
      parts.push({ type: 'md', text: stripped.slice(last, m.index) });
    }
    const lang = (m[1] || '').toLowerCase();
    if (lang === 'mermaid') {
      parts.push({ type: 'mermaid', text: m[2].trim() });
    } else {
      parts.push({ type: 'code', lang, text: m[2] });
    }
    last = m.index + m[0].length;
  }
  if (last < stripped.length) {
    parts.push({ type: 'md', text: stripped.slice(last) });
  }

  let html = '';
  for (const part of parts) {
    if (part.type === 'mermaid') {
      html += `<div class="mermaid-wrap"><div class="mermaid">${part.text}</div></div>\n`;
      continue;
    }
    if (part.type === 'code') {
      html += `<pre><code>${escapeHtml(part.text)}</code></pre>\n`;
      continue;
    }
    html += renderMdChunk(part.text);
  }
  return html;
}

function renderMdChunk(chunk) {
  const lines = chunk.split('\n');
  let out = '';
  let i = 0;
  let inUl = false;
  let inOl = false;
  let inBq = false;
  let inTable = false;
  let tableRows = [];

  const closeLists = () => {
    if (inUl) {
      out += '</ul>\n';
      inUl = false;
    }
    if (inOl) {
      out += '</ol>\n';
      inOl = false;
    }
  };
  const closeBq = () => {
    if (inBq) {
      out += '</blockquote>\n';
      inBq = false;
    }
  };
  const flushTable = () => {
    if (!inTable) return;
    out += '<table>\n';
    tableRows.forEach((row, idx) => {
      const cells = row
        .replace(/^\|/, '')
        .replace(/\|$/, '')
        .split('|')
        .map((c) => c.trim());
      if (idx === 1 && cells.every((c) => /^[-:]+$/.test(c))) return;
      const tag = idx === 0 ? 'th' : 'td';
      out +=
        '<tr>' +
        cells.map((c) => `<${tag}>${mdInline(c)}</${tag}>`).join('') +
        '</tr>\n';
    });
    out += '</table>\n';
    inTable = false;
    tableRows = [];
  };

  while (i < lines.length) {
    const line = lines[i];

    if (/^\|/.test(line)) {
      closeLists();
      closeBq();
      inTable = true;
      tableRows.push(line);
      i++;
      continue;
    }
    if (inTable) flushTable();

    if (/^>\s?/.test(line)) {
      closeLists();
      if (!inBq) {
        out += '<blockquote>\n';
        inBq = true;
      }
      out += `<p>${mdInline(line.replace(/^>\s?/, ''))}</p>\n`;
      i++;
      continue;
    }
    if (inBq && line.trim() === '') {
      closeBq();
      i++;
      continue;
    }
    if (inBq && !/^>\s?/.test(line)) closeBq();

    const h = /^(#{1,3})\s+(.+)$/.exec(line);
    if (h) {
      closeLists();
      const level = h[1].length;
      out += `<h${level}>${mdInline(h[2])}</h${level}>\n`;
      i++;
      continue;
    }

    if (/^---+$/.test(line.trim())) {
      closeLists();
      out += '<hr />\n';
      i++;
      continue;
    }

    const ul = /^[-*]\s+(.+)$/.exec(line);
    if (ul) {
      if (inOl) {
        out += '</ol>\n';
        inOl = false;
      }
      if (!inUl) {
        out += '<ul>\n';
        inUl = true;
      }
      out += `<li>${mdInline(ul[1])}</li>\n`;
      i++;
      continue;
    }

    const ol = /^\d+\.\s+(.+)$/.exec(line);
    if (ol) {
      if (inUl) {
        out += '</ul>\n';
        inUl = false;
      }
      if (!inOl) {
        out += '<ol>\n';
        inOl = true;
      }
      out += `<li>${mdInline(ol[1])}</li>\n`;
      i++;
      continue;
    }

    if (line.trim() === '') {
      closeLists();
      i++;
      continue;
    }

    closeLists();
    out += `<p>${mdInline(line)}</p>\n`;
    i++;
  }
  flushTable();
  closeLists();
  closeBq();
  return out;
}

function buildHtml(bodyHtml) {
  let logoDataUri = '';
  try {
    const logoSvg = fs.readFileSync(path.join(repoRoot, '456.svg'), 'utf8');
    logoDataUri = `data:image/svg+xml;base64,${Buffer.from(logoSvg).toString('base64')}`;
  } catch {
    /* optional */
  }

  const cssPath = path.join(repoRoot, 'pdf-styles.css');
  const css = fs.existsSync(cssPath) ? fs.readFileSync(cssPath, 'utf8') : '';

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>GlowTap — Database ER Guide</title>
  <style>
${css}
body { padding: 24px 32px; max-width: 960px; margin: 0 auto; background: #fff; }

/* Cover must fit exactly one PDF page (no spill onto page 2) */
.doc-cover {
  box-sizing: border-box;
  width: 100%;
  height: 240mm; /* stay under A4 content area so cover never spills to page 2 */
  max-height: 240mm;
  min-height: 0 !important;
  margin: 0 !important;
  padding: 28mm 24px !important;
  overflow: hidden;
  page-break-after: always;
  break-after: page;
  page-break-inside: avoid;
  break-inside: avoid;
}
.doc-cover .brand-logo-wide {
  width: 260px;
  margin-bottom: 28px;
}
.doc-cover .doc-type {
  margin-bottom: 24px;
  padding: 14px 28px;
}

.mermaid-wrap {
  margin: 1.25rem 0 1.75rem;
  padding: 1rem;
  background: #fafafa;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  overflow-x: auto;
  page-break-inside: avoid;
}
.mermaid { text-align: center; }
h2 { page-break-before: auto; }
pre {
  background: #f3f4f6;
  padding: 0.75rem 1rem;
  border-radius: 6px;
  overflow-x: auto;
  font-size: 9.5pt;
}
code {
  font-family: Consolas, 'Courier New', monospace;
  font-size: 0.92em;
  background: #f3f4f6;
  padding: 0.1em 0.35em;
  border-radius: 3px;
}
pre code { background: transparent; padding: 0; }
table { width: 100%; border-collapse: collapse; margin: 1rem 0; font-size: 10pt; }
th, td { border: 1px solid #e5e7eb; padding: 0.45rem 0.6rem; text-align: left; vertical-align: top; }
th { background: #ede9fe; color: #5b21b6; }
blockquote {
  border-left: 4px solid #a78bfa;
  margin: 1rem 0;
  padding: 0.5rem 1rem;
  background: #faf5ff;
  color: #4b5563;
}
@media print {
  body { padding: 0; max-width: none; }
  .doc-cover {
    height: 240mm;
    max-height: 240mm;
    margin: 0 !important;
    overflow: hidden;
  }
}
  </style>
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
</head>
<body>
<div class="doc-cover">
  <div class="doc-cover-inner">
    ${logoDataUri ? `<img class="brand-logo-wide" src="${logoDataUri}" alt="GlowTap" />` : '<h1 style="color:#fff">GlowTap</h1>'}
    <div class="doc-type">
      <h2>Database ER Guide</h2>
      <p>Super Admin — Tables, Relationships &amp; Explanations</p>
    </div>
    <div class="doc-meta">
      <strong>Version</strong> 1.0 &nbsp;|&nbsp;
      <strong>Date</strong> 29 Jul 2026 &nbsp;|&nbsp;
      <strong>Confidential</strong>
    </div>
  </div>
</div>

${bodyHtml}

<script>
  mermaid.initialize({
    startOnLoad: true,
    theme: 'base',
    themeVariables: {
      primaryColor: '#EDE9FE',
      primaryTextColor: '#1F2937',
      primaryBorderColor: '#6C3AED',
      lineColor: '#6C3AED',
      secondaryColor: '#FDF2F8',
      tertiaryColor: '#F3F4F6',
      fontFamily: 'Segoe UI, sans-serif',
      fontSize: '13px'
    },
    er: { useMaxWidth: true },
    flowchart: { useMaxWidth: true, htmlLabels: true }
  });
</script>
</body>
</html>`;
}

async function main() {
  const md = fs.readFileSync(mdPath, 'utf8');
  const body = parseMdToBody(md);
  const html = buildHtml(body);
  fs.writeFileSync(htmlPath, html, 'utf8');
  console.log('Wrote', htmlPath);

  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });
  try {
    const page = await browser.newPage();
    await page.goto('file:///' + htmlPath.replace(/\\/g, '/'), {
      waitUntil: 'networkidle0',
      timeout: 120000,
    });
    // Wait until mermaid has rendered SVGs
    await page.waitForFunction(
      () => {
        const nodes = document.querySelectorAll('.mermaid');
        if (!nodes.length) return true;
        return [...nodes].every((n) => n.querySelector('svg'));
      },
      { timeout: 90000 }
    );
    // Brief settle for layout
    await new Promise((r) => setTimeout(r, 800));

    await page.pdf({
      path: pdfPath,
      format: 'A4',
      printBackground: true,
      margin: { top: '18mm', bottom: '16mm', left: '14mm', right: '14mm' },
      displayHeaderFooter: true,
      headerTemplate: `
        <div style="width:100%;font-size:7px;padding:0 14mm;display:flex;justify-content:space-between;align-items:center;color:${BRAND.grey};">
          <span style="color:${BRAND.primary};font-weight:600;">${BRAND.name}</span>
          <span style="letter-spacing:1.5px;text-transform:uppercase;font-size:6px;color:${BRAND.accentPink};">${BRAND.tagline}</span>
          <span>Database ER Guide</span>
        </div>`,
      footerTemplate: `
        <div style="width:100%;font-size:7px;padding:0 14mm;display:flex;justify-content:space-between;align-items:center;color:${BRAND.grey};">
          <span>&copy; ${new Date().getFullYear()} ${BRAND.name}</span>
          <span>Page <span class="pageNumber"></span> of <span class="totalPages"></span></span>
          <span style="color:${BRAND.lavender};">Confidential</span>
        </div>`,
    });
    console.log('Wrote', pdfPath);
  } finally {
    await browser.close();
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
