# GlowTap — Database Performance

**Generated:** 4/8/2026, 2:56:17 am IST
**Engine:** Neon Postgres (serverless)
**Rounds per test:** 5 (after 1 warm-up)
**Methodology:** client-side wall clock (Node `perf_hooks`) + `EXPLAIN (ANALYZE, BUFFERS)`

---

## 1. Executive summary

| Metric | Value |
|--------|------:|
| Database size | 463 MB / 512 MB |
| Perf organizations | 850 |
| Perf branches | 4,250 |
| Perf appointments | 1,70,000 |
| Perf EUT | 63,750 |
| Perf attendance rows | 2,72,000 |
| Perf employees | 34,000 |
| Benchmark tests | 26 |
| EXPLAIN ANALYZE profiles | 4 |
| Grade mix | GOOD: 18 · ACCEPTABLE: 1 · EXCELLENT: 7 |

### Slowest operations (by avg latency)

| Rank | Operation | Category | Avg (ms) | P95 (ms) | Grade |
|-----:|-----------|----------|--------:|---------:|-------|
| 1 | Platform-wide appointment status histogram | analytics | 250.44 | 401 | EXCELLENT |
| 2 | Top 20 branches by completed booking GMV | analytics | 186.08 | 246.86 | EXCELLENT |
| 3 | Cross-schema merchant payable vs appointments | analytics | 133.74 | 219.95 | EXCELLENT |
| 4 | GET EUT by transaction_ref (unique) | point_lookup | 111.53 | 134.7 | ACCEPTABLE |
| 5 | Running GMV window (org appointments) | analytics | 100.33 | 129.99 | EXCELLENT |

---

## 2. Storage & schema footprint

| Schema | Tables | Size |
|--------|-------:|------|
| `appointments` | 4 | 174.8 MB |
| `employee` | 9 | 123.8 MB |
| `rms` | 18 | 86.8 MB |
| `services` | 4 | 27.0 MB |
| `tickets` | 9 | 18.0 MB |
| `review` | 7 | 10.6 MB |
| `public` | 8 | 5.4 MB |
| `admin_org` | 3 | 4.3 MB |
| `cms` | 4 | 0.6 MB |
| `subscription` | 2 | 0.3 MB |

### Hottest relations (by total size)

| Relation | Live rows (approx) | Size |
|----------|-------------------:|------|
| `appointments.appointments` | 1,70,003 | 141 MB |
| `employee.attendance_records` | 2,72,002 | 76 MB |
| `rms.end_user_transactions` | 63,761 | 43 MB |
| `appointments.appointment_status_events` | 1,70,006 | 34 MB |
| `employee.leave_balances` | 1,02,006 | 22 MB |
| `rms.merchant_ledger_entries` | 63,763 | 19 MB |
| `employee.employees` | 34,002 | 14 MB |
| `services.branch_services` | 42,512 | 14 MB |
| `services.branch_service_specialists` | 85,001 | 13 MB |
| `tickets.support_tickets` | 17,002 | 10208 kB |
| `review.reviews` | 17,003 | 10176 kB |
| `rms.salon_payout_items` | 34,014 | 8072 kB |
| `tickets.support_ticket_messages` | 34,003 | 7528 kB |
| `employee.leave_requests` | 17,001 | 7424 kB |
| `public.branches` | 4,261 | 4232 kB |
| `rms.invoices` | 10,202 | 4120 kB |
| `employee.branch_leave_policies` | 12,756 | 4112 kB |
| `rms.payments` | 10,201 | 3568 kB |
| `rms.invoice_line_items` | 10,202 | 3008 kB |
| `rms.invoice_payments` | 10,201 | 2464 kB |
| `admin_org.sub_admin_modules` | 13,615 | 2136 kB |
| `rms.salon_payouts` | 5,103 | 1824 kB |
| `admin_org.sub_admin_branches` | 5,955 | 1328 kB |
| `admin_org.sub_admins` | 1,704 | 936 kB |
| `employee.leave_types` | 2,553 | 728 kB |

---

## 3. Point lookups (GET by key / unique)

