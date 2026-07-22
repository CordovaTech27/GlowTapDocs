from pathlib import Path
import re

p = Path(__file__).with_name("dashboard.html")
t = p.read_text(encoding="utf-8")

t = t.replace(
    "<title>GlowTap Super Admin — Dashboard</title>",
    "<title>GlowTap Salon Admin — Dashboard</title>",
)

ADMIN_CSS = r"""
    /* ── Salon Admin dashboard extras ── */
    .branch-switcher {
      display: flex;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
      margin-top: 14px;
    }

    .branch-switcher label {
      font-size: 0.72rem;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      color: var(--muted);
    }

    .branch-switcher select {
      appearance: none;
      padding: 9px 36px 9px 14px;
      border-radius: 999px;
      border: 1px solid rgba(123, 0, 255, 0.2);
      background: #fff url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%237B00FF' stroke-width='2.5'%3E%3Cpath d='m6 9 6 6 6-6'/%3E%3C/svg%3E") no-repeat right 14px center;
      font-family: inherit;
      font-size: 0.875rem;
      font-weight: 600;
      color: var(--purple-dark);
      min-width: 240px;
      cursor: pointer;
    }

    .promo-banner {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      flex-wrap: wrap;
      padding: 16px 20px;
      border-radius: 16px;
      background: var(--gradient-brand-soft);
      border: 1px solid rgba(123, 0, 255, 0.12);
      box-shadow: var(--shadow-card);
      margin-bottom: 24px;
    }

    .promo-banner strong {
      display: block;
      font-size: 0.95rem;
      color: var(--purple-dark);
      margin-bottom: 4px;
    }

    .promo-banner p {
      font-size: 0.82rem;
      color: var(--muted);
      margin: 0;
    }

    .branch-card {
      display: flex;
      flex-direction: column;
      gap: 14px;
      padding: 18px;
      border-radius: 18px;
      text-decoration: none;
      color: inherit;
      border: 1px solid var(--border);
      box-shadow: var(--shadow-card);
      transition: transform 0.15s, box-shadow 0.15s, border-color 0.15s;
      background: var(--gradient-surface-purple);
    }

    .branch-card:nth-child(4n+2) { background: var(--gradient-surface-pink); }
    .branch-card:nth-child(4n+3) { background: var(--gradient-surface-violet); }
    .branch-card:nth-child(4n+4) { background: var(--gradient-surface-lavender); }

    .branch-card:hover {
      transform: translateY(-2px);
      box-shadow: var(--shadow-card-hover);
      border-color: rgba(123, 0, 255, 0.22);
    }

    .branch-card.on {
      border-color: rgba(123, 0, 255, 0.35);
      box-shadow: var(--shadow-pill);
    }

    .branch-card-top {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 10px;
    }

    .branch-card h3 {
      font-size: 1rem;
      font-weight: 700;
      color: var(--text);
    }

    .branch-card .city {
      font-size: 0.78rem;
      color: var(--muted);
      margin-top: 4px;
    }

    .status-pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 10px;
      border-radius: 999px;
      font-size: 0.68rem;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.03em;
    }

    .status-pill::before {
      content: '';
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: currentColor;
    }

    .status-pill.active { background: #ECFDF5; color: #047857; }
    .status-pill.pending { background: #FFFBEB; color: #B45309; }
    .status-pill.suspended { background: #FEF2F2; color: #B91C1C; }

    .branch-stats {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 10px;
    }

    .branch-stat {
      padding: 10px 12px;
      border-radius: 12px;
      background: rgba(255, 255, 255, 0.72);
      border: 1px solid var(--border);
    }

    .branch-stat .s-label {
      font-size: 0.65rem;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      color: var(--muted);
    }

    .branch-stat .s-val {
      font-size: 1.05rem;
      font-weight: 700;
      margin-top: 4px;
      color: var(--text);
    }

    .quick-actions {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
    }

    .quick-actions .btn { text-decoration: none; }

    .screen-tag {
      display: inline-block;
      margin-left: 6px;
      padding: 2px 8px;
      border-radius: 6px;
      font-size: 0.68rem;
      font-weight: 700;
      color: var(--purple-dark);
      background: var(--surface-violet);
      border: 1px solid var(--border);
      vertical-align: middle;
    }

    .mb { margin-bottom: 28px; }

    .grid.g4 {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 16px;
    }

    .grid.g2 {
      display: grid;
      grid-template-columns: 1.2fr 1fr;
      gap: 16px;
    }

    @media (max-width: 1100px) {
      .grid.g4 { grid-template-columns: repeat(2, 1fr); }
      .grid.g2 { grid-template-columns: 1fr; }
    }

    @media (max-width: 640px) {
      .grid.g4 { grid-template-columns: 1fr; }
    }
"""

if "/* ── Salon Admin dashboard extras ── */" not in t:
    t = t.replace("</style>", ADMIN_CSS + "\n  </style>", 1)

BODY = Path(__file__).with_name("_dashboard_body.html").read_text(encoding="utf-8")

body_idx = t.find("<body>")
if body_idx == -1:
    raise SystemExit("no body")

head = t[:body_idx]
head = re.sub(
    r'\s*<script src="https://cdn\.jsdelivr\.net/npm/chart\.js[^"]*"[^>]*></script>\s*',
    "\n",
    head,
)

p.write_text(head + BODY.lstrip("\n"), encoding="utf-8")
print("Wrote", p, "bytes", p.stat().st_size)
