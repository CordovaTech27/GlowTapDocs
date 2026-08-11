# GlowTap — Database Performance

**Generated:** 4/8/2026, 3:11:58 am IST
**Engine:** Local PostgreSQL (GlowTap)
**Rounds per test:** 5 (after 1 warm-up)
**Methodology:** client-side wall clock (Node `perf_hooks`) + `EXPLAIN (ANALYZE, BUFFERS)`

---

## 1. Test environment

### Host machine (Postgres + benchmark client)

| Metric | Value |
|--------|-------|
| Hostname | LAPTOP-0VLFL1GO |
| OS | Windows_NT 10.0.19045 (x64) |
| CPU | Intel(R) Core(TM) i5-9300H CPU @ 2.40GHz |
| Logical cores | 8 |
| CPU clock (avg) | 2400 MHz |
| RAM | 7.9 GB total / 1.8 GB free |
| Node.js | v24.15.0 |

### PostgreSQL settings

| Metric | Value |
|--------|-------|
| Target | local |
| Database | GlowTap |
| Version | 18.4 |
| shared_buffers | 128 MB |
| work_mem | 64 MB |
| effective_cache_size | 4096 MB |
| max_parallel_workers | 8 |
| max_parallel_workers_per_gather | 4 |
| max_connections | 100 |

> Local Postgres — CPU/RAM below are from this machine (client and DB host).

---

## 2. Dataset under test

| Metric | Value |
|--------|------:|
| Database size | 5472 MB |
| Approx. live rows (tracked schemas) | 1,11,58,912 |
| PERF seed row sum (listed below) | 86,02,500 |
| Perf organizations | 2,500 |
| Perf branches | 12,500 |
| Perf appointments | 25,00,000 |
| Perf status events | 25,00,000 |
| Perf EUT | 8,62,500 |
| Perf attendance rows | 25,00,000 |
| Perf employees | 1,00,000 |
| Perf branch services | 1,25,000 |
| Benchmark tests | 26 |
| EXPLAIN ANALYZE profiles | 4 |
| Grade mix | EXCELLENT: 25 · GOOD: 1 |

### Slowest operations (by avg latency)

| Rank | Operation | Category | Avg (ms) | P95 (ms) | Grade |
|-----:|-----------|----------|--------:|---------:|-------|
| 1 | Platform-wide appointment status histogram | analytics | 504.36 | 558.17 | GOOD |
| 2 | Top 20 branches by completed booking GMV | analytics | 188.4 | 269.82 | EXCELLENT |
| 3 | Cross-schema merchant payable vs appointments | analytics | 100.66 | 101.48 | EXCELLENT |
| 4 | Specialist utilization (appt hours / specialist) | analytics | 5.22 | 6.34 | EXCELLENT |
| 5 | Attendance present-rate by branch (window) | analytics | 3.64 | 5.18 | EXCELLENT |

---

## 3. Storage & schema footprint

| Schema | Tables | Size |
|--------|-------:|------|
| `appointments` | 4 | 3224.9 MB |
| `rms` | 18 | 1094.2 MB |
| `employee` | 9 | 850.0 MB |
| `review` | 7 | 123.6 MB |
| `services` | 4 | 82.6 MB |
| `tickets` | 9 | 60.3 MB |
| `public` | 8 | 13.2 MB |
| `admin_org` | 3 | 11.8 MB |
| `cms` | 4 | 0.5 MB |
| `subscription` | 2 | 0.2 MB |

### Hottest relations (by total size)

| Relation | Live rows (approx) | Size |
|----------|-------------------:|------|
| `appointments.appointments` | 24,84,835 | 2742 MB |
| `employee.attendance_records` | 24,87,809 | 698 MB |
| `rms.end_user_transactions` | 8,64,394 | 687 MB |
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

## 4. Point lookups (GET by key / unique)

| Test | Rows | Min | Avg | P50 | P95 | P99 | Max | Grade |
|------|-----:|----:|----:|----:|----:|----:|----:|-------|
| GET organization by slug (unique) | 1 | 0.92 | **1.12** | 1.03 | 1.63 | 1.63 | 1.63 | EXCELLENT |
| GET appointment by booking_number (unique) | 1 | 1.34 | **1.73** | 1.44 | 2.39 | 2.39 | 2.39 | EXCELLENT |
| GET EUT by transaction_ref (unique) | 1 | 0.91 | **1.07** | 1.06 | 1.29 | 1.29 | 1.29 | EXCELLENT |
| GET employee by org + employee_number | 0 | 0.92 | **1.3** | 1.27 | 1.97 | 1.97 | 1.97 | EXCELLENT |

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

## 5. Range / filter scans

| Test | Rows | Min | Avg | P50 | P95 | P99 | Max | Grade |
|------|-----:|----:|----:|----:|----:|----:|----:|-------|
| List appointments for branch (30-day window) | 0 | 1.09 | **1.42** | 1.22 | 1.87 | 1.87 | 1.87 | EXCELLENT |
| Filter appointments by status + org | 0 | 1.15 | **1.33** | 1.19 | 1.63 | 1.63 | 1.63 | EXCELLENT |
| Attendance for employee (date range) | 0 | 0.89 | **1.28** | 1.49 | 1.55 | 1.55 | 1.55 | EXCELLENT |
| EUT success list for org (recent) | 0 | 1.07 | **1.49** | 1.3 | 2.01 | 2.01 | 2.01 | EXCELLENT |

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

## 6. Multi-table joins

