#!/usr/bin/env node
/**
 * GlowTap HTML → Figma capture CLI
 *
 * Usage:
 *   node bin/glowtap-h2f.js capture --all
 *   node bin/glowtap-h2f.js capture --portal subadmin
 *   node bin/glowtap-h2f.js capture --portal admin --include-auth
 *   node bin/glowtap-h2f.js gui
 */
const path = require('path');

async function main() {
  const args = process.argv.slice(2);
  const cmd = args[0] || 'help';

  function flag(name) {
    return args.includes(name);
  }
  function opt(name, fallback) {
    const i = args.indexOf(name);
    if (i >= 0 && args[i + 1]) return args[i + 1];
    return fallback;
  }

  if (cmd === 'help' || cmd === '--help' || cmd === '-h') {
    console.log(`
GlowTap HTML → Figma  (html.to.design-style capture + plugin import)

Commands:
  capture --all                 Capture Sub Admin + Admin + Super Admin
  capture --portal <id>         subadmin | admin | super
  capture --include-auth        Also capture login / password screens
  gui                           Open local GUI helper

Output:
  ../../figma-export/<portal>/*.gt2f.json
  ../../figma-export/<portal>/manifest.json
  ../../figma-export/<portal>/*.png

Next:
  1. Figma → Plugins → Development → Import plugin from manifest
     (tools/html-to-figma/figma-plugin/manifest.json)
  2. Run "GlowTap HTML to Figma" and load figma-export/<portal>/manifest.json
`);
    return;
  }

  if (cmd === 'gui') {
    require('../gui/server.js');
    return;
  }

  if (cmd === 'capture') {
    const { captureAll, capturePortal } = require('../src/capture-runner');
    const { resolvePortal, PORTALS } = require('../src/portals');
    const options = {
      includeAuth: flag('--include-auth'),
      width: Number(opt('--width', 1440)),
      height: Number(opt('--height', 900)),
      file: opt('--file', null),
    };

    if (flag('--all')) {
      const root = await captureAll(options);
      console.log('\nDone. Root manifest:', path.join(require('../src/portals').EXPORT_ROOT, 'manifest.json'));
      console.log(JSON.stringify(root.portals, null, 2));
      return;
    }

    const portalKey = opt('--portal', 'subadmin');
    const portal = resolvePortal(portalKey);
    if (!portal) {
      console.error('Unknown portal. Use: subadmin | admin | super');
      console.error('Available:', Object.keys(PORTALS).join(', '));
      process.exit(1);
    }
    console.log(`\n▶ Capturing ${portal.name}`);
    const result = await capturePortal(portal, options);
    console.log('\nDone:', result);
    return;
  }

  console.error('Unknown command:', cmd);
  process.exit(1);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
