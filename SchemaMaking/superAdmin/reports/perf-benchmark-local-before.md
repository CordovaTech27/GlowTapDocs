# GlowTap Super Admin — Database Performance Benchmark Report

**Generated:** 4/8/2026, 2:11:50 am IST
**Engine:** Local PostgreSQL (GlowTap)
**Rounds per test:** 5 (after 1 warm-up)
**Methodology:** client-side wall clock (Node `perf_hooks`) + `EXPLAIN (ANALYZE, BUFFERS)`

---

## 1. Executive summary

| Metric | Value |
|--------|------:|
| Database size | 4397 MB |
| Perf organizations | 2,500 |
| Perf branches | 12,500 |
| Perf appointments | 25,00,000 |
| Perf EUT | 8,62,500 |
| Perf attendance rows | 25,00,000 |
| Perf employees | 1,00,000 |
| Benchmark tests | 26 |
| EXPLAIN ANALYZE profiles | 4 |
| Grade mix | EXCELLENT: 22 · ACCEPTABLE: 3 · SLOW: 1 |

### Slowest operations (by avg latency)

| Rank | Operation | Category | Avg (ms) | P95 (ms) | Grade |
|-----:|-----------|----------|--------:|---------:|-------|
| 1 | Cross-schema merchant payable vs appointments | analytics | 40444.84 | 42863.67 | SLOW |
| 2 | Platform-wide appointment status histogram | analytics | 2800.09 | 3228.4 | ACCEPTABLE |
| 3 | Top 20 branches by completed booking GMV | analytics | 1642.87 | 1858.97 | ACCEPTABLE |
| 4 | Appointment + service + specialist join | join | 140.6 | 201.61 | ACCEPTABLE |
| 5 | INSERT appointment (single row) | write | 2.52 | 2.91 | EXCELLENT |

---

## 2. Storage & schema footprint

| Schema | Tables | Size |
|--------|-------:|------|
| `appointments` | 4 | 2198.7 MB |
| `rms` | 18 | 1045.6 MB |
| `employee` | 9 | 850.0 MB |
| `review` | 7 | 123.6 MB |
| `services` | 4 | 82.6 MB |
| `tickets` | 9 | 60.3 MB |
| `public` | 8 | 13.1 MB |
| `admin_org` | 3 | 11.8 MB |
| `cms` | 4 | 0.5 MB |
| `subscription` | 2 | 0.2 MB |

### Hottest relations (by total size)

| Relation | Live rows (approx) | Size |
|----------|-------------------:|------|
| `appointments.appointments` | 24,97,362 | 1716 MB |
| `employee.attendance_records` | 24,87,809 | 698 MB |
| `rms.end_user_transactions` | 8,63,695 | 638 MB |
| `appointments.appointment_status_events` | 25,00,045 | 483 MB |
| `rms.merchant_ledger_entries` | 8,62,500 | 258 MB |
| `review.reviews` | 2,50,003 | 123 MB |
| `rms.salon_payout_items` | 4,37,500 | 102 MB |
| `employee.leave_balances` | 3,00,006 | 76 MB |
| `services.branch_services` | 1,25,012 | 46 MB |
| `employee.employees` | 1,00,002 | 43 MB |
| `services.branch_service_specialists` | 2,50,000 | 37 MB |
| `tickets.support_tickets` | 50,002 | 31 MB |
| `tickets.support_ticket_messages` | 1,34,003 | 29 MB |
| `employee.leave_requests` | 50,001 | 20 MB |
| `rms.invoices` | 30,002 | 13 MB |
| `employee.branch_leave_policies` | 37,506 | 11 MB |
| `public.branches` | 12,511 | 11 MB |
| `rms.payments` | 30,001 | 11 MB |
| `rms.invoice_line_items` | 30,002 | 8904 kB |
| `rms.invoice_payments` | 30,001 | 8584 kB |
| `admin_org.sub_admin_modules` | 40,015 | 6064 kB |
| `rms.salon_payouts` | 15,003 | 4680 kB |
| `admin_org.sub_admin_branches` | 17,505 | 3632 kB |
| `admin_org.sub_admins` | 5,004 | 2376 kB |
| `employee.leave_types` | 7,503 | 1800 kB |

---

## 3. Point lookups (GET by key / unique)

