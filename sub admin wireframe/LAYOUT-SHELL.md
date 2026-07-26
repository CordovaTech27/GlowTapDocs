# Salon Admin — Shell Layout Spec

Source of truth: `dashboard.html` (measured + applied Jul 2026).
Use these sizes on **every** shell screen (sidebar + main panel). Auth screens (`login*`, `forgot-password`, `reset-password`, `change-password`) are excluded.

## Page frame

| Token | Value | Notes |
|---|---|---|
| Viewport intent | full viewport | `min-height: 100vh` |
| App padding | `16px` | Space around floating panels |
| Panel gap | `16px` | Between sidebar and main |
| Outer inset total | `32px` | `16 + 16` vertical / horizontal |

## Sidebar panel

| Token | Value |
|---|---|
| Width | `280px` |
| Height | `calc(100vh - 32px)` |
| Sticky top | `16px` |
| Border | `1px solid var(--border)` |
| Border radius | `20px` |
| Overflow | `hidden` |
| Shadow | `4px 0 20px rgba(123, 0, 255, 0.025)` |
| Background | white → light purple gradient |

### Logo strip

| Token | Value |
|---|---|
| Height | `100px` (must match hero) |
| Width | `100%` of sidebar (`280px` image) |
| Divider | SVG bottom rule `#E2E8F0` at `y=100` |

### Nav

| Token | Value |
|---|---|
| Padding | `12px 10px` |
| Item padding | `10px 14px` |
| Item radius | `10px` |
| Item gap | `10px` |
| Icon size | `18×18` |
| Font size | `0.875rem` / weight `600` |
| Avatar | `36×36` |
| User card padding | `10px 12px` / radius `12px` |

## Main content panel

| Token | Value |
|---|---|
| Height | `calc(100vh - 32px)` |
| Border | `1px solid var(--border)` |
| Border radius | `20px` |
| Overflow | `y: auto`, `x: hidden` |
| Shadow | `0 4px 24px rgba(123, 0, 255, 0.04)` |
| Background | white → light purple gradient |

### Content padding

| Token | Value |
|---|---|
| `.app-content` padding | `28px` |
| Hero bleed | `margin: -28px -28px 28px` (full-bleed top of panel) |

## Page hero (`.dashboard-hero`)

Must align with sidebar logo divider.

| Token | Value |
|---|---|
| Height | `min-height: 100px` (auto grow; was fixed 100px which clipped Active branch) |
| Horizontal padding | `28px` |
| Vertical padding | `18px` |
| Border radius | `0` (parent panel clips top corners) |
| Bottom divider | `1px solid #E2E8F0` |
| Overflow | `visible` (so Active branch pill + dropdown are not cut off) |
| Display | flex / `align-items: center` |

**Alignment rule:** logo bottom and hero bottom share the same Y (`16px app pad + 100px`).

## Page head / actions

| Token | Value |
|---|---|
| `.page-head` | flex, `space-between`, `align-items: center`, gap `20px` |
| Title `h1` | `1.65rem` / weight `700` / line-height `1.2` / Outfit |
| `.page-actions` | flex, gap `12px`, `align-items: flex-end` |
| Action button height | `40px` |
| Branch switcher | column; label above select; gap `6px` |
| Branch select | height `40px`, min-width `220px`, pill radius |

## Cards / sections (shared)

| Token | Value |
|---|---|
| Card radius | `18px` |
| Card padding | `20px` |
| Section title size | `1.05rem` |
| Section title underline accent | `52×2` gradient bar |
| Grid gap | `16px` |

## Figma export override (`html.figma-export`)

| Token | Value |
|---|---|
| Frame | `1440×1024` |
| App padding / gap | `0` |
| Sidebar | `280×1024`, no radius, right border only |
| Main | `1160×1024`, no radius / border / shadow |

## Screens this layout applies to

All `wireframes_admin/*.html` that contain `.app-screen` + `.sidebar`, including:

- Dashboard variants
- Organization / Branches / Sub Admins / Employees
- Leave, Attendance, Services, Appointments
- Transactions, Reports, Support
- All detail / edit / request / history / preview screens under the shell

## Do not change

- Auth / password flows (no app shell)
- Module-specific content grids inside each page (only the chrome / shell)
