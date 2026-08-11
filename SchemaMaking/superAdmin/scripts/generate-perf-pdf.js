/**
 * Render GlowTap performance HTML report → PDF (charts included).
 *
 *   node scripts/generate-perf-pdf.js --local
 *   node scripts/generate-perf-pdf.js
 */
const fs = require('fs');
const path = require('path');
const puppeteer = require(path.join(__dirname, '..', '..', '..', 'node_modules', 'puppeteer'));

const IS_LOCAL = process.argv.includes('--local');
const OUT_DIR = path.join(__dirname, '..', 'reports');
const suffix = IS_LOCAL ? '-local' : '';
const htmlPath = path.join(OUT_DIR, `perf-benchmark${suffix}.html`);
const pdfPath = path.join(OUT_DIR, `perf-benchmark${suffix}.pdf`);

async function main() {
  if (!fs.existsSync(htmlPath)) {
    throw new Error(`Missing ${htmlPath} — run the benchmark (or --html-only) first`);
  }

  const fileUrl = 'file:///' + htmlPath.replace(/\\/g, '/');
  console.log(`Rendering PDF from ${path.basename(htmlPath)}...`);

  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--allow-file-access-from-files'],
  });

  try {
    const page = await browser.newPage();
    await page.setViewport({ width: 1400, height: 1800, deviceScaleFactor: 2 });
    await page.goto(fileUrl, { waitUntil: 'networkidle0', timeout: 120000 });

    // Wait for Chart.js canvases to paint
    await page.waitForFunction(
      () => {
        const canvases = [...document.querySelectorAll('canvas')];
        return canvases.length >= 4 && canvases.every((c) => c.width > 0 && c.height > 0);
      },
      { timeout: 30000 }
    );
    await new Promise((r) => setTimeout(r, 800));

    await page.pdf({
      path: pdfPath,
      format: 'A4',
      printBackground: true,
      preferCSSPageSize: false,
      margin: { top: '10mm', bottom: '12mm', left: '8mm', right: '8mm' },
      displayHeaderFooter: true,
      headerTemplate: `
        <div style="width:100%;font-size:8px;padding:0 10mm;color:#5c726a;font-family:sans-serif;
                    display:flex;justify-content:space-between;align-items:center;">
          <span style="color:#0f766e;font-weight:700;">GlowTap</span>
          <span>Database Performance</span>
        </div>`,
      footerTemplate: `
        <div style="width:100%;font-size:8px;padding:0 10mm;color:#5c726a;font-family:sans-serif;
                    display:flex;justify-content:space-between;align-items:center;">
          <span>Confidential</span>
          <span>Page <span class="pageNumber"></span> / <span class="totalPages"></span></span>
        </div>`,
    });

    console.log(`Wrote ${pdfPath}`);
  } finally {
    await browser.close();
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