| Test | Rows | Min | Avg | P50 | P95 | P99 | Max | Grade |
|------|-----:|----:|----:|----:|----:|----:|----:|-------|
| GET organization by slug (unique) | 1 | 0.88 | **1.43** | 1.19 | 2.73 | 2.73 | 2.73 | EXCELLENT |
| GET appointment by booking_number (unique) | 1 | 0.35 | **0.48** | 0.48 | 0.59 | 0.59 | 0.59 | EXCELLENT |
| GET EUT by transaction_ref (unique) | 1 | 0.31 | **0.8** | 0.91 | 1.45 | 1.45 | 1.45 | EXCELLENT |
| GET employee by org + employee_number | 0 | 0.21 | **0.44** | 0.27 | 0.92 | 0.92 | 0.92 | EXCELLENT |

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
| List appointments for branch (30-day window) | 0 | 0.3 | **0.35** | 0.35 | 0.4 | 0.4 | 0.4 | EXCELLENT |
| Filter appointments by status + org | 0 | 0.26 | **0.3** | 0.27 | 0.39 | 0.39 | 0.39 | EXCELLENT |
| Attendance for employee (date range) | 0 | 0.63 | **0.81** | 0.82 | 0.91 | 0.91 | 0.91 | EXCELLENT |
| EUT success list for org (recent) | 0 | 0.26 | **0.51** | 0.35 | 1.17 | 1.17 | 1.17 | EXCELLENT |

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
| Appointment + service + specialist join | 0 | 60.66 | **140.6** | 181.14 | 201.61 | 201.61 | 201.61 | ACCEPTABLE |
| EUT + appointment + branch join | 0 | 0.92 | **1.07** | 1.1 | 1.12 | 1.12 | 1.12 | EXCELLENT |
| Branch services with specialist count | 1 | 0.57 | **0.95** | 1.15 | 1.18 | 1.18 | 1.18 | EXCELLENT |
| Invoice + line items + payment join | 0 | 0.58 | **0.8** | 0.65 | 1.16 | 1.16 | 1.16 | EXCELLENT |

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
| Org revenue rollup (EUT sum/count by day) | 0 | 0.4 | **0.45** | 0.41 | 0.53 | 0.53 | 0.53 | EXCELLENT |
| Platform-wide appointment status histogram | 5 | 2500.15 | **2800.09** | 2555.58 | 3228.4 | 3228.4 | 3228.4 | ACCEPTABLE |
| Top 20 branches by completed booking GMV | 20 | 1562.13 | **1642.87** | 1585.59 | 1858.97 | 1858.97 | 1858.97 | ACCEPTABLE |
| Specialist utilization (appt hours / specialist) | 0 | 0.4 | **0.45** | 0.45 | 0.51 | 0.51 | 0.51 | EXCELLENT |
| Attendance present-rate by branch (window) | 0 | 0.5 | **0.8** | 0.77 | 1.18 | 1.18 | 1.18 | EXCELLENT |
| Running GMV window (org appointments) | 0 | 0.22 | **0.24** | 0.23 | 0.28 | 0.28 | 0.28 | EXCELLENT |
| Cross-schema merchant payable vs appointments | 50 | 36640.05 | **40444.84** | 41208.72 | 42863.67 | 42863.67 | 42863.67 | SLOW |

<details><summary>SQL samples</summary>

**Org revenue rollup (EUT sum/count by day)**

```sql
SELECT date_trunc('day', occurred_at) AS day, COUNT(*)::int AS txns, SUM(gross_amount) AS gross, SUM(commission_amount) AS commission, SUM(net_to_salon) AS net FROM rms.end_user_transactions WHERE organization_id = $1 AND status = 'SUCCESS' GROUP BY 1 ORDER BY 1 DESC
```

**Platform-wide appointment status histogram**

```sql
SELECT status, COUNT(*)::int AS n, ROUND(AVG(gross_amount)::numeric, 2) AS avg_gross FROM appointments.appointments WHERE booking_number LIKE 'PERF-APT-%' GROUP BY status ORDER BY n DESC
```

**Top 20 branches by completed booking GMV**

