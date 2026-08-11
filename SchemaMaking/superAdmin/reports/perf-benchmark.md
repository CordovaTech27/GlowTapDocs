# GlowTap — Database Performance

**Generated:** 4/8/2026, 3:13:15 am IST
**Engine:** Neon Postgres (serverless)
**Rounds per test:** 5 (after 1 warm-up)
**Methodology:** client-side wall clock (Node `perf_hooks`) + `EXPLAIN (ANALYZE, BUFFERS)`

---

## 1. Test environment

### Neon compute (database host)

| Metric | Value |
|--------|-------|
| Provider | Neon Postgres (serverless) |
| Region | ap-southeast-1 |
| Project ID | little-feather-12343290 |
| Endpoint ID | ep-lively-shadow-ao184du5 |
| Host | ep-lively-shadow-ao184du5-pooler.c-2.ap-southeast-1.aws.neon.tech |
| Estimated compute | ~0.25 CU |
| Estimated RAM | ~1 GB |
| Local file cache (LFC) | ~0.75 GB |
| Allocated CPUs (num_cpus) | 1 |
| Estimate basis | shared_buffers ≈ 230 MB |

> Laptop/client CPU is **not** listed — timings are Neon compute + WAN RTT from the runner.

### PostgreSQL settings

| Metric | Value |
|--------|-------|
| Target | neon |
| Database | superAdmin |
| Version | 18.4 (df16b3c) |
| shared_buffers | 230 MB |
| work_mem | 4096 kB |
| effective_cache_size | 6553 MB |
| max_parallel_workers | 8 |
| max_parallel_workers_per_gather | 2 |
| max_connections | 901 |

> Hardware metrics are Neon compute (not the laptop that ran Node). num_cpus()=1 (fractional CUs may round up). Wall-clock timings still include client↔Neon WAN RTT.

---

## 2. Dataset under test

| Metric | Value |
|--------|------:|
| Database size | 463 MB / 512 MB free-tier cap |
| Approx. live rows (tracked schemas) | 12,11,629 |
| PERF seed row sum (listed below) | 7,57,350 |
| Perf organizations | 850 |
| Perf branches | 4,250 |
| Perf appointments | 1,70,000 |
| Perf status events | 1,70,000 |
| Perf EUT | 63,750 |
| Perf attendance rows | 2,72,000 |
| Perf employees | 34,000 |
| Perf branch services | 42,500 |
| Benchmark tests | 26 |
| EXPLAIN ANALYZE profiles | 4 |
| Grade mix | ACCEPTABLE: 14 · EXCELLENT: 7 · GOOD: 5 |

### Slowest operations (by avg latency)

| Rank | Operation | Category | Avg (ms) | P95 (ms) | Grade |
|-----:|-----------|----------|--------:|---------:|-------|
| 1 | Top 20 branches by completed booking GMV | analytics | 203.89 | 277.58 | EXCELLENT |
| 2 | Platform-wide appointment status histogram | analytics | 199.59 | 205.91 | EXCELLENT |
| 3 | Cross-schema merchant payable vs appointments | analytics | 159.99 | 249.55 | EXCELLENT |
| 4 | End-user booking history by end_user_ref | mixed | 132.96 | 164.91 | ACCEPTABLE |
| 5 | INSERT attendance row | write | 125.97 | 136.44 | GOOD |

---

## 3. Storage & schema footprint

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

## 4. Point lookups (GET by key / unique)

