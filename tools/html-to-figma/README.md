# GlowTap HTML → Figma

Batch tool that converts portal wireframe HTML into **editable Figma frames** with **Auto Layout**, **scroll regions**, and **prototype click links** — same architecture pattern as [html.to.design](https://html.to.design) (capture in a browser → design nodes in Figma).

> Proprietary `code.to.design` is closed. This tool implements the open pipeline: **Puppeteer DOM + computed styles → `.gt2f` pack → Figma plugin**.

## Folders → Figma pages

| Portal folder | CLI id | Figma page |
|---------------|--------|------------|
| `sub admin wireframe/` | `subadmin` | Sub Admin |
| `wireframes_admin/` | `admin` | Salon Admin |
| `wireframes/` | `super` | Super Admin |

## Requirements

- Node 18+
- Google Chrome installed (tool auto-detects Windows Chrome path), **or** set `PUPPETEER_EXECUTABLE_PATH`
- **Figma Desktop app** (browser Figma cannot load local Development plugins)

## Quick start

```bash
cd tools/html-to-figma
npm install

# Capture one portal (or --all)
npm run capture:subadmin

# Keep API/GUI up for the Figma plugin
npm run gui
```

If `npm run gui` says the port is busy: **that’s OK** — the GUI is already running. Open http://127.0.0.1:3847 in your browser.

---

## Connect to Figma (detailed)

Capture only creates JSON/PNG on disk. Figma receives the design when you run the **GlowTap plugin** inside a Figma file.

### A. One-time: install the local plugin

1. Install / open **[Figma Desktop](https://www.figma.com/downloads/)** (not only the browser tab).
2. Create or open any Design file (blank is fine).
3. Top menu: **Plugins → Development → Import plugin from manifest…**  
   *(If you don’t see Development: enable it under* **Figma → Preferences → Enable dev tools / local plugins** *depending on your Figma version, or use* **Plugins → Development** *after signing in.)*
4. Browse to this file and select it:

```
...\GlowTapDocs\tools\html-to-figma\figma-plugin\manifest.json
```

5. You should see **GlowTap HTML to Figma** under **Plugins → Development**.

Re-import the manifest only if you update `code.js` / `ui.html`.

### B. Every time: import Sub Admin (or another portal)

**Path 1 — Localhost (recommended)**

1. Capture finished (you already have `figma-export/subadmin/…`).
2. In a terminal:

```bash
cd tools/html-to-figma
npm run gui
```

3. Confirm in browser: http://127.0.0.1:3847 (status pills should say **Ready** for Sub Admin).
4. In Figma Desktop, open your file → **Plugins → Development → GlowTap HTML to Figma**.
5. In the plugin panel:
   - Select **Sub Admin**
   - Click **Import from localhost:3847**
   - Optional: check **Replace existing frames on page**
6. Wait until status shows Done (screens + prototype links).
7. On the canvas you get a page named **Sub Admin** with frames side by side.
8. Switch to **Prototype** mode (top right) to click hotspots / overlays.

**Path 2 — File drop (no GUI needed)**

1. In Figma: **Plugins → Development → GlowTap HTML to Figma**
2. Click the file picker in the plugin.
3. Choose:

```
...\GlowTapDocs\figma-export\subadmin\subadmin.gt2f-pack.json
```

4. Import runs the same way.

### C. What you should see

| In Figma | Meaning |
|----------|---------|
| Page **Sub Admin** | Portal page created/selected |
| Large frames (≈1440 wide) | Each HTML screen |
| Frames titled `Modal / …` | Confirm / Reschedule / Cancel etc. |
| Nearly invisible purple hotspots | Click targets for prototype |
| Prototype mode links | Navigate between screens / open overlays |

### D. Common issues

| Problem | Fix |
|---------|-----|
| `EADDRINUSE … 3847` | GUI already running → use http://127.0.0.1:3847 ; don’t start a second one |
| Plugin missing under Development | Use **Figma Desktop**, re-import `manifest.json` |
| Import fails / fetch error | Start `npm run gui`, or use **file drop** of `subadmin.gt2f-pack.json` |
| Empty / wrong layout | Re-run `npm run capture:subadmin`, then import again with **Replace** |
| No click prototype | Open **Prototype** tab (not Design only); hotspots are low-opacity |

### E. Admin / Super Admin later

```bash
npm run capture:admin
# or
node bin/glowtap-h2f.js capture --portal super
npm run gui
```

In the plugin, pick **Admin** or **Super**, then Import.

---

### Install plugin (short)

1. Open **Figma Desktop**
2. **Plugins → Development → Import plugin from manifest…**
3. Select `tools/html-to-figma/figma-plugin/manifest.json`

### Import into Figma (short)

**Option A — localhost**  
`npm run gui` → plugin → **Import from localhost:3847**

**Option B — file drop**  
Drop `figma-export/subadmin/subadmin.gt2f-pack.json` into the plugin.

Output is written to:

```
figma-export/
  subadmin/
    appointments.gt2f.json
    appointments.png
    subadmin.gt2f-pack.json
    manifest.json
  …
```

## CLI

```bash
node bin/glowtap-h2f.js capture --all
node bin/glowtap-h2f.js capture --portal admin
node bin/glowtap-h2f.js capture --portal super --include-auth
node bin/glowtap-h2f.js capture --portal subadmin --width 1440 --height 900
node bin/glowtap-h2f.js gui
```

## How it works (like html.to.design)

1. **Local static server** serves each portal folder  
2. **Puppeteer** opens `?figma=1` screens at 1440×900  
3. **Serializer** walks the DOM, reads `getComputedStyle` + geometry  
4. **Flex/grid → Auto Layout** (`layoutMode`, gap, padding, align)  
5. **Text / fills / radius / shadows / images** mapped to Figma node props  
6. **`data-figma-overflow`** → Figma overflow scrolling  
7. **Links** (`page.html`, `#modal-id`) → Prototype Navigate / Overlay  
8. **Figma plugin** rebuilds the tree on the canvas  

## Accuracy expectations

| Layer | Typical |
|-------|---------|
| Screen list + naming (`data-figma-frame`) | High |
| Shell / card structure + Auto Layout | High–medium |
| Visual polish (complex gradients, filters) | Medium |
| Prototype nav + modals | High |
| Live JS widgets (date picker open state) | Low (static) |

For pixel-perfect marketing pages, use html.to.design on a hosted URL. For **GlowTap admin wireframes + flows**, this tool is purpose-built.

## Root npm scripts

From repo root you can add:

```json
"h2f:capture": "npm --prefix tools/html-to-figma run capture",
"h2f:gui": "npm --prefix tools/html-to-figma run gui"
```

## Privacy

Capture runs **fully local**. The plugin only talks to `127.0.0.1` when you use localhost import. Nothing is uploaded.