```sql
SELECT b.name, o.slug AS org, COUNT(*)::int AS completed, SUM(a.gross_amount) AS gmv FROM appointments.appointments a JOIN branches b ON b.id = a.branch_id JOIN organizations o ON o.id = a.organization_id WHERE a.status = 'COMPLETED' AND a.booking_number LIKE 'PERF-APT-%' GROUP BY b.id, b.name, o.slug ORDER BY gmv DESC NULLS LAST LIMIT 20
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
SELECT o.slug, COUNT(DISTINCT a.id)::int AS appts, COUNT(DISTINCT e.id)::int AS euts, COALESCE(SUM(e.net_to_salon),0) AS payable_accrued FROM organizations o LEFT JOIN appointments.appointments a ON a.organization_id = o.id AND a.booking_number LIKE 'PERF-APT-%' LEFT JOIN rms.end_user_transactions e ON e.organization_id = o.id AND e.transaction_ref LIKE 'PERF-EUT-%' WHERE o.slug LIKE 'perf-org-00%' GROUP BY o.id, o.slug ORDER BY payable_accrued DESC LIMIT 50
```

</details>

---

## 7. Write path (INSERT / UPDATE / DELETE)

| Test | Rows | Min | Avg | P50 | P95 | P99 | Max | Grade |
|------|-----:|----:|----:|----:|----:|----:|----:|-------|
| INSERT appointment (single row) | 1 | 1.99 | **2.52** | 2.7 | 2.91 | 2.91 | 2.91 | EXCELLENT |
| UPDATE appointment status BOOKED→CONFIRMED | 0 | 0.34 | **0.46** | 0.35 | 0.77 | 0.77 | 0.77 | EXCELLENT |
| INSERT attendance row | 1 | 0.62 | **1.72** | 1.87 | 2.45 | 2.45 | 2.45 | EXCELLENT |
| UPDATE org merchant balances | 1 | 0.39 | **0.51** | 0.43 | 0.78 | 0.78 | 0.78 | EXCELLENT |
| DELETE bench appointments (cleanup slice) | 0 | 0.28 | **0.32** | 0.29 | 0.45 | 0.45 | 0.45 | EXCELLENT |

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
| Salon dashboard snapshot (multi-aggregate) | 1 | 0.72 | **1.39** | 1.51 | 1.96 | 1.96 | 1.96 | EXCELLENT |
| End-user booking history by end_user_ref | 20 | 0.37 | **0.46** | 0.43 | 0.68 | 0.68 | 0.68 | EXCELLENT |

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
| Branch appointments 45d | 0.269 | **0.063** | 203.42 | 0 | Limit |
| Org EUT daily rollup | 0.127 | **0.056** | 1306.03 | 0 | Sort |
| Top branches by GMV | 0.32 | **2482.096** | 161504.3 | 20 | Limit |
| Appointment+service+specialist | 0.447 | **56.766** | 10950.19 | 0 | Limit |

---

## 10. Grading rubric

| Grade | Point / range / join (avg) | Writes (avg) | Analytics (avg) |
|-------|---------------------------:|-------------:|----------------:|
| EXCELLENT | ≤ 10 ms | ≤ 20 ms | ≤ 200 ms |
| GOOD | ≤ 40 ms | ≤ 80 ms | ≤ 1 s |
| ACCEPTABLE | ≤ 150 ms | ≤ 300 ms | ≤ 3 s |
| SLOW | above | above | above |

> Local rubric (no network RTT). Measured against ~10M-row GlowTap load.

---

## 11. Recommendations

- **Appointment + service + specialist join** (ACCEPTABLE, avg 140.6 ms) — review indexes / reduce join width / paginate.
- **Platform-wide appointment status histogram** (ACCEPTABLE, avg 2800.09 ms) — review indexes / reduce join width / paginate.
- **Top 20 branches by completed booking GMV** (ACCEPTABLE, avg 1642.87 ms) — review indexes / reduce join width / paginate.
- **Cross-schema merchant payable vs appointments** (SLOW, avg 40444.84 ms) — review indexes / reduce join width / paginate.
- Keep `VACUUM ANALYZE` on large tables after bulk loads (appointments, attendance, EUT).
- Prefer keyset pagination over `OFFSET` for appointment/EUT lists at this scale.
- Local DB size: 4397 MB.

---

*Report generated by `scripts/run-perf-benchmark.js`*