| Test | Rows | Min | Avg | P50 | P95 | P99 | Max | Grade |
|------|-----:|----:|----:|----:|----:|----:|----:|-------|
| GET organization by slug (unique) | 1 | 99.76 | **103.95** | 100.4 | 114.34 | 114.34 | 114.34 | ACCEPTABLE |
| GET appointment by booking_number (unique) | 1 | 118.64 | **122.72** | 120.66 | 133.57 | 133.57 | 133.57 | ACCEPTABLE |
| GET EUT by transaction_ref (unique) | 1 | 89.84 | **115.14** | 119.29 | 135.2 | 135.2 | 135.2 | ACCEPTABLE |
| GET employee by org + employee_number | 0 | 97.53 | **107.93** | 102.01 | 132.17 | 132.17 | 132.17 | ACCEPTABLE |

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
| List appointments for branch (30-day window) | 0 | 99.97 | **115.24** | 115.62 | 141.05 | 141.05 | 141.05 | ACCEPTABLE |
| Filter appointments by status + org | 0 | 109.62 | **119.78** | 120.77 | 130.28 | 130.28 | 130.28 | ACCEPTABLE |
| Attendance for employee (date range) | 0 | 99.64 | **111.81** | 109.99 | 130.5 | 130.5 | 130.5 | ACCEPTABLE |
| EUT success list for org (recent) | 0 | 99.58 | **114.1** | 110.35 | 139.99 | 139.99 | 139.99 | ACCEPTABLE |

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
| Appointment + service + specialist join | 0 | 109.63 | **118.02** | 110.72 | 130.76 | 130.76 | 130.76 | ACCEPTABLE |
| EUT + appointment + branch join | 0 | 112.54 | **123.94** | 121.98 | 138.22 | 138.22 | 138.22 | ACCEPTABLE |
| Branch services with specialist count | 1 | 108 | **117.62** | 111.87 | 134.37 | 134.37 | 134.37 | ACCEPTABLE |
| Invoice + line items + payment join | 0 | 106.37 | **118.69** | 123.47 | 126.65 | 126.65 | 126.65 | ACCEPTABLE |

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
| Org revenue rollup (EUT sum/count by day) | 0 | 109.75 | **118.03** | 119.11 | 129.71 | 129.71 | 129.71 | EXCELLENT |
| Platform-wide appointment status histogram | 5 | 186.84 | **199.59** | 200.77 | 205.91 | 205.91 | 205.91 | EXCELLENT |
| Top 20 branches by completed booking GMV | 20 | 164.64 | **203.89** | 199.54 | 277.58 | 277.58 | 277.58 | EXCELLENT |
| Specialist utilization (appt hours / specialist) | 0 | 119.17 | **124.74** | 121.45 | 140.78 | 140.78 | 140.78 | EXCELLENT |
| Attendance present-rate by branch (window) | 0 | 99.87 | **114.92** | 108.94 | 140.24 | 140.24 | 140.24 | EXCELLENT |
| Running GMV window (org appointments) | 0 | 102.27 | **105.99** | 104.61 | 113.06 | 113.06 | 113.06 | EXCELLENT |
| Cross-schema merchant payable vs appointments | 50 | 129.96 | **159.99** | 139.48 | 249.55 | 249.55 | 249.55 | EXCELLENT |

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
| INSERT appointment (single row) | 1 | 111.07 | **119.29** | 119.59 | 128.46 | 128.46 | 128.46 | GOOD |
| UPDATE appointment status BOOKED→CONFIRMED | 0 | 93.12 | **118.37** | 126.92 | 133.68 | 133.68 | 133.68 | GOOD |
| INSERT attendance row | 1 | 119.9 | **125.97** | 122.63 | 136.44 | 136.44 | 136.44 | GOOD |
| UPDATE org merchant balances | 1 | 101.14 | **112.08** | 114.64 | 120.09 | 120.09 | 120.09 | GOOD |
| DELETE bench appointments (cleanup slice) | 0 | 99.71 | **113.38** | 110.07 | 125.05 | 125.05 | 125.05 | GOOD |

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
| Salon dashboard snapshot (multi-aggregate) | 1 | 98.47 | **103.64** | 99.91 | 120.36 | 120.36 | 120.36 | ACCEPTABLE |
| End-user booking history by end_user_ref | 17 | 119.49 | **132.96** | 125.37 | 164.91 | 164.91 | 164.91 | ACCEPTABLE |

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
| Branch appointments 45d | 0.135 | **0.055** | 158.15 | 0 | Limit |
| Org EUT daily rollup | 0.104 | **0.045** | 275.23 | 0 | Aggregate |
| Top branches by GMV | 16.332 | **57.437** | 11826.75 | 20 | Sort |
| Appointment+service+specialist | 5.673 | **0.049** | 854.59 | 0 | Limit |

---

## 11. Grading rubric

| Grade | Point / range / join (avg) | Writes (avg) | Analytics (avg) |
|-------|---------------------------:|-------------:|----------------:|
| EXCELLENT | ≤ 30 ms | ≤ 50 ms | ≤ 500 ms |
| GOOD | ≤ 100 ms | ≤ 200 ms | ≤ 2 s |
| ACCEPTABLE | ≤ 400 ms | ≤ 800 ms | ≤ 5 s |
| SLOW | above | above | above |

> Neon serverless may show higher first-hit latency (compute resume). Warm-up round is excluded from stats.

---

## 12. Recommendations

- **Applied (Round 3):** covering / composite indexes in `076_performance_indexes_round3.sql` (full on local; lite subset `076b` on Neon due to 512 MB cap).
- **Applied:** analytics SQL rewritten — prefix range predicates (`>= … AND < …`) + `LATERAL` aggregates for cross-schema rollups (avoids cartesian LEFT JOIN blow-up).
- **GET organization by slug (unique)** (ACCEPTABLE, avg 103.95 ms) — review indexes / reduce join width / paginate.
- **GET appointment by booking_number (unique)** (ACCEPTABLE, avg 122.72 ms) — review indexes / reduce join width / paginate.
- **GET EUT by transaction_ref (unique)** (ACCEPTABLE, avg 115.14 ms) — review indexes / reduce join width / paginate.
- **GET employee by org + employee_number** (ACCEPTABLE, avg 107.93 ms) — review indexes / reduce join width / paginate.
- **List appointments for branch (30-day window)** (ACCEPTABLE, avg 115.24 ms) — review indexes / reduce join width / paginate.
- **Filter appointments by status + org** (ACCEPTABLE, avg 119.78 ms) — review indexes / reduce join width / paginate.
- **Attendance for employee (date range)** (ACCEPTABLE, avg 111.81 ms) — review indexes / reduce join width / paginate.
- **EUT success list for org (recent)** (ACCEPTABLE, avg 114.1 ms) — review indexes / reduce join width / paginate.
- **Appointment + service + specialist join** (ACCEPTABLE, avg 118.02 ms) — review indexes / reduce join width / paginate.
- **EUT + appointment + branch join** (ACCEPTABLE, avg 123.94 ms) — review indexes / reduce join width / paginate.
- **Branch services with specialist count** (ACCEPTABLE, avg 117.62 ms) — review indexes / reduce join width / paginate.
- **Invoice + line items + payment join** (ACCEPTABLE, avg 118.69 ms) — review indexes / reduce join width / paginate.
- **Salon dashboard snapshot (multi-aggregate)** (ACCEPTABLE, avg 103.64 ms) — review indexes / reduce join width / paginate.
- **End-user booking history by end_user_ref** (ACCEPTABLE, avg 132.96 ms) — review indexes / reduce join width / paginate.
- Keep `VACUUM ANALYZE` on large tables after bulk loads (appointments, attendance, EUT).
- Prefer keyset pagination over `OFFSET` for appointment/EUT lists at this scale.
- Monitor Neon storage (512 MB free tier); current DB ~463 MB.

---

*Report generated by `scripts/run-perf-benchmark.js`*