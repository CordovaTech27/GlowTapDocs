# Sub Admin Wireframes

HTML / CSS / JS wireframes for the **Salon Sub Admin** portal (no Python generators).

**Source of truth:** `../SubAdmin-Requirements.md` · Admin Functional Spec §§2, 2.1, **4.2**, 4.6, **5.5** · layout: [`LAYOUT-SHELL.md`](LAYOUT-SHELL.md) · branch filter: [`BRANCH-CONTEXT.md`](BRANCH-CONTEXT.md)

## Demo persona

| Field | Value |
|---|---|
| User | Riya Kapoor · `manager@luxecurls.in` |
| Role | Sub Admin |
| Assigned salons | **Bandra West, Koramangala, Juhu Wave, Indiranagar** |
| Modules ON | Branch Profile, Employees, Leave & Holidays, Attendance, Services, Appointments, **Transactions**, Reports |
| Always ON | Dashboard, Support, auth |
| Never in nav | Organization Profile, Sub Admins, Change Plan, Request Branch |

> Spec §8 sample had Transactions OFF; this wireframe set turns Transactions **ON** so list/detail screens are reachable. Org-only modules stay unreachable → [`access-denied.html`](access-denied.html).

## Start here

Open [`index.html`](index.html) or [`dashboard.html`](dashboard.html). Coverage checklist: [`COVERAGE.md`](COVERAGE.md).

## Shell rules

1. Nav shows only granted modules (+ Dashboard + Support).
2. **Active branch** defaults to **All Assigned Salons**; multi-select of the 4 assigned salons only (`assets/branch-scope.js` + `branch-scope-filter.js`).
3. Horizontal card scroll (`.branch-cards-scroll` / `.cards-scroll`) when rows overflow.
4. Floating shell tokens: `16px` pad, `280px` sidebar, `20px` radius, `calc(100vh - 32px)` — see [`LAYOUT-SHELL.md`](LAYOUT-SHELL.md).
5. Org Suspended demo: [`dashboard-locked.html`](dashboard-locked.html).

## Assets

Local copy under `./assets` (aligned with Main Admin wireframes).