| Test | Rows | Min | Avg | P50 | P95 | P99 | Max | Grade |
|------|-----:|----:|----:|----:|----:|----:|----:|-------|
| Appointment + service + specialist join | 0 | 1.81 | **2.7** | 2.64 | 3.73 | 3.73 | 3.73 | EXCELLENT |
| EUT + appointment + branch join | 0 | 1.66 | **1.78** | 1.82 | 1.89 | 1.89 | 1.89 | EXCELLENT |
| Branch services with specialist count | 1 | 0.53 | **0.73** | 0.71 | 0.91 | 0.91 | 0.91 | EXCELLENT |
| Invoice + line items + payment join | 0 | 0.54 | **0.67** | 0.6 | 1 | 1 | 1 | EXCELLENT |

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

## 7. Aggregations & expensive analytics

| Test | Rows | Min | Avg | P50 | P95 | P99 | Max | Grade |
|------|-----:|----:|----:|----:|----:|----:|----:|-------|
| Org revenue rollup (EUT sum/count by day) | 0 | 0.29 | **0.34** | 0.33 | 0.39 | 0.39 | 0.39 | EXCELLENT |
| Platform-wide appointment status histogram | 5 | 472.8 | **504.36** | 493.48 | 558.17 | 558.17 | 558.17 | GOOD |
| Top 20 branches by completed booking GMV | 20 | 158.44 | **188.4** | 170 | 269.82 | 269.82 | 269.82 | EXCELLENT |
| Specialist utilization (appt hours / specialist) | 0 | 3.51 | **5.22** | 5.18 | 6.34 | 6.34 | 6.34 | EXCELLENT |
| Attendance present-rate by branch (window) | 0 | 2.47 | **3.64** | 3.38 | 5.18 | 5.18 | 5.18 | EXCELLENT |
| Running GMV window (org appointments) | 0 | 0.68 | **1.55** | 1.41 | 2.71 | 2.71 | 2.71 | EXCELLENT |
| Cross-schema merchant payable vs appointments | 50 | 99.78 | **100.66** | 100.53 | 101.48 | 101.48 | 101.48 | EXCELLENT |

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

## 8. Write path (INSERT / UPDATE / DELETE)

| Test | Rows | Min | Avg | P50 | P95 | P99 | Max | Grade |
|------|-----:|----:|----:|----:|----:|----:|----:|-------|
| INSERT appointment (single row) | 1 | 1.88 | **2.48** | 2.31 | 3.67 | 3.67 | 3.67 | EXCELLENT |
| UPDATE appointment status BOOKED→CONFIRMED | 0 | 0.34 | **0.53** | 0.43 | 1.06 | 1.06 | 1.06 | EXCELLENT |
| INSERT attendance row | 1 | 0.66 | **2.65** | 2.54 | 4.29 | 4.29 | 4.29 | EXCELLENT |
| UPDATE org merchant balances | 1 | 0.42 | **0.46** | 0.45 | 0.54 | 0.54 | 0.54 | EXCELLENT |
| DELETE bench appointments (cleanup slice) | 0 | 0.33 | **0.41** | 0.37 | 0.57 | 0.57 | 0.57 | EXCELLENT |

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

## 9. Mixed / application-style workloads

| Test | Rows | Min | Avg | P50 | P95 | P99 | Max | Grade |
|------|-----:|----:|----:|----:|----:|----:|----:|-------|
| Salon dashboard snapshot (multi-aggregate) | 1 | 1.03 | **2.05** | 2.28 | 2.49 | 2.49 | 2.49 | EXCELLENT |
| End-user booking history by end_user_ref | 20 | 0.51 | **0.59** | 0.55 | 0.73 | 0.73 | 0.73 | EXCELLENT |

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

## 10. EXPLAIN ANALYZE profiles

Postgres planner cost + actual runtime (includes buffer hits). Useful for index / join tuning.

| Query | Planning (ms) | Execution (ms) | Total cost | Actual rows | Top node |
|-------|-------------:|---------------:|-----------:|------------:|----------|
| Branch appointments 45d | 0.298 | **0.054** | 203.44 | 0 | Limit |
| Org EUT daily rollup | 0.624 | **0.134** | 1306.03 | 0 | Sort |
| Top branches by GMV | 0.821 | **267.941** | 43725.77 | 20 | Sort |
| Appointment+service+specialist | 2.127 | **0.103** | 812.77 | 0 | Limit |

---

## 11. Grading rubric

| Grade | Point / range / join (avg) | Writes (avg) | Analytics (avg) |
|-------|---------------------------:|-------------:|----------------:|
| EXCELLENT | ≤ 10 ms | ≤ 20 ms | ≤ 200 ms |
| GOOD | ≤ 40 ms | ≤ 80 ms | ≤ 1 s |
| ACCEPTABLE | ≤ 150 ms | ≤ 300 ms | ≤ 3 s |
| SLOW | above | above | above |

> Local rubric (no network RTT). Measured against ~10M-row GlowTap load.

---

## 12. Recommendations

- **Applied (Round 3):** covering / composite indexes in `076_performance_indexes_round3.sql` (full on local; lite subset `076b` on Neon due to 512 MB cap).
- **Applied:** analytics SQL rewritten — prefix range predicates (`>= … AND < …`) + `LATERAL` aggregates for cross-schema rollups (avoids cartesian LEFT JOIN blow-up).
- No SLOW/ACCEPTABLE grades under current thresholds; re-run after schema growth or with higher concurrency.
- Keep `VACUUM ANALYZE` on large tables after bulk loads (appointments, attendance, EUT).
- Prefer keyset pagination over `OFFSET` for appointment/EUT lists at this scale.
- Local DB size: 5472 MB.

---

*Report generated by `scripts/run-perf-benchmark.js`*