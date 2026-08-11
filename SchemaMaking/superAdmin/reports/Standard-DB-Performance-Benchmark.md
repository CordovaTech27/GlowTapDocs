# GlowTap — Standard Database Performance Benchmark

**Document type:** Industry reference (latency SLOs & test-data norms)  
**Audience:** Product / engineering / stakeholders  
**Date:** 6 August 2026  
**Scope:** OLTP SaaS databases (bookings, dashboards, writes) — *not* warehouse/BI-only workloads  

---

## 1. Purpose

This document defines **industry-typical** performance targets and **dataset sizes** used when bench­marking transactional Postgres-style applications (e.g. salon/booking platforms).

Use it to answer:

1. What latency range is considered **good**?
2. How much data should performance tests usually load?

---

## 2. Latency standards (what “good” means)

Times below are **end-to-end query / API latency** (includes network when remote). Prefer **p95** for product SLOs; **avg/p50** for developer benches.

### 2.1 By query type

| Workload | Excellent (local / same-region) | Good | Acceptable | Investigate |
|----------|--------------------------------:|-----:|-----------:|------------:|
| Point lookup (PK / unique key) | ≤ 5–10 ms | ≤ 20–40 ms | ≤ 100–150 ms | > 200–300 ms |
| Filtered list (paginated, indexed) | ≤ 20 ms | ≤ 50 ms | ≤ 150–200 ms | > 300–500 ms |
| Multi-table join (screen-sized) | ≤ 50 ms | ≤ 100 ms | ≤ 250–300 ms | > 500 ms |
| Single-row INSERT / UPDATE | ≤ 10–20 ms | ≤ 50–80 ms | ≤ 200–300 ms | > 500 ms |
| Analytics / platform rollup (interactive) | ≤ 200 ms | ≤ 1 s | ≤ 2–3 s | > 3–5 s |
| Analytics (batch / offline OK) | — | &lt; 30 s | &lt; 5 min | job design |

### 2.2 Product-level API SLOs (common industry practice)

| Metric | Typical target |
|--------|----------------|
| Interactive API **p50** | &lt; 100 ms |
| Interactive API **p95** | &lt; 200–300 ms |
| Interactive API **p99** | &lt; 500 ms – 1 s |
| User-blocking UI | Keep under ~2–3 s; else async / pagination |

### 2.3 Local vs remote (serverless) interpretation

| Environment | What the number mostly reflects | How to read it |
|-------------|----------------------------------|----------------|
| **Local Postgres** | Disk / CPU / planner / indexes | Treat **≤ 10–40 ms** lookups as strong |
| **Remote serverless (e.g. Neon)** | **WAN RTT + pooler +** DB work | Lookups often sit **~80–150 ms** even when the plan is fine |

A remote lookup of ~100 ms can be **healthy** if EXPLAIN shows index use and local equivalent is a few ms.  
A local lookup of ~100 ms on an indexed unique key usually means **missing index, cold disk, or bad plan**.

### 2.4 Thumb-rule “good range” (quick reference)

- **Lookups / lists / writes (local):** aim **under ~50 ms**; celebrate **under ~10–20 ms**  
- **Lookups (remote same-ish region):** aim **under ~100–150 ms**  
- **Dashboard aggregates (interactive):** aim **under ~200–500 ms**; move heavier work async  
- **Anything interactive over ~2–3 s:** redesign query, add index, or make it a background job  

---

## 3. Standard test-data volumes

Industry performance tests are only trustworthy when hot tables are large enough that **wrong plans hurt**.

### 3.1 Recommended dataset sizes

| Stage | Hot-table rows (approx.) | Overall DB | Use |
|-------|--------------------------|------------|-----|
| CI / smoke | 10K – 100K | &lt; 500 MB | Correctness + basic timings |
| **Engineering perf (standard)** | **1M – 10M+** on hottest tables | **~1–10 GB** | Index, join, pagination realism |
| Pre-prod / capacity | 10M – 100M+ or production clone | tens of GB+ | Peak load, degradation |
| Analytics / warehouse | Months–years of history | Separate store often | Reporting SLOs, not OLTP |

### 3.2 Content rules (not just row count)

1. **Skew:** some orgs/branches huge, some tiny (like production).  
2. **Indexes under load:** unique keys, `(org_id, status)`, date ranges, FKs used in joins.  
3. **Writes included:** INSERT / UPDATE / DELETE — not SELECT-only.  
4. **Warm-up + N rounds:** discard first run; report avg / p50 / p95 from measured rounds.  
5. **Separate environments:** local CPU baseline vs remote RTT-inclusive baseline — never mix grades blindly.

### 3.3 Rule of thumb

> If a full table scan of the hottest table would still finish in tens of ms, the dataset is **too small** for a serious OLTP perf claim.

Use at least **~1 million rows** on primary transactional tables (appointments, attendance, ledger, etc.) for release-grade perf statements.

---

## 4. Methodology checklist (industry-aligned)

| Step | Standard practice |
|------|-------------------|
| Warm-up | 1 discarded run (cache / cold start) |
| Measured rounds | 3–10 timed runs (5 is common) |
| Reported stats | min, avg, **p50**, **p95**, max |
| Grades | Band by workload type (lookup vs write vs analytics) |
| Environment note | CPU/RAM or compute CU, region, DB size, row counts |
| Plans | Spot-check with `EXPLAIN (ANALYZE, BUFFERS)` on outliers |
| Pass criteria | No interactive path in **Investigate** band on target env |

---

## 5. Grading bands used in GlowTap suite (aligned to §2)

These bands encode the industry ranges above for automated reports.

### Local PostgreSQL

| Grade | Lookups / joins | Writes | Analytics |
|-------|----------------:|-------:|----------:|
| EXCELLENT | ≤ 10 ms | ≤ 20 ms | ≤ 200 ms |
| GOOD | ≤ 40 ms | ≤ 80 ms | ≤ 1 s |
| ACCEPTABLE | ≤ 150 ms | ≤ 300 ms | ≤ 3 s |
| SLOW | above | above | above |

### Neon / remote serverless

| Grade | Lookups / joins | Writes | Analytics |
|-------|----------------:|-------:|----------:|
| EXCELLENT | ≤ 30 ms | ≤ 50 ms | ≤ 500 ms |
| GOOD | ≤ 100 ms | ≤ 200 ms | ≤ 2 s |
| ACCEPTABLE | ≤ 400 ms | ≤ 800 ms | ≤ 5 s |
| SLOW | above | above | above |

---

## 6. One-page summary

| Question | Standard answer |
|----------|-----------------|
| Is my lookup “good”? | Local **&lt; 20–40 ms**; remote **&lt; 100–150 ms** usually yes |
| Is my interactive dashboard “good”? | Prefer **&lt; 200–500 ms**; treat &gt; 2–3 s as a product problem |
| How much data to load for real perf? | **1M–10M+ rows** on hot tables; full suite often **multi-GB** |
| Smoke data enough? | No — fine for CI, not for “we’re production-ready” claims |
| What to publish? | Environment, dataset size, rounds, **p95**, grade mix, top slow queries |

---

## 7. References (practice basis)

- Interactive SaaS API SLO practice: p95 often in the **200–300 ms** band  
- Postgres OLTP tuning focus: index-backed point lookups and keyset pagination under **millions of rows**  
- Serverless Postgres: separate **RTT** from **execution time** via EXPLAIN vs client wall clock  
- GlowTap automated suite: `SchemaMaking/superAdmin/scripts/run-perf-benchmark.js`

---

*GlowTap · Standard Database Performance Benchmark · industry norms only · Confidential*
