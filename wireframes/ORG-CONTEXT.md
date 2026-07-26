# Active Org (Org Scope) — Super Admin

Same idea as Salon Admin **Active branch**, but for **organizations**.

## Purpose

| Selection | What the screen shows |
|---|---|
| **All Orgs** (default) | Platform-wide / every organization |
| **One org** | Only that organization’s rows and cards |
| **Multiple orgs** | Combined data for only the checked orgs |

## Example

1. Open **Active org** → check **Serenity Spa** and **Blush Beauty**.
2. Dashboard **Organizations** row shows only those two cards (scroll left/right if more).
3. **All Salons** / **Transactions** / **Support** lists show only matching org rows.
4. Switch to **All Orgs** → full platform data returns.

## Rules

1. Default: All Orgs.
2. Multi-select supported.
3. Checking All Orgs clears individuals; checking any org turns All Orgs off.
4. Clearing the last org snaps back to All Orgs.
5. Persists in `localStorage` (`glowtap.orgScope`) across Super Admin shell screens.

## Where it appears

Dashboard, All Salons, Approvals, Subscriptions, Transactions, Support, Reports, Analytics.

## Horizontal overflow

Org / KPI / alert cards keep a fixed size (~220–280px). Extra cards scroll **left/right** (`.cards-scroll`) — same pattern as Admin branch cards.

**Active org** dropdown: vertical scroll inside the org list (`max-height` ~240px). Scales to N orgs.