| Test | Rows | Min | Avg | P50 | P95 | P99 | Max | Grade |
|------|-----:|----:|----:|----:|----:|----:|----:|-------|
| GET organization by slug (unique) | 1 | 83.37 | **89.22** | 86.27 | 97 | 97 | 97 | GOOD |
| GET appointment by booking_number (unique) | 1 | 90.16 | **97.34** | 94.37 | 110.71 | 110.71 | 110.71 | GOOD |
| GET EUT by transaction_ref (unique) | 1 | 85.8 | **111.53** | 121.2 | 134.7 | 134.7 | 134.7 | ACCEPTABLE |
| GET employee by org + employee_number | 0 | 89.55 | **93.49** | 94.48 | 95.36 | 95.36 | 95.36 | GOOD |

<details><summary>SQL samples</summary>

**GET organization by slug (unique)**

```sql
SELECT id, name, status, owner_email FROM organizations WHERE slug = $1
```

**GET appointment by booking_number (unique)**

```sql
SELECT id, status, starts_at, gross_amount FROM appointments.appointments WHERE booking_number = $1
```

**GET EUT by transaction_ref (unique)**

```sql
SELECT id, gross_amount, status, net_to_salon FROM rms.end_user_transactions WHERE transaction_ref = $1
```

**GET employee by org + employee_number**

```sql
SELECT id, full_name, status FROM employee.employees WHERE organization_id = $1 AND employee_number = $2
```

</details>

---

## 4. Range / filter scans

| Test | Rows | Min | Avg | P50 | P95 | P99 | Max | Grade |
|------|-----:|----:|----:|----:|----:|----:|----:|-------|
| List appointments for branch (30-day window) | 0 | 93.41 | **94.51** | 94.36 | 95.28 | 95.28 | 95.28 | GOOD |
| Filter appointments by status + org | 0 | 87.35 | **93.6** | 94.42 | 100.69 | 100.69 | 100.69 | GOOD |
| Attendance for employee (date range) | 0 | 85.75 | **92.81** | 93.97 | 95.71 | 95.71 | 95.71 | GOOD |
| EUT success list for org (recent) | 0 | 94.23 | **95.01** | 95.15 | 95.41 | 95.41 | 95.41 | GOOD |

<details><summary>SQL samples</summary>

**List appointments for branch (30-day window)**

```sql
SELECT id, booking_number, status, starts_at, gross_amount FROM appointments.appointments WHERE branch_id = $1 AND starts_at >= NOW() - INTERVAL '45 days' ORDER BY starts_at DESC LIMIT 50
```

**Filter appointments by status + org**

```sql
SELECT id, booking_number, starts_at FROM appointments.appointments WHERE organization_id = $1 AND status = 'COMPLETED' ORDER BY starts_at DESC LIMIT 100
```

**Attendance for employee (date range)**

```sql
SELECT attendance_date, status, check_in_at, check_out_at FROM employee.attendance_records WHERE employee_id = $1 ORDER BY attendance_date DESC LIMIT 30
```

**EUT success list for org (recent)**

```sql
SELECT transaction_ref, gross_amount, net_to_salon, occurred_at FROM rms.end_user_transactions WHERE organization_id = $1 AND status = 'SUCCESS' ORDER BY occurred_at DESC LIMIT 100
```

</details>

---

## 5. Multi-table joins

| Test | Rows | Min | Avg | P50 | P95 | P99 | Max | Grade |
|------|-----:|----:|----:|----:|----:|----:|----:|-------|
| Appointment + service + specialist join | 0 | 93.73 | **98.56** | 98.89 | 101.23 | 101.23 | 101.23 | GOOD |
| EUT + appointment + branch join | 0 | 91.87 | **96.2** | 94.2 | 102.67 | 102.67 | 102.67 | GOOD |
| Branch services with specialist count | 1 | 91.1 | **95.52** | 94.9 | 99.69 | 99.69 | 99.69 | GOOD |
| Invoice + line items + payment join | 0 | 97.04 | **99.42** | 99.88 | 100.83 | 100.83 | 100.83 | GOOD |

<details><summary>SQL samples</summary>

**Appointment + service + specialist join**

```sql
SELECT a.booking_number, a.status, a.starts_at, s.name AS service, e.full_name AS specialist, a.gross_amount FROM appointments.appointments a JOIN services.branch_services s ON s.id = a.branch_service_id LEFT JOIN employee.employees e ON e.id = a.specialist_id WHERE a.organization_id = $1 ORDER BY a.starts_at DESC LIMIT 50
```

**EUT + appointment + branch join**

