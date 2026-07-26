# Active Branch (Branch Scope) — Behavior

Controls **what data each screen shows**. It is a **filter for the current page**, not a navigation change.

## Purpose

| Selection | What the screen shows |
|---|---|
| **All Salons** (default) | Aggregated / combined data for **every** salon (branch) under the org |
| **One salon** | Only that salon’s data (employees, appointments, services, KPIs, etc.) |
| **Multiple salons** | Combined data for **only** the checked salons |

## Applies on every operational screen

The same Active branch selection filters **all** branch-scoped screens (not only Dashboard). Selection persists in `localStorage`, so choosing salons on Dashboard carries to Employees, Appointments, etc.

| Screen | What filters |
|---|---|
| **Dashboard** (+ locked / sub-admin) | KPIs recalculate for selected salons; **Branches** cards hide others; Today / tickets scoped |
| **Branches** | Table rows for selected salons only |
| **Employees / Leave / Attendance** | Staff / leave / attendance rows for selected salons |
| **Services / Slots / Availability** | Catalog & config rows for selected salons |
| **Appointments / History / Detail** | Bookings for selected salons |
| **Transactions / Support / Reports** | Rows / tickets linked to selected salons (org-wide tickets stay visible) |

### Example

1. On any screen, open **Active branch** → check **Bandra West** and **Koramangala**.
2. Lists and cards show **only** those two salons’ data (combined).
3. Banner: “Showing data for: Bandra West, Koramangala…”
4. Switch to **All Salons** → full org data returns.

Implementation: `assets/branch-scope.js` (picker) + `assets/branch-scope-filter.js` (hides/shows `[data-branch]` rows/cards).

## Rules

1. **Default on load:** `All Salons` is selected (all org salon data).
2. **Multi-select:** User can check one or more individual salons.
3. **All Salons vs individuals:**
   - Checking **All Salons** clears individual checks and shows everything.
   - Checking any individual salon turns **All Salons** off.
   - If the user clears the last individual salon, selection snaps back to **All Salons**.
4. **Persistence:** Selection is stored in `localStorage` (`glowtap.branchScope`) and restored on other shell screens until changed.
5. **Label in UI:** Still titled **Active branch** (product wording). Trigger text shows:
   - `All Salons`
   - or one salon name
   - or `N salons` when multiple are checked

## Where it appears

Operational / list screens that are branch-scoped, e.g.:

- Dashboard
- Branches, Branch Profile
- Employees, Leave, Attendance
- Services (+ slot / availability)
- Appointments (+ detail / history)
- Transactions, Reports, Support

## Overflow when many salons

Card size stays the same. Lists do **not** shrink to fit.

| Surface | Scroll |
|---|---|
| Dashboard **Branches** / **Assigned salons** row | Horizontal scroll. Fixed card width (~220–280px); ~3–4 visible; more salons scroll |
| **Active branch** dropdown | Vertical scroll inside the salon list (`max-height` ~240px). **All Salons** stays pinned above |
| Sub Admin **Branch access** (Admin create/edit) | Vertical 1-col scroll list (`.branch-access-list`) — scales to N |
| Report **Branches** filter | Compact multi-select dropdown with scrollable checklist (`.branch-multi`) |

## Where it does **not** appear

Org-level modules (no branch filter):

- Organization Profile
- Change Plan
- Sub Admins / Sub Admin edit
- Auth / password screens

## Main Admin vs Sub Admin

| Role | Options in the control |
|---|---|
| Main Admin | **All Salons** + every branch in the org |
| Sub Admin | **All assigned** (same UX as All Salons) + only branches assigned to that Sub Admin |

## Product note

This replaces the older “pick exactly one active branch” model in the wireframes. Spec copy in `Admin-Functional-Spec.md` §4.2 should match: scope may be **all**, **one**, or **many** salons; default is **all**.
