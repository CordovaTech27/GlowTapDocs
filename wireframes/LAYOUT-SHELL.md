# Super Admin — Shell Layout Spec



Same ratios and sizes as Salon Admin (`wireframes_admin/LAYOUT-SHELL.md`).

Source applied Jul 2026 across `wireframes/*.html` shell screens.



## Page frame



| Token | Value |

|---|---|

| App padding | `16px` |

| Panel gap | `16px` |

| Outer inset | `32px` |



## Sidebar panel



| Token | Value |

|---|---|

| Width | `280px` |

| Height | `calc(100vh - 32px)` |

| Sticky top | `16px` |

| Border | `1px solid var(--border)` |

| Border radius | `20px` |

| Overflow | `hidden` |

| Logo height | `100px` |



## Main content panel



| Token | Value |

|---|---|

| Height | `calc(100vh - 32px)` |

| Border | `1px solid var(--border)` |

| Border radius | `20px` |

| Overflow | `y: auto` |

| Content padding | `28px` |



## Page hero



| Token | Value |

|---|---|

| Min height | `100px` (aligns with logo strip) |

| Padding | `18px 28px` |

| Border bottom | `1px solid #E2E8F0` |

| Overflow | `visible` (Active org dropdown must not clip) |

| Page head | `align-items: center`, gap `20px` |

| Title | `1.65rem` / Outfit / line-height `1.2` |

| Actions | gap `12px`, button height `40px`, `align-items: flex-end` |



## Horizontal card scroll (parity with Admin Branches)



When a row has more cards than fit (~4 visible), use **left/right scroll** — do not shrink cards.



| Token | Value |

|---|---|

| Class | `.cards-scroll` |

| Layout | `display: flex`, gap `16px`, `overflow-x: auto` |

| Card width | `min-width: 220px`, about 4 visible (`calc((100% - 48px) / 4)`) |

| Snap | `scroll-snap-type: x mandatory` |



Used on:



- Dashboard — Operation Alerts, Key Metrics, Organizations

- Subscriptions — top metric strip



## Active org (parity with Admin Active branch)



| Rule | Behavior |

|---|---|

| Control | Hero **Active org** multi-select |

| Default | **All Orgs** |

| Multi-select | One or more organizations |

| Persistence | `localStorage` key `glowtap.orgScope` |

| Effect | Lists / org cards / tagged rows show only selected orgs |



Assets: `assets/org-scope.js`, `assets/org-scope-filter.js`



## Hover tips



`assets/hover-tips.css` + `assets/hover-tips.js` on every shell page (nav + Active org).



## Figma export



| Token | Value |

|---|---|

| Frame | `1440×1024` |

| Padding/gap | `0` |

| Flat sidebar/main (no floating radius) | yes |



## Applies to



All Super Admin shell pages under `wireframes/` (Dashboard, All Salons, Approvals, Subscriptions, Transactions, Support, Reports, Analytics, CMS, Master Config, Notifications, Audit, User Access).



## Excluded



- `login.html`, `login-figma.html`


