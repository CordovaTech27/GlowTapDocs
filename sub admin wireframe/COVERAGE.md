# Sub Admin Wireframe Coverage

Mapped to `SubAdmin-Requirements.md` and Admin Functional Spec §4.1–4.16 / §5.5.

| Spec | Screen(s) | Status |
|---|---|---|
| §4.1 Auth | login.html, login-figma.html, login-disabled.html, forgot/reset/change-password.html | Done |
| §4.2 / Req §7 Dashboard | dashboard.html | Done — multi-salon KPIs, alerts, cards, quick actions, banners; no billing |
| §5.5 / Req §9 Org lock | dashboard-locked.html | Done — Suspended org, dimmed read-only |
| §4.4–4.5 Branches | branches.html, branch-profile.html | Done — assigned 4 only; no request-branch |
| §4.7 Employees | employees.html, employee-detail.html, employee-edit.html | Done — branch-scoped |
| §4.8 Leave | leave-holidays.html | Done — assigned only |
| §4.9 Attendance | attendance.html | Done — Mark In/Out + summary |
| §4.10–4.11 Services | services.html, service-edit.html, slot-config.html, availability-preview.html | Done |
| §4.12 Appointments | appointments.html, appointment-detail.html, booking-history.html | Done |
| §4.13 Transactions | transactions.html, transaction-detail.html | Done — **ON** for full coverage (overrides §8 sample OFF) |
| §4.14.2 Reports | reports.html, report-view.html | Done — branch-level only; no org section |
| §4.15 Support | support.html, ticket-detail.html | Done — own tickets; confirm/reopen |
| §5.5 Access denied | access-denied.html | Done |
| Organization Profile | — | N/A (never in nav) |
| Sub Admins | — | N/A (never in nav) |
| Change Plan / Request Branch | — | N/A → access-denied |

## Shell checklist

- [x] Sub Admin nav + Transactions + user card “4 assigned salons”
- [x] Active branch: All Assigned Salons + 4 assigned only
- [x] Main Admin leaks stripped (org / sub-admins / change-plan / request-branch)
- [x] Floating shell + horizontal card scroll on Dashboard / Branches / Appointments / Transactions
- [x] index.html + README.md updated for full screen list