```sql
SELECT e.transaction_ref, e.gross_amount, e.commission_amount, a.booking_number, b.name AS branch FROM rms.end_user_transactions e LEFT JOIN appointments.appointments a ON a.booking_number = e.booking_ref JOIN branches b ON b.id = e.branch_id WHERE e.organization_id = $1 ORDER BY e.occurred_at DESC LIMIT 50
```

**Branch services with specialist count**

```sql
SELECT s.name, s.price, s.duration_minutes, COUNT(ss.employee_id)::int AS specialists FROM services.branch_services s LEFT JOIN services.branch_service_specialists ss ON ss.branch_service_id = s.id WHERE s.branch_id = $1 AND s.status = 'ACTIVE' GROUP BY s.id, s.name, s.price, s.duration_minutes ORDER BY s.sort_order
```

**Invoice + line items + payment join**

```sql
SELECT i.invoice_number, i.total_amount, i.status, COUNT(ili.id)::int AS lines, COALESCE(SUM(ip.amount_applied),0) AS paid FROM rms.invoices i LEFT JOIN rms.invoice_line_items ili ON ili.invoice_id = i.id LEFT JOIN rms.invoice_payments ip ON ip.invoice_id = i.id WHERE i.organization_id = $1 GROUP BY i.id ORDER BY i.issue_date DESC
```

</details>

---

## 6. Aggregations & expensive analytics

| Test | Rows | Min | Avg | P50 | P95 | P99 | Max | Grade |
|------|-----:|----:|----:|----:|----:|----:|----:|-------|
| Org revenue rollup (EUT sum/count by day) | 0 | 88.04 | **94.59** | 95.86 | 98.51 | 98.51 | 98.51 | EXCELLENT |
| Platform-wide appointment status histogram | 5 | 189.54 | **250.44** | 199.14 | 401 | 401 | 401 | EXCELLENT |
| Top 20 branches by completed booking GMV | 20 | 169.02 | **186.08** | 171.56 | 246.86 | 246.86 | 246.86 | EXCELLENT |
| Specialist utilization (appt hours / specialist) | 0 | 89.31 | **94.75** | 95.11 | 99.71 | 99.71 | 99.71 | EXCELLENT |
| Attendance present-rate by branch (window) | 0 | 89.65 | **94.69** | 90.21 | 104.09 | 104.09 | 104.09 | EXCELLENT |
| Running GMV window (org appointments) | 0 | 86.77 | **100.33** | 94.38 | 129.99 | 129.99 | 129.99 | EXCELLENT |
| Cross-schema merchant payable vs appointments | 50 | 110.56 | **133.74** | 112.88 | 219.95 | 219.95 | 219.95 | EXCELLENT |

<details><summary>SQL samples</summary>

**Org revenue rollup (EUT sum/count by day)**

```sql
SELECT date_trunc('day', occurred_at) AS day, COUNT(*)::int AS txns, SUM(gross_amount) AS gross, SUM(commission_amount) AS commission, SUM(net_to_salon) AS net FROM rms.end_user_transactions WHERE organization_id = $1 AND status = 'SUCCESS' GROUP BY 1 ORDER BY 1 DESC
```

**Platform-wide appointment status histogram**

```sql
SELECT status, COUNT(*)::int AS n, ROUND(AVG(gross_amount)::numeric, 2) AS avg_gross FROM appointments.appointments WHERE booking_number >= 'PERF-APT-' AND booking_number < 'PERF-APT.' GROUP BY status ORDER BY n DESC
```

**Top 20 branches by completed booking GMV**

```sql
SELECT b.name, o.slug AS org, x.completed, x.gmv FROM ( SELECT branch_id, COUNT(*)::int AS completed, SUM(gross_amount) AS gmv FROM appointments.appointments WHERE status = 'COMPLETED' AND booking_number >= 'PERF-APT-' AND booking_number < 'PERF-APT.' GROUP BY branch_id ORDER BY gmv DESC NULLS LAST LIMIT 20 ) x JOIN branches b ON b.id = x.branch_id JOIN organizations o ON o.id = b.organization_id ORDER BY x.gmv DESC
```

**Specialist utilization (appt hours / specialist)**

```sql
SELECT e.full_name, e.employee_number, COUNT(*)::int AS bookings, SUM(a.service_duration_min)::int AS minutes, ROUND(AVG(a.gross_amount)::numeric, 2) AS avg_ticket FROM appointments.appointments a JOIN employee.employees e ON e.id = a.specialist_id WHERE a.organization_id = $1 AND a.status IN ('COMPLETED','CONFIRMED','NO_SHOW') GROUP BY e.id ORDER BY minutes DESC
```

