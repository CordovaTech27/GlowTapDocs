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
  charcoal: '#374151',
};

const docs = [
  {
    input: 'Super-Admin-Functional-Spec.md',
    output: 'Super-Admin-Functional-Spec.pdf',
    docTitle: 'Functional Specification',
    docSubtitle: 'Super Admin Portal — Business & Operations',
    version: '1.1',
  },
  {
    input: 'Admin-Functional-Spec.md',
    output: 'Admin-Functional-Spec.pdf',
    docTitle: 'Functional Specification',
    docSubtitle: 'Salon Admin Portal — Business & Operations',
    version: '1.1',
    date: 'June 28, 2026',
  },
  {
    input: 'Super-Admin-Solutioning-Spec.md',
    output: 'Super-Admin-Solutioning-Spec.pdf',
    docTitle: 'Solutioning & Technical Architecture',
    docSubtitle: 'Super Admin Portal — Engineering & Implementation',
    version: '1.2',
  },
  {
    input: 'GlowTap-Pricing-Timeline.md',
    output: 'GlowTap-Pricing-Timeline.pdf',
    docTitle: 'Pricing & Timeline',
    docSubtitle: 'SDLC Delivery Plan — Design + Development Phases',
    version: '1.3',
    date: 'June 27, 2026',
  },
  {
    input: 'Super-Admin-Figma-Screen-Guide.md',
    output: 'Super-Admin-Figma-Screen-Guide.pdf',
    docTitle: 'Figma Screen Guide',
    plain: true,
  },
];

const logoSvg = fs.readFileSync(path.join(__dirname, '456.svg'), 'utf8');
const logoDataUri = `data:image/svg+xml;base64,${Buffer.from(logoSvg).toString('base64')}`;

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
      <strong>Date</strong> ${doc.date || 'May 31, 2026'} &nbsp;|&nbsp;
      <strong>Confidential</strong>
    </div>
  </div>
</div>
`;
}

function buildPdfConfig(doc) {
  const title = doc.docTitle || 'Document';
  const stylesheet = doc.plain
    ? path.join(__dirname, 'pdf-styles-plain.css')
    : path.join(__dirname, 'pdf-styles.css');

  return {
    stylesheet: [stylesheet],
    pdf_options: {
      format: 'A4',
      margin: doc.plain
        ? { top: '18mm', bottom: '16mm', left: '15mm', right: '15mm' }
        : { top: '22mm', bottom: '18mm', left: '15mm', right: '15mm' },
      printBackground: true,
      displayHeaderFooter: true,
      headerTemplate: doc.plain
        ? `<div style="width:100%;font-size:8px;padding:0 15mm;color:#666;text-align:center;">Super Admin — Figma Screen Inventory &amp; Design Guide</div>`
        : `
        <div style="width:100%;font-size:7px;padding:0 15mm;display:flex;justify-content:space-between;align-items:center;color:${BRAND.grey};">
          <span style="color:${BRAND.primary};font-weight:600;">${BRAND.name}</span>
          <span style="letter-spacing:1.5px;text-transform:uppercase;font-size:6px;color:${BRAND.accentPink};">${BRAND.tagline}</span>
          <span>${title}</span>
        </div>`,
      footerTemplate: doc.plain
        ? `<div style="width:100%;font-size:8px;padding:0 15mm;display:flex;justify-content:space-between;color:#888;"><span>June 27, 2026 · v1.0</span><span>Page <span class="pageNumber"></span> of <span class="totalPages"></span></span></div>`
        : `
        <div style="width:100%;font-size:7px;padding:0 15mm;display:flex;justify-content:space-between;align-items:center;color:${BRAND.grey};">
          <span>&copy; ${new Date().getFullYear()} ${BRAND.name}</span>
          <span>Page <span class="pageNumber"></span> of <span class="totalPages"></span></span>
          <span style="color:${BRAND.lavender};">Confidential</span>
        </div>`,
    },
  };
}

async function generate() {
  for (const doc of docs) {
    const inputPath = path.join(__dirname, doc.input);
    const outputPath = path.join(__dirname, doc.output);
    const rawMd = fs.readFileSync(inputPath, 'utf8');

    let fullMd;
    if (doc.plain) {
      fullMd = rawMd;
    } else {
      const bodyMd = rawMd.replace(/^# GlowTap[\s\S]*?^---\n/m, '');
      fullMd = buildCoverHtml(doc) + '\n\n' + bodyMd;
    }

    console.log(`Generating ${doc.output}...`);
    const pdf = await mdToPdf({ content: fullMd }, buildPdfConfig(doc));

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
