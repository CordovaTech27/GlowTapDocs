const { mdToPdf } = require('md-to-pdf');
const fs = require('fs');
const path = require('path');

const BRAND = {
  name: 'GlowTap',
  tagline: 'Tap. Book. Glow.',
  primary: '#6C3AED',
  accentPink: '#F472B6',
  lavender: '#DDD6FE',
  grey: '#9CA3AF',
};

const solutionDocsDir = path.join(__dirname, '..', 'Solution docs');
const repoRoot = path.join(__dirname, '..', '..', '..');
const logoSvg = fs.readFileSync(path.join(repoRoot, '456.svg'), 'utf8');
const logoDataUri = `data:image/svg+xml;base64,${Buffer.from(logoSvg).toString('base64')}`;

const docs = [
  {
    input: 'Organization-structure.md',
    output: 'Organization-structure.pdf',
    docTitle: 'Organization Structure',
    docSubtitle: 'Super Admin — Org → Branch Hierarchy & Seed Data',
    version: '1.1',
    date: 'July 12, 2026',
  },
];

function buildCoverHtml(doc) {
  return `
<div class="doc-cover">
  <div class="doc-cover-inner">
    <img class="brand-logo-wide" src="${logoDataUri}" alt="GlowTap — Tap. Book. Glow." />
    <div class="doc-type">
      <h2>${doc.docTitle}</h2>
      <p>${doc.docSubtitle}</p>
    </div>
    <div class="doc-meta">
      <strong>Version</strong> ${doc.version} &nbsp;|&nbsp;
      <strong>Date</strong> ${doc.date} &nbsp;|&nbsp;
      <strong>Confidential</strong>
    </div>
  </div>
</div>
`;
}

async function generate() {
  for (const doc of docs) {
    const inputPath = path.join(solutionDocsDir, doc.input);
    const outputPath = path.join(solutionDocsDir, doc.output);
    const rawMd = fs.readFileSync(inputPath, 'utf8');
    const bodyMd = rawMd.replace(/^# GlowTap[\s\S]*?^---\n/m, '');
    const fullMd = buildCoverHtml(doc) + '\n\n' + bodyMd;

    console.log(`Generating ${doc.output}...`);
    const pdf = await mdToPdf(
      { content: fullMd },
      {
        stylesheet: [path.join(repoRoot, 'pdf-styles.css')],
        pdf_options: {
          format: 'A4',
          margin: { top: '22mm', bottom: '18mm', left: '15mm', right: '15mm' },
          printBackground: true,
          displayHeaderFooter: true,
          headerTemplate: `
        <div style="width:100%;font-size:7px;padding:0 15mm;display:flex;justify-content:space-between;align-items:center;color:${BRAND.grey};">
          <span style="color:${BRAND.primary};font-weight:600;">${BRAND.name}</span>
          <span style="letter-spacing:1.5px;text-transform:uppercase;font-size:6px;color:${BRAND.accentPink};">${BRAND.tagline}</span>
          <span>${doc.docTitle}</span>
        </div>`,
          footerTemplate: `
        <div style="width:100%;font-size:7px;padding:0 15mm;display:flex;justify-content:space-between;align-items:center;color:${BRAND.grey};">
          <span>&copy; ${new Date().getFullYear()} ${BRAND.name}</span>
          <span>Page <span class="pageNumber"></span> of <span class="totalPages"></span></span>
          <span style="color:${BRAND.lavender};">Confidential</span>
        </div>`,
        },
      }
    );

    if (pdf && pdf.content) {
      fs.writeFileSync(outputPath, pdf.content);
      console.log(`  Created ${doc.output} (${(pdf.content.length / 1024).toFixed(0)} KB)`);
    } else {
      console.error(`  Failed to generate ${doc.output}`);
      process.exit(1);
    }
  }
}

generate().catch((err) => {
  console.error('PDF generation failed:', err);
  process.exit(1);
});