**Attendance present-rate by branch (window)**

```sql
SELECT b.name, COUNT(*)::int AS records, COUNT(*) FILTER (WHERE ar.status = 'PRESENT')::int AS present, ROUND(100.0 * COUNT(*) FILTER (WHERE ar.status = 'PRESENT') / NULLIF(COUNT(*),0), 1) AS present_pct FROM employee.attendance_records ar JOIN branches b ON b.id = ar.branch_id WHERE ar.organization_id = $1 GROUP BY b.id, b.name ORDER BY present_pct DESC
```

**Running GMV window (org appointments)**

```sql
SELECT booking_number, starts_at, gross_amount, SUM(gross_amount) OVER (ORDER BY starts_at ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_gmv FROM appointments.appointments WHERE organization_id = $1 AND status = 'COMPLETED' ORDER BY starts_at LIMIT 200
```

**Cross-schema merchant payable vs appointments**

```sql
SELECT o.slug, COALESCE(ap.appts, 0)::int AS appts, COALESCE(eu.euts, 0)::int AS euts, COALESCE(eu.payable_accrued, 0) AS payable_accrued FROM organizations o LEFT JOIN LATERAL ( SELECT COUNT(*)::bigint AS appts FROM appointments.appointments a WHERE a.organization_id = o.id AND a.booking_number >= 'PERF-APT-' AND a.booking_number < 'PERF-APT.' ) ap ON TRUE LEFT JOIN LATERAL ( SELECT COUNT(*)::bigint AS euts, COALESCE(SUM(e.net_to_salon), 0) AS payable_accrued FROM rms.end_user_transactions e WH
```

</details>

---

## 7. Write path (INSERT / UPDATE / DELETE)

| Test | Rows | Min | Avg | P50 | P95 | P99 | Max | Grade |
|------|-----:|----:|----:|----:|----:|----:|----:|-------|
| INSERT appointment (single row) | 1 | 89.95 | **95.47** | 95.54 | 101.6 | 101.6 | 101.6 | GOOD |
| UPDATE appointment status BOOKED→CONFIRMED | 0 | 89.71 | **94.05** | 95.11 | 95.23 | 95.23 | 95.23 | GOOD |
| INSERT attendance row | 1 | 88.18 | **91.87** | 90.92 | 96.6 | 96.6 | 96.6 | GOOD |
| UPDATE org merchant balances | 1 | 89.64 | **94.27** | 92.76 | 99.33 | 99.33 | 99.33 | GOOD |
| DELETE bench appointments (cleanup slice) | 0 | 93.17 | **95.07** | 95.51 | 96.58 | 96.58 | 96.58 | GOOD |

<details><summary>SQL samples</summary>

**INSERT appointment (single row)**

```sql
INSERT INTO appointments.appointments ( booking_number, organization_id, branch_id, branch_service_id, specialist_id, end_user_ref, end_user_name, service_name, service_duration_min, starts_at, ends_at, status, source, list_price, discount_amount, gross_amount, payment_method, payment_status ) VALUES ( $1, $2, $3, $4, $5, 'EU-BENCH', 'Bench User', 'Bench Cut', 30, NOW() + ($6 || ' minutes')::interval, NOW() + (($6)::int + 30 || ' minutes')::interval, 'BOOKED', 'CONSUMER_APP', 499, 0, 499, 'ONLIN
```

**UPDATE appointment status BOOKED→CONFIRMED**

```sql
UPDATE appointments.appointments SET status = 'CONFIRMED', confirmed_at = NOW(), updated_at = NOW(), payment_status = 'PAID' WHERE organization_id = $1 AND booking_number LIKE 'PERF-BENCH-APT-%' AND status = 'BOOKED' RETURNING id
```

**INSERT attendance row**

```sql
INSERT INTO employee.attendance_records ( organization_id, branch_id, employee_id, attendance_date, check_in_at, check_out_at, status, source, marked_by_ref ) VALUES ( $1, $2, $3, CURRENT_DATE + ($4 || ' days')::interval, NOW(), NOW() + INTERVAL '8 hours', 'PRESENT', 'SYSTEM', 'perf-bench' ) ON CONFLICT (employee_id, attendance_date) DO UPDATE SET status = EXCLUDED.status, updated_at = NOW() RETURNING id
```

