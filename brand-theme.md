# GlowTap Document Brand Theme

Use this reference when creating or updating GlowTap documentation (PDFs, presentations, specs).

## Brand Identity

| Element | Value |
|---------|-------|
| **Brand Name** | GlowTap |
| **Tagline** | Tap. Book. Glow. |
| **Positioning** | Premium beauty-tech platform with a modern, mobile-first identity |

## Color Palette

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| **Primary** | Purple / Violet | `#6C3AED` | Headings, buttons, links, brand accents |
| **Primary Dark** | Deep Violet | `#5B21B6` | H2 headings, table headers text |
| **Primary Light** | Soft Violet | `#EDE9FE` | Table backgrounds, code highlights, blockquotes |
| **Accent** | Lavender | `#DDD6FE` | Borders, dividers, subtle highlights |
| **Accent** | Pink | `#F472B6` | Callouts, blockquote borders, code block accent |
| **Gradient** | Brand Gradient | `#6C3AED → #A78BFA → #F472B6` | Cover pages, hero sections |
| **Neutral** | White | `#FFFFFF` | Backgrounds, cover text |
| **Neutral** | Grey 100 | `#F3F4F6` | Alternate table rows, info bars |
| **Neutral** | Grey 200 | `#E5E7EB` | Borders, table lines |
| **Neutral** | Grey 400 | `#9CA3AF` | Footer text, metadata |
| **Neutral** | Charcoal | `#1F2937` | Code blocks, dark text |
| **Neutral** | Charcoal Soft | `#374151` | Body text |

## Typography

| Element | Font | Weight | Size (Print) |
|---------|------|--------|-------------|
| Brand name (cover) | Segoe UI / Inter | 700 | 42pt |
| Tagline (cover) | Segoe UI / Inter | 500 | 14pt, uppercase, letter-spacing 3px |
| H1 | Segoe UI / Inter | 700 | 22pt |
| H2 | Segoe UI / Inter | 600 | 16pt |
| Body | Segoe UI / Inter | 400 | 11pt |
| Code | Consolas | 400 | 9pt |

## Logo

- File: `456.svg` (primary — full wordmark + tagline)
- Legacy icon: `glowtap-logo.svg`
- Cover pages use `456.svg` at ~320px width

## Document Structure

1. **Cover page** — Gradient background, logo, brand name, tagline, document title
2. **Header** (every page) — GlowTap | Tagline | Document title
3. **Footer** (every page) — Copyright | Page X of Y | Confidential
4. **Body** — Primary purple headings, lavender/pink accents, charcoal body text

## Regenerating PDFs

```bash
cd c:\Code\GlowTap\Docs
node generate-pdfs.js
```

Stylesheet: `pdf-styles.css`  
Logo: `glowtap-logo.svg`
