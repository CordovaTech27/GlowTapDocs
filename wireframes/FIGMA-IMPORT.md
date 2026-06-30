# Figma import — fix missing images

Use **`login-figma.html`** for Login (not `login.html`). Dashboard and Salon Approvals have no external images and should import as-is.

---

## Quick steps

1. **Keep the server running** (from `Docs` folder):
   ```bash
   npx serve wireframes
   ```
   Server URL: **http://localhost:3000**

2. In Figma → plugin **html.to.design** → **Import from URL**

3. Use these URLs **exactly** (not `file://`, not pasted HTML):

   | Screen | URL |
   |--------|-----|
   | Login | **http://localhost:3000/login.html?figma=1** |
   | Login (alias) | http://localhost:3000/login-figma.html → redirects to above |
   | Dashboard | **http://localhost:3000/dashboard.html?figma=1** |
   | Salon Approvals | **http://localhost:3000/salon-approvals.html?figma=1** |
   | Branch Approvals | **http://localhost:3000/branch-approvals.html?figma=1** |

   **`?figma=1`** locks pages to **1440×1024** and adds named scroll wrappers (`Main Scroll`, `Content Dashboard`, etc.) so html.to.design builds the right layer tree.

4. Before import, open the URL in **Chrome** and confirm layout + images.

5. In the plugin, enable **“Import images”** / **“Download assets”** if shown.

---

## Scroll regions — what imports automatically

HTML now includes Figma-mapped wrappers:

| HTML element | `data-figma-layer` | Purpose |
|--------------|-------------------|---------|
| `.app-screen` | `DASH-01` / `SAL-01` / `BRN-01` frame name | 1440×1024 screen |
| `.sidebar` | `SHELL-01 Sidebar` | Fixed 280px nav |
| `.app-main-scroll` | `Main Scroll` | Page scroll wrapper (1024px tall) |
| `.app-content` | `Content Dashboard` / `Content Salon` / `Content Branch` | Tall inner content |
| `.panel-scroll` | `Lead list Scroll` / `Request list Scroll` / `Review Scroll` | Nested scroll (salon + branch) |

**After import (usually automatic):** clipped frames with a taller child inside — correct structure for scroll.

**Still manual in Figma (one-time, ~10 seconds):** Prototype tab → select **`Main Scroll`** frame → **Overflow behavior → Vertical scrolling** → test in **Present**. html.to.design cannot set Figma prototype overflow from HTML.

If layer names match, search **`Main Scroll`** in Figma layers panel after import.

---

## Why `login.html` breaks in Figma

| Feature in login.html | Figma / html.to.design |
|----------------------|-------------------------|
| `filter: blur()` on images | Usually **not imported** — image layer empty |
| CSS `mask-image: url(assets/...)` | **Not supported** — torn paper / white panel missing |
| `mix-blend-mode`, `position: fixed` | Often dropped or flattened wrong |
| Relative `assets/...` when pasting HTML | Paths **don’t resolve** — must use live URL + server |
| `.webp` (wave-bg.webp) | Sometimes fails — PNG fallback in `login-figma.html` |
| Responsive frame shrinks in import iframe | Use **`login.html?figma=1`** for fixed 1440×900 |

`login.html?figma=1` is the **same page** as normal login — fixed canvas + img-based torn edge instead of CSS masks.

---

## If images still missing

### A. Import assets manually (fastest fallback)

Drag these into Figma from `wireframes/assets/`:

- `salon-bg.png` — login hero + blurred bg (add **Background blur** in Figma ~40–60)
- `torn-edge.png` — torn edge on login card
- `wave-bg.webp` — optional texture overlay (12% opacity, Screen blend)

### B. Use absolute image URLs

Edit `login-figma.html` and replace `src="assets/..."` with:

```
http://localhost:3000/assets/salon-bg.png
http://localhost:3000/assets/torn-edge.png
```

Re-import while `npx serve wireframes` is running.

### C. Try another plugin

- **Anima** — Import HTML
- **Wireframe Designer** — screenshot-based (less accurate)

### D. Screenshot fallback

1. Open http://localhost:3000/login-figma.html at **1440×900** (Chrome DevTools device toolbar).
2. Full-page screenshot → place in Figma → rebuild form on top as components.

---

## After import — cleanup in Figma

1. Find **`Main Scroll`** → Prototype → **Vertical scrolling** (if not already set).
2. Replace flat groups with **Auto layout** where helpful.
3. Apply color styles from `Figma-Prototype-Build-Guide.md`.
4. Name top frame **DASH-01** / **SAL-01** / **BRN-01** if the plugin flattened `data-figma-frame` names.
5. Prototype: **Log in** → Dashboard frame.

**Re-import?** Only if you changed HTML and want a fresh import — otherwise rename frames + enable scroll on existing import.