**UPDATE org merchant balances**

```sql
UPDATE rms.org_merchant_balances SET outstanding_amount = outstanding_amount + 10, pending_payout_amount = pending_payout_amount + 25, updated_at = NOW() WHERE organization_id = $1 RETURNING outstanding_amount, pending_payout_amount
```

**DELETE bench appointments (cleanup slice)**

```sql
DELETE FROM appointments.appointments WHERE organization_id = $1 AND booking_number LIKE 'PERF-BENCH-APT-%' AND status = 'CONFIRMED' RETURNING id
```

</details>

---

## 8. Mixed / application-style workloads

| Test | Rows | Min | Avg | P50 | P95 | P99 | Max | Grade |
|------|-----:|----:|----:|----:|----:|----:|----:|-------|
| Salon dashboard snapshot (multi-aggregate) | 1 | 91.38 | **99.5** | 96.91 | 116.21 | 116.21 | 116.21 | GOOD |
| End-user booking history by end_user_ref | 17 | 87.85 | **94.61** | 94.98 | 100.35 | 100.35 | 100.35 | GOOD |

<details><summary>SQL samples</summary>

**Salon dashboard snapshot (multi-aggregate)**

```sql
SELECT (SELECT COUNT(*) FROM appointments.appointments WHERE organization_id = $1 AND starts_at::date = CURRENT_DATE) AS todays_appts, (SELECT COUNT(*) FROM appointments.appointments WHERE organization_id = $1 AND status = 'COMPLETED') AS completed, (SELECT COALESCE(SUM(gross_amount),0) FROM rms.end_user_transactions WHERE organization_id = $1 AND status = 'SUCCESS') AS eut_gross, (SELECT COUNT(*) FROM employee.employees WHERE organization_id = $1 AND status = 'ACTIVE') AS active_staff, (SELECT 
```

**End-user booking history by end_user_ref**

```sql
SELECT booking_number, service_name, starts_at, status, gross_amount, payment_status FROM appointments.appointments WHERE end_user_ref = $1 ORDER BY starts_at DESC LIMIT 20
```

</details>

---

## 9. EXPLAIN ANALYZE profiles

Postgres planner cost + actual runtime (includes buffer hits). Useful for index / join tuning.

| Query | Planning (ms) | Execution (ms) | Total cost | Actual rows | Top node |
|-------|-------------:|---------------:|-----------:|------------:|----------|
| Branch appointments 45d | 0.136 | **0.042** | 158.15 | 0 | Limit |
| Org EUT daily rollup | 0.12 | **0.04** | 275.23 | 0 | Aggregate |
| Top branches by GMV | 15.869 | **65.641** | 11826.75 | 20 | Sort |
| Appointment+service+specialist | 5.645 | **0.05** | 854.59 | 0 | Limit |

---

## 10. Grading rubric

| Grade | Point / range / join (avg) | Writes (avg) | Analytics (avg) |
|-------|---------------------------:|-------------:|----------------:|
| EXCELLENT | ≤ 30 ms | ≤ 50 ms | ≤ 500 ms |
| GOOD | ≤ 100 ms | ≤ 200 ms | ≤ 2 s |
| ACCEPTABLE | ≤ 400 ms | ≤ 800 ms | ≤ 5 s |
| SLOW | above | above | above |

> Neon serverless may show higher first-hit latency (compute resume). Warm-up round is excluded from stats.

---

## 11. Recommendations

- **Applied (Round 3):** covering / composite indexes in `076_performance_indexes_round3.sql` (full on local; lite subset `076b` on Neon due to 512 MB cap).
- **Applied:** analytics SQL rewritten — prefix range predicates (`>= … AND < …`) + `LATERAL` aggregates for cross-schema rollups (avoids cartesian LEFT JOIN blow-up).
- **GET EUT by transaction_ref (unique)** (ACCEPTABLE, avg 111.53 ms) — review indexes / reduce join width / paginate.
- Keep `VACUUM ANALYZE` on large tables after bulk loads (appointments, attendance, EUT).
- Prefer keyset pagination over `OFFSET` for appointment/EUT lists at this scale.
- Monitor Neon storage (512 MB free tier); current DB ~463 MB.

---

*Report generated by `scripts/run-perf-benchmark.js`*