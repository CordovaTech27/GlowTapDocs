/**
 * Industry-standard Postgres performance benchmark suite.
 * Workload: SELECT / INSERT / UPDATE / DELETE + analytics + EXPLAIN ANALYZE
 * against PERF-* load + demo data. Bench DML uses isolated PERF-BENCH-* rows.
 *
 *   node scripts/run-perf-benchmark.js --local --rounds=5
 *   node scripts/run-perf-benchmark.js --local --html-only   # refresh HTML/MD from JSON
 *   node scripts/run-perf-benchmark.js              # uses Neon .env
 *
 * Outputs (local adds -local suffix):
 *   reports/perf-benchmark[-local].{json,md,html,pdf}
 */
const fs = require('fs');
const path = require('path');
const os = require('os');
const { performance } = require('perf_hooks');

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const m = a.match(/^--([^=]+)(?:=(.*))?$/);
    return m ? [m[1], m[2] === undefined ? true : m[2]] : [a, true];
  })
);

const IS_LOCAL = Boolean(args.local);
if (IS_LOCAL) {
  const localEnv = path.join(__dirname, '..', '.env.local');
  if (!fs.existsSync(localEnv)) {
    throw new Error('Missing .env.local — run setup-local-glowtap.js first');
  }
  for (const line of fs.readFileSync(localEnv, 'utf8').split(/\r?\n/)) {
    const t = line.trim();
    if (!t || t.startsWith('#') || !t.includes('=')) continue;
    const eq = t.indexOf('=');
    process.env[t.slice(0, eq).trim()] = t.slice(eq + 1).trim();
  }
}

const { pool } = require('../connection');

const ROUNDS = Math.max(3, Number(args.rounds || 5));
const OUT_DIR = path.join(__dirname, '..', 'reports');
const OUT_SUFFIX = IS_LOCAL ? '-local' : '';

function pct(sorted, p) {
  if (!sorted.length) return 0;
  const i = Math.min(sorted.length - 1, Math.max(0, Math.ceil((p / 100) * sorted.length) - 1));
  return sorted[i];
}

function stats(samplesMs) {
  const s = [...samplesMs].sort((a, b) => a - b);
  const sum = s.reduce((a, b) => a + b, 0);
  return {
    n: s.length,
    min_ms: +s[0].toFixed(2),
    avg_ms: +(sum / s.length).toFixed(2),
    p50_ms: +pct(s, 50).toFixed(2),
    p95_ms: +pct(s, 95).toFixed(2),
    p99_ms: +pct(s, 99).toFixed(2),
    max_ms: +s[s.length - 1].toFixed(2),
  };
}

function gradeLatency(avgMs, op) {
  // Local host = tighter bands; Neon remote = RTT-aware bands
  const limits = IS_LOCAL
    ? op === 'analytics'
      ? { good: 200, ok: 1000, warn: 3000 }
      : op === 'write'
        ? { good: 20, ok: 80, warn: 300 }
        : { good: 10, ok: 40, warn: 150 }
    : op === 'analytics'
      ? { good: 500, ok: 2000, warn: 5000 }
      : op === 'write'
        ? { good: 50, ok: 200, warn: 800 }
        : { good: 30, ok: 100, warn: 400 };
  if (avgMs <= limits.good) return 'EXCELLENT';
  if (avgMs <= limits.ok) return 'GOOD';
  if (avgMs <= limits.warn) return 'ACCEPTABLE';
  return 'SLOW';
}

async function timed(client, sql, params = []) {
  const t0 = performance.now();
  const res = await client.query(sql, params);
  const ms = performance.now() - t0;
  return { ms, rowCount: res.rowCount ?? res.rows?.length ?? 0, rows: res.rows };
}

async function bench(client, name, category, sql, paramsFn, rounds = ROUNDS) {
  const samples = [];
  let lastRows = 0;
  let error = null;
  // warm-up
  try {
    const p = typeof paramsFn === 'function' ? paramsFn(0) : paramsFn || [];
    await client.query(sql, p);
  } catch (e) {
    return { name, category, error: e.message, stats: null, grade: 'ERROR' };
  }
  for (let i = 0; i < rounds; i++) {
    try {
      const p = typeof paramsFn === 'function' ? paramsFn(i) : paramsFn || [];
      const r = await timed(client, sql, p);
      samples.push(r.ms);
      lastRows = r.rowCount;
    } catch (e) {
      error = e.message;
      break;
    }
  }
  if (error) return { name, category, error, stats: null, grade: 'ERROR', sql };
  const st = stats(samples);
  return {
    name,
    category,
    sql: sql.replace(/\s+/g, ' ').trim().slice(0, 500),
    rowCount: lastRows,
    stats: st,
    grade: gradeLatency(st.avg_ms, category),
  };
}

async function explainAnalyze(client, name, sql, params = []) {
  const t0 = performance.now();
  const res = await client.query(`EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) ${sql}`, params);
  const ms = performance.now() - t0;
  const plan = res.rows[0]['QUERY PLAN'][0];
  return {
    name,
    wall_ms: +ms.toFixed(2),
    planning_ms: plan['Planning Time'],
    execution_ms: plan['Execution Time'],
    total_cost: plan.Plan?.['Total Cost'],
    actual_rows: plan.Plan?.['Actual Rows'],
    shared_hit: plan['Shared Hit Blocks'] ?? plan.Plan?.['Shared Hit Blocks'],
    shared_read: plan['Shared Read Blocks'] ?? plan.Plan?.['Shared Read Blocks'],
    node: plan.Plan?.['Node Type'],
    plan_json: plan,
  };
}

async function inventory(client) {
  const size = await client.query(`
    SELECT pg_database_size(current_database()) AS bytes,
           pg_size_pretty(pg_database_size(current_database())) AS pretty`);
  const schemas = await client.query(`
    SELECT n.nspname AS schema,
           COUNT(*) FILTER (WHERE c.relkind = 'r')::int AS tables,
           COALESCE(SUM(pg_total_relation_size(c.oid)) FILTER (WHERE c.relkind = 'r'), 0)::bigint AS bytes
    FROM pg_namespace n
    LEFT JOIN pg_class c ON c.relnamespace = n.oid
    WHERE n.nspname IN ('public','rms','subscription','admin_org','cms','review','tickets','services','employee','appointments')
    GROUP BY n.nspname
    ORDER BY bytes DESC`);
  const hot = await client.query(`
    SELECT n.nspname||'.'||c.relname AS relation,
           COALESCE(s.n_live_tup, 0)::bigint AS live_rows,
           pg_total_relation_size(c.oid) AS bytes,
           pg_size_pretty(pg_total_relation_size(c.oid)) AS size
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    LEFT JOIN pg_stat_user_tables s ON s.relid = c.oid
    WHERE n.nspname IN ('public','rms','subscription','admin_org','cms','review','tickets','services','employee','appointments')
      AND c.relkind = 'r'
    ORDER BY pg_total_relation_size(c.oid) DESC
    LIMIT 25`);
  const counts = await client.query(`
    SELECT
      (SELECT COUNT(*)::int FROM organizations WHERE slug LIKE 'perf-%') AS perf_orgs,
      (SELECT COUNT(*)::int FROM branches b JOIN organizations o ON o.id=b.organization_id WHERE o.slug LIKE 'perf-%') AS perf_branches,
      (SELECT COUNT(*)::int FROM appointments.appointments WHERE booking_number LIKE 'PERF-APT-%') AS perf_appointments,
      (SELECT COUNT(*)::int FROM appointments.appointment_status_events e
         JOIN appointments.appointments a ON a.id = e.appointment_id
         WHERE a.booking_number LIKE 'PERF-APT-%') AS perf_status_events,
      (SELECT COUNT(*)::int FROM rms.end_user_transactions WHERE transaction_ref LIKE 'PERF-EUT-%') AS perf_eut,
      (SELECT COUNT(*)::int FROM employee.attendance_records WHERE marked_by_ref='bulk-seed') AS perf_attendance,
      (SELECT COUNT(*)::int FROM employee.employees e JOIN organizations o ON o.id=e.organization_id WHERE o.slug LIKE 'perf-%') AS perf_employees,
      (SELECT COUNT(*)::int FROM services.branch_services s JOIN organizations o ON o.id=s.organization_id WHERE o.slug LIKE 'perf-%') AS perf_services
  `);
  const totals = await client.query(`
    SELECT COALESCE(SUM(n_live_tup), 0)::bigint AS approx_live_rows
    FROM pg_stat_user_tables
    WHERE schemaname IN ('public','rms','subscription','admin_org','cms','review','tickets','services','employee','appointments')
  `);
  const pc = counts.rows[0];
  const perfRowSum =
    Number(pc.perf_orgs) +
    Number(pc.perf_branches) +
    Number(pc.perf_appointments) +
    Number(pc.perf_status_events) +
    Number(pc.perf_eut) +
    Number(pc.perf_attendance) +
    Number(pc.perf_employees) +
    Number(pc.perf_services);
  return {
    db_size: size.rows[0],
    schemas: schemas.rows,
    hottest_tables: hot.rows,
    perf_counts: { ...pc, perf_row_sum: perfRowSum },
    approx_live_rows: Number(totals.rows[0].approx_live_rows),
  };
}

function collectClientEnv() {
  const cpus = os.cpus() || [];
  const cpuModel = cpus[0]?.model?.replace(/\s+/g, ' ').trim() || 'unknown';
  const speeds = cpus.map((c) => c.speed).filter(Boolean);
  const avgMhz = speeds.length ? Math.round(speeds.reduce((a, b) => a + b, 0) / speeds.length) : null;
  const totalMemGb = +(os.totalmem() / 1024 ** 3).toFixed(1);
  const freeMemGb = +(os.freemem() / 1024 ** 3).toFixed(1);
  return {
    role: 'benchmark_client',
    hostname: os.hostname(),
    os: `${os.type()} ${os.release()}`,
    platform: os.platform(),
    arch: os.arch(),
    cpu_model: cpuModel,
    cpu_cores_logical: cpus.length,
    cpu_avg_mhz: avgMhz,
    ram_total_gb: totalMemGb,
    ram_free_gb: freeMemGb,
    node: process.version,
  };
}

function parseSizeToMb(prettyOrRaw) {
  if (prettyOrRaw == null) return null;
  const s = String(prettyOrRaw).trim();
  const m = s.match(/^([\d.]+)\s*(bytes|kB|KB|MB|GB|TB)?$/i);
  if (!m) return null;
  const n = Number(m[1]);
  const u = (m[2] || 'MB').toUpperCase();
  if (u === 'BYTES') return n / (1024 * 1024);
  if (u === 'KB' || u === 'KB') return n / 1024;
  if (u === 'MB') return n;
  if (u === 'GB') return n * 1024;
  if (u === 'TB') return n * 1024 * 1024;
  return n;
}

function estimateNeonComputeSize({ maxConnections, sharedBuffersPretty }) {
  // Neon public CU → RAM / LFC mapping
  const table = [
    { cu: 0.25, ram_gb: 1, max_conn: 104, lfc_gb: 0.75, sb_mb_max: 280 },
    { cu: 0.5, ram_gb: 2, max_conn: 209, lfc_gb: 1.5, sb_mb_max: 450 },
    { cu: 1, ram_gb: 4, max_conn: 419, lfc_gb: 3, sb_mb_max: 900 },
    { cu: 2, ram_gb: 8, max_conn: 839, lfc_gb: 6, sb_mb_max: 1800 },
    { cu: 3, ram_gb: 12, max_conn: 1258, lfc_gb: 9, sb_mb_max: 2700 },
    { cu: 4, ram_gb: 16, max_conn: 1678, lfc_gb: 12, sb_mb_max: 3600 },
  ];

  // Prefer shared_buffers — max_connections on Neon free/pooler can diverge from CU table
  const sbMb = parseSizeToMb(sharedBuffersPretty);
  if (sbMb != null) {
    for (const row of table) {
      if (sbMb <= row.sb_mb_max) {
        return { ...row, basis: `shared_buffers ≈ ${sharedBuffersPretty}` };
      }
    }
    return { ...table[table.length - 1], basis: `shared_buffers ≈ ${sharedBuffersPretty}` };
  }

  const mc = Number(maxConnections) || 0;
  let best = table[0];
  let bestDiff = Infinity;
  for (const row of table) {
    const d = Math.abs(row.max_conn - mc);
    if (d < bestDiff) {
      best = row;
      bestDiff = d;
    }
  }
  return { ...best, basis: `closest CU by max_connections=${mc} (ref ${best.max_conn})` };
}

function parseNeonRegion(hostname) {
  const m = String(hostname || '').match(/\.([a-z0-9-]+)\.aws\.neon\.tech$/i);
  return m ? m[1] : null;
}

async function collectPostgresEnv(client) {
  const meta = await client.query(`
    SELECT current_database() AS database,
           current_setting('server_version') AS server_version,
           current_setting('shared_buffers') AS shared_buffers,
           current_setting('work_mem') AS work_mem,
           current_setting('effective_cache_size') AS effective_cache_size,
           current_setting('max_parallel_workers') AS max_parallel_workers,
           current_setting('max_parallel_workers_per_gather') AS max_parallel_workers_per_gather,
           current_setting('max_connections') AS max_connections,
           inet_server_addr()::text AS server_addr,
           inet_server_port() AS server_port
  `);
  const sizes = await client.query(`
    SELECT name,
           CASE
             WHEN unit = '8kB' THEN pg_size_pretty(setting::bigint * 8192)
             WHEN unit = 'kB' THEN pg_size_pretty(setting::bigint * 1024)
             ELSE setting || COALESCE(unit, '')
           END AS pretty
    FROM pg_settings
    WHERE name IN ('shared_buffers', 'effective_cache_size', 'work_mem')
  `);
  const prettyMap = Object.fromEntries(sizes.rows.map((r) => [r.name, r.pretty]));
  const row = meta.rows[0];
  let hostHint = 'unknown';
  try {
    const u = new URL(process.env.DATABASE_URL);
    hostHint = u.hostname;
  } catch (_) {}

  const base = {
    role: 'postgres_server',
    target: IS_LOCAL ? 'local' : 'neon',
    host: hostHint,
    database: row.database,
    server_version: row.server_version,
    shared_buffers: row.shared_buffers,
    shared_buffers_pretty: prettyMap.shared_buffers || row.shared_buffers,
    work_mem: prettyMap.work_mem || row.work_mem,
    effective_cache_size: row.effective_cache_size,
    effective_cache_size_pretty: prettyMap.effective_cache_size || row.effective_cache_size,
    max_parallel_workers: row.max_parallel_workers,
    max_parallel_workers_per_gather: row.max_parallel_workers_per_gather,
    max_connections: row.max_connections,
    server_addr: row.server_addr,
    server_port: row.server_port,
  };

  if (IS_LOCAL) {
    const clientEnv = collectClientEnv();
    return {
      ...base,
      // Local: server hardware ≈ client machine
      cpu_model: clientEnv.cpu_model,
      cpu_cores_logical: clientEnv.cpu_cores_logical,
      cpu_avg_mhz: clientEnv.cpu_avg_mhz,
      ram_total_gb: clientEnv.ram_total_gb,
      ram_free_gb: clientEnv.ram_free_gb,
      os: clientEnv.os,
      arch: clientEnv.arch,
      hostname: clientEnv.hostname,
      note: 'Local Postgres — CPU/RAM below are from this machine (client and DB host).',
    };
  }

  // Neon: pull compute identity + num_cpus from the server, not the laptop
  let projectId = null;
  let endpointId = null;
  try {
    const ids = await client.query(`
      SELECT current_setting('neon.project_id', true) AS project_id,
             current_setting('neon.endpoint_id', true) AS endpoint_id
    `);
    projectId = ids.rows[0]?.project_id || null;
    endpointId = ids.rows[0]?.endpoint_id || null;
  } catch (_) {}

  let numCpus = null;
  try {
    await client.query('CREATE EXTENSION IF NOT EXISTS neon_utils');
    const cpus = await client.query('SELECT num_cpus() AS num_cpus');
    numCpus = Number(cpus.rows[0]?.num_cpus);
  } catch (_) {}

  const est = estimateNeonComputeSize({
    maxConnections: row.max_connections,
    sharedBuffersPretty: prettyMap.shared_buffers || row.shared_buffers,
  });
  const region = parseNeonRegion(hostHint);

  return {
    ...base,
    provider: 'Neon Postgres (serverless)',
    region: region || 'unknown',
    project_id: projectId,
    endpoint_id: endpointId,
    allocated_cpus: numCpus,
    estimated_cu: est.cu,
    estimated_ram_gb: est.ram_gb,
    estimated_lfc_gb: est.lfc_gb,
    compute_estimate_basis: est.basis,
    // Fields used by report "hardware" panel (Neon, not laptop)
    cpu_model: `Neon compute (~${est.cu} CU)`,
    cpu_cores_logical: numCpus,
    ram_total_gb: est.ram_gb,
    note:
      'Hardware metrics are Neon compute (not the laptop that ran Node). ' +
      `num_cpus()=${numCpus ?? 'n/a'} (fractional CUs may round up). ` +
      'Wall-clock timings still include client↔Neon WAN RTT.',
  };
}

async function setupBenchFixtures(client) {
  // Isolated org for DML benches — cleaned at end
  await client.query(`DELETE FROM organizations WHERE slug = 'perf-bench-org'`);
  const state = (await client.query(`SELECT id FROM states ORDER BY code LIMIT 1`)).rows[0];
  const plan = (
    await client.query(`SELECT id FROM subscription.subscription_plans ORDER BY amount LIMIT 1`)
  ).rows[0];
  const cycle = (
    await client.query(`SELECT id FROM rms.billing_cycles ORDER BY interval_months LIMIT 1`)
  ).rows[0];
  const subcat = (
    await client.query(`
      SELECT sc.id AS subcategory_id, sc.category_id
      FROM services.service_subcategories sc LIMIT 1`)
  ).rows[0];

  const org = (
    await client.query(
      `
    INSERT INTO organizations (
      name, slug, owner_name, owner_email, registered_address, state_id,
      business_type, gst_registration_type, kyc_status, status, is_agreement_signed
    ) VALUES (
      'Perf Bench Org', 'perf-bench-org', 'Bench Owner', 'bench@perf.glowtap.test',
      '{"line1":"1 Bench","city":"Bengaluru","pincode":"560001","country":"IN"}'::jsonb,
      $1, 'PRIVATE_LIMITED', 'REGULAR', 'VERIFIED', 'ACTIVE', TRUE
    ) RETURNING id`,
      [state.id]
    )
  ).rows[0];

  const branch = (
    await client.query(
      `
    INSERT INTO branches (
      organization_id, name, slug, address, status, is_primary, state_id, kyc_status, is_agreement_signed
    ) VALUES (
      $1, 'Bench Branch', 'bench',
      '{"line1":"1 Bench","city":"Bengaluru","pincode":"560001","country":"IN"}'::jsonb,
      'ACTIVE', TRUE, $2, 'VERIFIED', TRUE
    ) RETURNING id`,
      [org.id, state.id]
    )
  ).rows[0];

  await client.query(
    `
    INSERT INTO rms.org_bill_structure (
      organization_id, subscription_plan_id, billing_cycle_id, state_id,
      start_date, renewal_date, payment_method, status
    ) VALUES ($1,$2,$3,$4, CURRENT_DATE, CURRENT_DATE + 30, 'UPI', 'ACTIVE')`,
    [org.id, plan.id, cycle.id, state.id]
  );

  await client.query(
    `
    INSERT INTO rms.org_merchant_balances (
      organization_id, outstanding_amount, pending_payout_amount, currency, updated_at
    ) VALUES ($1, 0, 0, 'INR', NOW())
    ON CONFLICT (organization_id) DO NOTHING`,
    [org.id]
  );

  const emp = (
    await client.query(
      `
    INSERT INTO employee.employees (
      organization_id, branch_id, employee_number, full_name, email, date_of_joining, status
    ) VALUES ($1,$2,'BENCH-001','Bench Emp','bench.emp@perf.glowtap.test', CURRENT_DATE, 'ACTIVE')
    RETURNING id`,
      [org.id, branch.id]
    )
  ).rows[0];

  const svc = (
    await client.query(
      `
    INSERT INTO services.branch_services (
      organization_id, branch_id, category_id, subcategory_id,
      name, price, duration_minutes, status
    ) VALUES ($1,$2,$3,$4,'Bench Cut',499,30,'ACTIVE')
    RETURNING id`,
      [org.id, branch.id, subcat.category_id, subcat.subcategory_id]
    )
  ).rows[0];

  return { orgId: org.id, branchId: branch.id, empId: emp.id, svcId: svc.id };
}

async function cleanupBenchFixtures(client) {
  await client.query(`DELETE FROM organizations WHERE slug = 'perf-bench-org'`);
}

function renderMarkdown(report) {
  const lines = [];
  const inv = report.inventory;
  const ts = new Date(report.generatedAt).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' });

  lines.push(`# GlowTap — Database Performance`);
  lines.push('');
  lines.push(`**Generated:** ${ts} IST`);
  lines.push(`**Engine:** ${IS_LOCAL ? 'Local PostgreSQL (GlowTap)' : 'Neon Postgres (serverless)'}`);
  lines.push(`**Rounds per test:** ${report.rounds} (after 1 warm-up)`);
  lines.push(`**Methodology:** client-side wall clock (Node \`perf_hooks\`) + \`EXPLAIN (ANALYZE, BUFFERS)\``);
  lines.push('');
  lines.push(`---`);
  lines.push('');
  lines.push(`## 1. Test environment`);
  lines.push('');
  const rt = report.runtime || {};
  const clientEnv = rt.client || {};
  const pgEnv = rt.postgres || {};
  if (IS_LOCAL) {
    lines.push(`### Host machine (Postgres + benchmark client)`);
    lines.push('');
    lines.push(`| Metric | Value |`);
    lines.push(`|--------|-------|`);
    lines.push(`| Hostname | ${pgEnv.hostname || clientEnv.hostname || '—'} |`);
    lines.push(`| OS | ${pgEnv.os || clientEnv.os || '—'} (${clientEnv.arch || '—'}) |`);
    lines.push(`| CPU | ${pgEnv.cpu_model || clientEnv.cpu_model || '—'} |`);
    lines.push(`| Logical cores | ${pgEnv.cpu_cores_logical ?? clientEnv.cpu_cores_logical ?? '—'} |`);
    lines.push(
      `| CPU clock (avg) | ${clientEnv.cpu_avg_mhz != null ? clientEnv.cpu_avg_mhz + ' MHz' : '—'} |`
    );
    lines.push(
      `| RAM | ${pgEnv.ram_total_gb != null ? pgEnv.ram_total_gb + ' GB total / ' + (pgEnv.ram_free_gb ?? clientEnv.ram_free_gb) + ' GB free' : '—'} |`
    );
    lines.push(`| Node.js | ${clientEnv.node || '—'} |`);
  } else {
    lines.push(`### Neon compute (database host)`);
    lines.push('');
    lines.push(`| Metric | Value |`);
    lines.push(`|--------|-------|`);
    lines.push(`| Provider | ${pgEnv.provider || 'Neon Postgres (serverless)'} |`);
    lines.push(`| Region | ${pgEnv.region || '—'} |`);
    lines.push(`| Project ID | ${pgEnv.project_id || '—'} |`);
    lines.push(`| Endpoint ID | ${pgEnv.endpoint_id || '—'} |`);
    lines.push(`| Host | ${pgEnv.host || '—'} |`);
    lines.push(`| Estimated compute | ~${pgEnv.estimated_cu ?? '—'} CU |`);
    lines.push(`| Estimated RAM | ~${pgEnv.estimated_ram_gb ?? '—'} GB |`);
    lines.push(`| Local file cache (LFC) | ~${pgEnv.estimated_lfc_gb ?? '—'} GB |`);
    lines.push(`| Allocated CPUs (num_cpus) | ${pgEnv.allocated_cpus ?? '—'} |`);
    lines.push(`| Estimate basis | ${pgEnv.compute_estimate_basis || '—'} |`);
    lines.push('');
    lines.push(`> Laptop/client CPU is **not** listed — timings are Neon compute + WAN RTT from the runner.`);
  }
  lines.push('');
  lines.push(`### PostgreSQL settings`);
  lines.push('');
  lines.push(`| Metric | Value |`);
  lines.push(`|--------|-------|`);
  lines.push(`| Target | ${pgEnv.target || (IS_LOCAL ? 'local' : 'neon')} |`);
  lines.push(`| Database | ${pgEnv.database || '—'} |`);
  lines.push(`| Version | ${pgEnv.server_version || '—'} |`);
  lines.push(
    `| shared_buffers | ${pgEnv.shared_buffers_pretty || pgEnv.shared_buffers || '—'} |`
  );
  lines.push(`| work_mem | ${pgEnv.work_mem || '—'} |`);
  lines.push(
    `| effective_cache_size | ${pgEnv.effective_cache_size_pretty || pgEnv.effective_cache_size || '—'} |`
  );
  lines.push(`| max_parallel_workers | ${pgEnv.max_parallel_workers || '—'} |`);
  lines.push(`| max_parallel_workers_per_gather | ${pgEnv.max_parallel_workers_per_gather || '—'} |`);
  lines.push(`| max_connections | ${pgEnv.max_connections || '—'} |`);
  if (pgEnv.note) {
    lines.push('');
    lines.push(`> ${pgEnv.note}`);
  }
  lines.push('');
  lines.push(`---`);
  lines.push('');
  lines.push(`## 2. Dataset under test`);
  lines.push('');
  lines.push(`| Metric | Value |`);
  lines.push(`|--------|------:|`);
  lines.push(
    `| Database size | ${inv.db_size.pretty}${IS_LOCAL ? '' : ' / 512 MB free-tier cap'} |`
  );
  lines.push(
    `| Approx. live rows (tracked schemas) | ${(inv.approx_live_rows || 0).toLocaleString('en-IN')} |`
  );
  lines.push(
    `| PERF seed row sum (listed below) | ${(inv.perf_counts.perf_row_sum || 0).toLocaleString('en-IN')} |`
  );
  lines.push(`| Perf organizations | ${inv.perf_counts.perf_orgs.toLocaleString('en-IN')} |`);
  lines.push(`| Perf branches | ${inv.perf_counts.perf_branches.toLocaleString('en-IN')} |`);
  lines.push(`| Perf appointments | ${inv.perf_counts.perf_appointments.toLocaleString('en-IN')} |`);
  lines.push(
    `| Perf status events | ${(inv.perf_counts.perf_status_events || 0).toLocaleString('en-IN')} |`
  );
  lines.push(`| Perf EUT | ${inv.perf_counts.perf_eut.toLocaleString('en-IN')} |`);
  lines.push(`| Perf attendance rows | ${inv.perf_counts.perf_attendance.toLocaleString('en-IN')} |`);
  lines.push(`| Perf employees | ${inv.perf_counts.perf_employees.toLocaleString('en-IN')} |`);
  lines.push(`| Perf branch services | ${inv.perf_counts.perf_services.toLocaleString('en-IN')} |`);
  lines.push(`| Benchmark tests | ${report.benchmarks.length} |`);
  lines.push(`| EXPLAIN ANALYZE profiles | ${report.explains.length} |`);

  const byGrade = {};
  for (const b of report.benchmarks) {
    byGrade[b.grade] = (byGrade[b.grade] || 0) + 1;
  }
  lines.push(`| Grade mix | ${Object.entries(byGrade).map(([k, v]) => `${k}: ${v}`).join(' · ')} |`);
  lines.push('');

  const slow = report.benchmarks
    .filter((b) => b.stats)
    .sort((a, b) => b.stats.avg_ms - a.stats.avg_ms)
    .slice(0, 5);
  lines.push(`### Slowest operations (by avg latency)`);
  lines.push('');
  lines.push(`| Rank | Operation | Category | Avg (ms) | P95 (ms) | Grade |`);
  lines.push(`|-----:|-----------|----------|--------:|---------:|-------|`);
  slow.forEach((b, i) => {
    lines.push(
      `| ${i + 1} | ${b.name} | ${b.category} | ${b.stats.avg_ms} | ${b.stats.p95_ms} | ${b.grade} |`
    );
  });
  lines.push('');

  lines.push(`---`);
  lines.push('');
  lines.push(`## 3. Storage & schema footprint`);
  lines.push('');
  lines.push(`| Schema | Tables | Size |`);
  lines.push(`|--------|-------:|------|`);
  for (const s of inv.schemas) {
    const mb = (Number(s.bytes) / 1024 / 1024).toFixed(1);
    lines.push(`| \`${s.schema}\` | ${s.tables} | ${mb} MB |`);
  }
  lines.push('');
  lines.push(`### Hottest relations (by total size)`);
  lines.push('');
  lines.push(`| Relation | Live rows (approx) | Size |`);
  lines.push(`|----------|-------------------:|------|`);
  for (const t of inv.hottest_tables) {
    lines.push(
      `| \`${t.relation}\` | ${Number(t.live_rows).toLocaleString('en-IN')} | ${t.size} |`
    );
  }
  lines.push('');

  const cats = ['point_lookup', 'range_scan', 'join', 'analytics', 'write', 'mixed'];
  const catTitles = {
    point_lookup: '4. Point lookups (GET by key / unique)',
    range_scan: '5. Range / filter scans',
    join: '6. Multi-table joins',
    analytics: '7. Aggregations & expensive analytics',
    write: '8. Write path (INSERT / UPDATE / DELETE)',
    mixed: '9. Mixed / application-style workloads',
  };

  for (const cat of cats) {
    const items = report.benchmarks.filter((b) => b.category === cat || (cat === 'write' && b.category === 'write'));
    // remap categories used in benches
  }

  const groups = {
    point_lookup: report.benchmarks.filter((b) => b.category === 'point_lookup'),
    range_scan: report.benchmarks.filter((b) => b.category === 'range_scan'),
    join: report.benchmarks.filter((b) => b.category === 'join'),
    analytics: report.benchmarks.filter((b) => b.category === 'analytics'),
    write: report.benchmarks.filter((b) => b.category === 'write'),
    mixed: report.benchmarks.filter((b) => b.category === 'mixed'),
  };

  let section = 4;
  for (const [cat, title] of Object.entries(catTitles)) {
    const items = groups[cat] || [];
    if (!items.length) continue;
    lines.push(`---`);
    lines.push('');
    lines.push(`## ${section}. ${title.replace(/^\d+\.\s*/, '')}`);
    section++;
    lines.push('');
    lines.push(
      `| Test | Rows | Min | Avg | P50 | P95 | P99 | Max | Grade |`
    );
    lines.push(`|------|-----:|----:|----:|----:|----:|----:|----:|-------|`);
    for (const b of items) {
      if (b.error) {
        lines.push(`| ${b.name} | — | — | — | — | — | — | — | ERROR: ${b.error.slice(0, 80)} |`);
        continue;
      }
      const s = b.stats;
      lines.push(
        `| ${b.name} | ${b.rowCount} | ${s.min_ms} | **${s.avg_ms}** | ${s.p50_ms} | ${s.p95_ms} | ${s.p99_ms} | ${s.max_ms} | ${b.grade} |`
      );
    }
    lines.push('');
    lines.push(`<details><summary>SQL samples</summary>`);
    lines.push('');
    for (const b of items) {
      if (!b.sql) continue;
      lines.push(`**${b.name}**`);
      lines.push('');
      lines.push('```sql');
      lines.push(b.sql);
      lines.push('```');
      lines.push('');
    }
    lines.push(`</details>`);
    lines.push('');
  }

  lines.push(`---`);
  lines.push('');
  lines.push(`## ${section}. EXPLAIN ANALYZE profiles`);
  section++;
  lines.push('');
  lines.push(
    `Postgres planner cost + actual runtime (includes buffer hits). Useful for index / join tuning.`
  );
  lines.push('');
  lines.push(
    `| Query | Planning (ms) | Execution (ms) | Total cost | Actual rows | Top node |`
  );
  lines.push(`|-------|-------------:|---------------:|-----------:|------------:|----------|`);
  for (const e of report.explains) {
    lines.push(
      `| ${e.name} | ${e.planning_ms} | **${e.execution_ms}** | ${e.total_cost} | ${e.actual_rows} | ${e.node} |`
    );
  }
  lines.push('');

  lines.push(`---`);
  lines.push('');
  lines.push(`## ${section}. Grading rubric`);
  lines.push('');
  lines.push(`| Grade | Point / range / join (avg) | Writes (avg) | Analytics (avg) |`);
  lines.push(`|-------|---------------------------:|-------------:|----------------:|`);
  if (IS_LOCAL) {
    lines.push(`| EXCELLENT | ≤ 10 ms | ≤ 20 ms | ≤ 200 ms |`);
    lines.push(`| GOOD | ≤ 40 ms | ≤ 80 ms | ≤ 1 s |`);
    lines.push(`| ACCEPTABLE | ≤ 150 ms | ≤ 300 ms | ≤ 3 s |`);
    lines.push(`| SLOW | above | above | above |`);
    lines.push('');
    lines.push(`> Local rubric (no network RTT). Measured against ~10M-row GlowTap load.`);
  } else {
    lines.push(`| EXCELLENT | ≤ 30 ms | ≤ 50 ms | ≤ 500 ms |`);
    lines.push(`| GOOD | ≤ 100 ms | ≤ 200 ms | ≤ 2 s |`);
    lines.push(`| ACCEPTABLE | ≤ 400 ms | ≤ 800 ms | ≤ 5 s |`);
    lines.push(`| SLOW | above | above | above |`);
    lines.push('');
    lines.push(
      `> Neon serverless may show higher first-hit latency (compute resume). Warm-up round is excluded from stats.`
    );
  }
  lines.push('');

  lines.push(`---`);
  lines.push('');
  lines.push(`## ${section + 1}. Recommendations`);
  lines.push('');
  const recs = [];
  recs.push(
    '- **Applied (Round 3):** covering / composite indexes in `076_performance_indexes_round3.sql` (full on local; lite subset `076b` on Neon due to 512 MB cap).'
  );
  recs.push(
    '- **Applied:** analytics SQL rewritten — prefix range predicates (`>= … AND < …`) + `LATERAL` aggregates for cross-schema rollups (avoids cartesian LEFT JOIN blow-up).'
  );
  for (const b of report.benchmarks.filter((x) => x.grade === 'SLOW' || x.grade === 'ACCEPTABLE')) {
    recs.push(`- **${b.name}** (${b.grade}, avg ${b.stats?.avg_ms} ms) — review indexes / reduce join width / paginate.`);
  }
  if (!report.benchmarks.some((x) => x.grade === 'SLOW' || x.grade === 'ACCEPTABLE')) {
    recs.push('- No SLOW/ACCEPTABLE grades under current thresholds; re-run after schema growth or with higher concurrency.');
  }
  recs.push(
    '- Keep `VACUUM ANALYZE` on large tables after bulk loads (appointments, attendance, EUT).'
  );
  recs.push('- Prefer keyset pagination over `OFFSET` for appointment/EUT lists at this scale.');
  recs.push(
    IS_LOCAL
      ? '- Local DB size: ' + inv.db_size.pretty + '.'
      : '- Monitor Neon storage (512 MB free tier); current DB ~' + inv.db_size.pretty + '.'
  );
  lines.push(recs.join('\n'));
  lines.push('');
  lines.push(`---`);
  lines.push('');
  lines.push(`*Report generated by \`scripts/run-perf-benchmark.js\`*`);
  return lines.join('\n');
}

function loadBaseline() {
  if (!IS_LOCAL) return null;
  const p = path.join(OUT_DIR, 'perf-benchmark-local-before.json');
  if (!fs.existsSync(p)) return null;
  try {
    return JSON.parse(fs.readFileSync(p, 'utf8'));
  } catch {
    return null;
  }
}

function renderHtml(md, report, baseline) {
  const benches = report.benchmarks.filter((b) => b.stats);
  const gradeCounts = { EXCELLENT: 0, GOOD: 0, ACCEPTABLE: 0, SLOW: 0 };
  for (const b of benches) gradeCounts[b.grade] = (gradeCounts[b.grade] || 0) + 1;

  const cats = ['point_lookup', 'range_scan', 'join', 'analytics', 'write', 'mixed'];
  const catLabels = {
    point_lookup: 'Point lookup',
    range_scan: 'Range scan',
    join: 'Join',
    analytics: 'Analytics',
    write: 'Write',
    mixed: 'Mixed',
  };
  const catAvg = {};
  const catP95 = {};
  for (const c of cats) {
    const items = benches.filter((b) => b.category === c);
    catAvg[c] = items.length
      ? +(items.reduce((s, b) => s + b.stats.avg_ms, 0) / items.length).toFixed(2)
      : 0;
    catP95[c] = items.length
      ? +(items.reduce((s, b) => s + b.stats.p95_ms, 0) / items.length).toFixed(2)
      : 0;
  }

  const beforeMap = new Map();
  if (baseline?.benchmarks) {
    for (const b of baseline.benchmarks) {
      if (b.stats) beforeMap.set(b.name, b);
    }
  }

  const comparison = benches
    .map((b) => {
      const prev = beforeMap.get(b.name);
      if (!prev?.stats) return null;
      const delta = +(b.stats.avg_ms - prev.stats.avg_ms).toFixed(2);
      const pct = prev.stats.avg_ms
        ? +(((prev.stats.avg_ms - b.stats.avg_ms) / prev.stats.avg_ms) * 100).toFixed(1)
        : 0;
      return {
        name: b.name,
        before: prev.stats.avg_ms,
        after: b.stats.avg_ms,
        delta,
        improvement_pct: pct,
        grade_before: prev.grade,
        grade_after: b.grade,
      };
    })
    .filter(Boolean);

  const improved = comparison.filter((c) => c.delta < 0).length;
  const slowed = comparison.filter((c) => c.delta > 0).length;
  const avgImprovement =
    comparison.length > 0
      ? +(comparison.reduce((s, c) => s + c.improvement_pct, 0) / comparison.length).toFixed(1)
      : null;

  const topWins = comparison
    .filter((c) => c.improvement_pct > 0)
    .sort((a, b) => b.improvement_pct - a.improvement_pct)
    .slice(0, 5);

  const sortedByLatency = [...benches].sort((a, b) => b.stats.avg_ms - a.stats.avg_ms);
  const storage = report.inventory.schemas.map((s) => ({
    schema: s.schema,
    mb: Math.round(Number(s.bytes) / 1024 / 1024),
  }));

  const chartPayload = {
    labels: benches.map((b) => b.name),
    avg: benches.map((b) => b.stats.avg_ms),
    p50: benches.map((b) => b.stats.p50_ms),
    p95: benches.map((b) => b.stats.p95_ms),
    grades: gradeCounts,
    categories: cats.map((c) => catLabels[c]),
    categoryAvg: cats.map((c) => catAvg[c]),
    categoryP95: cats.map((c) => catP95[c]),
    comparison: comparison.slice().sort((a, b) => a.delta - b.delta),
    topWins,
    storage,
    inventory: report.inventory,
    slowest: sortedByLatency.slice(0, 8).map((b) => ({
      name: b.name,
      avg: b.stats.avg_ms,
      p95: b.stats.p95_ms,
    })),
  };

  const rows = benches
    .map((b) => {
      const prev = beforeMap.get(b.name);
      const delta =
        prev?.stats != null
          ? (() => {
              const d = +(b.stats.avg_ms - prev.stats.avg_ms).toFixed(2);
              const cls = d < 0 ? 'delta-down' : d > 0 ? 'delta-up' : 'delta-flat';
              const sign = d > 0 ? '+' : '';
              return `<td class="${cls}">${sign}${d}</td>`;
            })()
          : '<td class="muted">—</td>';
      return `<tr>
        <td class="name">${escapeHtml(b.name)}</td>
        <td><span class="pill cat-${b.category}">${escapeHtml(catLabels[b.category] || b.category)}</span></td>
        <td>${Number(b.rowCount).toLocaleString('en-IN')}</td>
        <td>${b.stats.avg_ms}</td>
        <td>${b.stats.p50_ms}</td>
        <td>${b.stats.p95_ms}</td>
        <td>${b.stats.max_ms}</td>
        ${delta}
        <td><span class="grade-chip g-${b.grade}">${b.grade}</span></td>
      </tr>`;
    })
    .join('\n');

  const winCards = topWins
    .map(
      (w) => `<div class="win">
        <div class="win-pct">−${w.improvement_pct}%</div>
        <div class="win-name">${escapeHtml(w.name)}</div>
        <div class="win-meta">${w.before} → ${w.after} ms</div>
      </div>`
    )
    .join('\n');

  const hotspotRows = report.inventory.hottest_tables
    .slice(0, 10)
    .map(
      (t) =>
        `<tr><td>${escapeHtml(t.relation)}</td><td>${Number(t.live_rows).toLocaleString('en-IN')}</td><td>${t.size}</td></tr>`
    )
    .join('\n');

  const envLabel = IS_LOCAL ? 'Local PostgreSQL' : 'Neon Postgres';
  const ts = new Date(report.generatedAt).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' });
  const score =
    gradeCounts.EXCELLENT * 4 +
    gradeCounts.GOOD * 3 +
    gradeCounts.ACCEPTABLE * 1 +
    gradeCounts.SLOW * 0;
  const maxScore = benches.length * 4;
  const healthPct = maxScore ? Math.round((score / maxScore) * 100) : 0;

  const rt = report.runtime || {};
  const clientEnv = rt.client || {};
  const pgEnv = rt.postgres || {};
  const pc = report.inventory.perf_counts || {};
  const fmt = (n) => Number(n || 0).toLocaleString('en-IN');

  let hardwareTitle;
  let hardwareHint;
  let hardwareRows;
  if (IS_LOCAL) {
    hardwareTitle = 'Host machine';
    hardwareHint = 'CPU / RAM where Postgres + Node ran';
    hardwareRows = [
      ['Hostname', pgEnv.hostname || clientEnv.hostname],
      ['OS', `${pgEnv.os || clientEnv.os || '—'} (${clientEnv.arch || '—'})`],
      ['CPU', pgEnv.cpu_model || clientEnv.cpu_model],
      ['Logical cores', pgEnv.cpu_cores_logical ?? clientEnv.cpu_cores_logical],
      ['CPU clock (avg)', clientEnv.cpu_avg_mhz != null ? `${clientEnv.cpu_avg_mhz} MHz` : '—'],
      [
        'RAM',
        pgEnv.ram_total_gb != null
          ? `${pgEnv.ram_total_gb} GB total · ${pgEnv.ram_free_gb ?? clientEnv.ram_free_gb} GB free`
          : '—',
      ],
      ['Node.js', clientEnv.node],
    ];
  } else {
    hardwareTitle = 'Neon compute';
    hardwareHint = 'Database host resources (not the laptop runner)';
    hardwareRows = [
      ['Provider', pgEnv.provider || 'Neon Postgres (serverless)'],
      ['Region', pgEnv.region],
      ['Project ID', pgEnv.project_id],
      ['Endpoint ID', pgEnv.endpoint_id],
      ['Host', pgEnv.host],
      ['Estimated CU', pgEnv.estimated_cu != null ? `~${pgEnv.estimated_cu} CU` : '—'],
      ['Estimated RAM', pgEnv.estimated_ram_gb != null ? `~${pgEnv.estimated_ram_gb} GB` : '—'],
      ['Local file cache', pgEnv.estimated_lfc_gb != null ? `~${pgEnv.estimated_lfc_gb} GB` : '—'],
      ['Allocated CPUs (num_cpus)', pgEnv.allocated_cpus],
      ['Estimate basis', pgEnv.compute_estimate_basis],
    ];
  }

  const envHardwareRows = hardwareRows
    .map(([k, v]) => `<tr><td>${escapeHtml(k)}</td><td>${escapeHtml(String(v ?? '—'))}</td></tr>`)
    .join('');

  const envPgRows = [
    ['Database', pgEnv.database],
    ['Version', pgEnv.server_version],
    ['shared_buffers', pgEnv.shared_buffers_pretty || pgEnv.shared_buffers],
    ['work_mem', pgEnv.work_mem],
    ['effective_cache_size', pgEnv.effective_cache_size_pretty || pgEnv.effective_cache_size],
    ['max_parallel_workers', pgEnv.max_parallel_workers],
    ['max_parallel_workers_per_gather', pgEnv.max_parallel_workers_per_gather],
    ['max_connections', pgEnv.max_connections],
  ]
    .map(([k, v]) => `<tr><td>${escapeHtml(k)}</td><td>${escapeHtml(String(v ?? '—'))}</td></tr>`)
    .join('');

  const datasetRows = [
    ['Database size', report.inventory.db_size.pretty],
    ['Approx. live rows', fmt(report.inventory.approx_live_rows)],
    ['PERF seed row sum', fmt(pc.perf_row_sum)],
    ['Organizations', fmt(pc.perf_orgs)],
    ['Branches', fmt(pc.perf_branches)],
    ['Appointments', fmt(pc.perf_appointments)],
    ['Status events', fmt(pc.perf_status_events)],
    ['End-user transactions', fmt(pc.perf_eut)],
    ['Attendance rows', fmt(pc.perf_attendance)],
    ['Employees', fmt(pc.perf_employees)],
    ['Branch services', fmt(pc.perf_services)],
  ]
    .map(([k, v]) => `<tr><td>${escapeHtml(k)}</td><td>${escapeHtml(String(v))}</td></tr>`)
    .join('');

  const cpuKpi = IS_LOCAL
    ? `<div class="kpi"><div class="label">CPU cores</div><div class="value">${pgEnv.cpu_cores_logical || clientEnv.cpu_cores_logical || '—'}</div><div class="sub">logical</div></div>`
    : `<div class="kpi"><div class="label">Neon CU</div><div class="value" style="font-size:1.25rem">~${pgEnv.estimated_cu ?? '—'}</div><div class="sub">~${pgEnv.estimated_ram_gb ?? '—'} GB RAM · ${pgEnv.allocated_cpus ?? '—'} CPU</div></div>`;

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>GlowTap — Database Performance</title>
<link rel="preconnect" href="https://fonts.googleapis.com"/>
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
<link href="https://fonts.googleapis.com/css2?family=Sora:wght@400;500;600;700&family=IBM+Plex+Sans:wght@400;500;600&display=swap" rel="stylesheet"/>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
<style>
  :root {
    --ink: #12201c;
    --muted: #5c726a;
    --line: #d7e3dc;
    --panel: #ffffff;
    --panel-soft: #f3f8f5;
    --teal: #0f766e;
    --teal-bright: #14b8a6;
    --amber: #d97706;
    --rose: #e11d48;
    --emerald: #059669;
    --sky: #0284c7;
    --shadow: 0 12px 40px rgba(18, 32, 28, 0.08);
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    font-family: "IBM Plex Sans", system-ui, sans-serif;
    color: var(--ink);
    background:
      radial-gradient(1200px 600px at 10% -10%, rgba(20,184,166,0.16), transparent 55%),
      radial-gradient(900px 500px at 100% 0%, rgba(2,132,199,0.10), transparent 50%),
      linear-gradient(180deg, #eef6f2 0%, #f7faf8 40%, #eef2f0 100%);
    min-height: 100vh;
    line-height: 1.45;
  }
  .wrap { max-width: 1320px; margin: 0 auto; padding: 28px 20px 72px; }
  .hero {
    position: relative;
    overflow: hidden;
    border-radius: 24px;
    padding: 36px 40px;
    margin-bottom: 22px;
    color: #f4fffb;
    background:
      linear-gradient(135deg, #0b3d38 0%, #0f766e 48%, #0e7490 100%);
    box-shadow: var(--shadow);
  }
  .hero::after {
    content: "";
    position: absolute; right: -80px; top: -60px; width: 320px; height: 320px;
    border-radius: 50%;
    background: radial-gradient(circle, rgba(255,255,255,0.18), transparent 70%);
    pointer-events: none;
  }
  .brand {
    font-family: Sora, sans-serif;
    font-size: 0.78rem; font-weight: 600; letter-spacing: 0.14em;
    text-transform: uppercase; opacity: 0.85; margin-bottom: 10px;
  }
  .hero h1 {
    font-family: Sora, sans-serif;
    margin: 0 0 10px; font-size: clamp(1.8rem, 3vw, 2.55rem);
    font-weight: 700; letter-spacing: -0.03em; max-width: 16ch;
  }
  .hero .meta { opacity: 0.88; font-size: 0.98rem; max-width: 62ch; }
  .hero-row { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 18px; }
  .chip {
    display: inline-flex; align-items: center; gap: 6px;
    padding: 6px 12px; border-radius: 999px;
    background: rgba(255,255,255,0.14); backdrop-filter: blur(6px);
    font-size: 0.82rem; font-weight: 500;
  }
  .kpis {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 12px; margin-bottom: 18px;
  }
  .kpi {
    background: var(--panel); border: 1px solid var(--line);
    border-radius: 18px; padding: 16px 18px; box-shadow: var(--shadow);
  }
  .kpi .label {
    font-family: Sora, sans-serif; font-size: 0.68rem; font-weight: 600;
    letter-spacing: 0.08em; text-transform: uppercase; color: var(--muted);
  }
  .kpi .value {
    font-family: Sora, sans-serif; font-size: 1.7rem; font-weight: 700;
    margin-top: 6px; letter-spacing: -0.03em;
  }
  .kpi .sub { color: var(--muted); font-size: 0.8rem; margin-top: 2px; }
  .grid2 { display: grid; grid-template-columns: 1.35fr 1fr; gap: 14px; margin-bottom: 14px; }
  .grid3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 14px; margin-bottom: 14px; }
  .grid-wins { display: grid; grid-template-columns: repeat(5, 1fr); gap: 10px; margin-bottom: 14px; }
  @media (max-width: 1100px) {
    .grid2, .grid3 { grid-template-columns: 1fr; }
    .grid-wins { grid-template-columns: 1fr 1fr; }
  }
  .card {
    background: var(--panel); border: 1px solid var(--line);
    border-radius: 20px; padding: 18px 20px; box-shadow: var(--shadow);
  }
  .card h2 {
    font-family: Sora, sans-serif; margin: 0 0 4px;
    font-size: 1.02rem; font-weight: 600; letter-spacing: -0.01em;
  }
  .card .hint { color: var(--muted); font-size: 0.82rem; margin: 0 0 14px; }
  .chart-box { position: relative; height: 300px; }
  .chart-box.tall { height: 460px; }
  .chart-box.med { height: 280px; }
  .win {
    background: linear-gradient(180deg, #ffffff, #f2fbf8);
    border: 1px solid var(--line); border-radius: 16px; padding: 14px;
  }
  .win-pct {
    font-family: Sora, sans-serif; font-size: 1.35rem; font-weight: 700;
    color: var(--emerald); letter-spacing: -0.02em;
  }
  .win-name { font-size: 0.82rem; font-weight: 600; margin-top: 6px; line-height: 1.3; }
  .win-meta { color: var(--muted); font-size: 0.75rem; margin-top: 4px; }
  table { width: 100%; border-collapse: collapse; font-size: 0.86rem; }
  th, td { padding: 10px 10px; border-bottom: 1px solid var(--line); text-align: left; }
  th {
    font-family: Sora, sans-serif; color: var(--muted); font-weight: 600;
    font-size: 0.68rem; text-transform: uppercase; letter-spacing: 0.05em;
    background: var(--panel-soft); position: sticky; top: 0;
  }
  td:nth-child(n+3), th:nth-child(n+3) { text-align: right; font-variant-numeric: tabular-nums; }
  td.name { font-weight: 500; }
  tbody tr:hover { background: #f7fcfa; }
  .pill {
    display: inline-block; padding: 3px 9px; border-radius: 999px;
    font-size: 0.72rem; font-weight: 600; background: #e8f2ee; color: #34584f;
  }
  .grade-chip {
    display: inline-block; padding: 3px 9px; border-radius: 999px;
    font-size: 0.72rem; font-weight: 700; letter-spacing: 0.02em;
  }
  .g-EXCELLENT { background: #d1fae5; color: #047857; }
  .g-GOOD { background: #ccfbf1; color: #0f766e; }
  .g-ACCEPTABLE { background: #fef3c7; color: #b45309; }
  .g-SLOW { background: #ffe4e6; color: #be123c; }
  .delta-down { color: var(--emerald); font-weight: 700; }
  .delta-up { color: var(--rose); font-weight: 700; }
  .delta-flat { color: var(--muted); }
  .muted { color: var(--muted); }
  .scroll { overflow: auto; max-height: 520px; border-radius: 12px; border: 1px solid var(--line); }
  .health {
    display: flex; align-items: center; gap: 18px; margin-top: 8px;
  }
  .ring {
    --p: ${healthPct};
    width: 88px; height: 88px; border-radius: 50%;
    background: conic-gradient(var(--teal-bright) calc(var(--p) * 1%), #dbe7e2 0);
    display: grid; place-items: center; flex-shrink: 0;
  }
  .ring > span {
    width: 66px; height: 66px; border-radius: 50%; background: #fff;
    display: grid; place-items: center;
    font-family: Sora, sans-serif; font-weight: 700; font-size: 1.05rem;
  }
  details { margin-top: 16px; }
  details summary {
    cursor: pointer; color: var(--teal); font-weight: 600;
    font-family: Sora, sans-serif; font-size: 0.92rem;
  }
  pre {
    background: #10241f; color: #d7ebe4; border-radius: 14px;
    padding: 16px; overflow: auto; font-size: 0.75rem; max-height: 420px;
  }
  footer {
    margin-top: 28px; text-align: center; color: var(--muted);
    font-size: 0.8rem;
  }
  code { font-size: 0.85em; background: #e7f2ee; padding: 1px 6px; border-radius: 6px; }
</style>
</head>
<body>
<div class="wrap">
  <header class="hero">
    <div class="brand">GlowTap</div>
    <h1>Database Performance</h1>
    <p class="meta">${escapeHtml(envLabel)} · ${escapeHtml(ts)} IST · ${report.rounds} measured rounds · DB ${escapeHtml(report.inventory.db_size.pretty)}</p>
    <div class="hero-row">
      <span class="chip">${benches.length} workloads</span>
      <span class="chip">${gradeCounts.EXCELLENT} excellent</span>
      <span class="chip">Latency suite</span>
      <span class="chip">Health score ${healthPct}%</span>
    </div>
  </header>

  <section class="kpis">
    <div class="kpi"><div class="label">Tests</div><div class="value">${benches.length}</div><div class="sub">timed queries</div></div>
    <div class="kpi"><div class="label">Excellent</div><div class="value" style="color:var(--emerald)">${gradeCounts.EXCELLENT}</div></div>
    <div class="kpi"><div class="label">Good</div><div class="value" style="color:var(--teal)">${gradeCounts.GOOD || 0}</div></div>
    <div class="kpi"><div class="label">Acceptable</div><div class="value" style="color:var(--amber)">${gradeCounts.ACCEPTABLE}</div></div>
    <div class="kpi"><div class="label">Slow</div><div class="value" style="color:var(--rose)">${gradeCounts.SLOW}</div></div>
    <div class="kpi"><div class="label">DB size</div><div class="value" style="font-size:1.25rem">${escapeHtml(report.inventory.db_size.pretty)}</div></div>
    <div class="kpi"><div class="label">Live rows</div><div class="value" style="font-size:1.15rem">${fmt(report.inventory.approx_live_rows)}</div><div class="sub">approx · all schemas</div></div>
    ${cpuKpi}
  </section>

  <div class="grid3" style="margin-bottom:14px">
    <div class="card">
      <h2>${escapeHtml(hardwareTitle)}</h2>
      <p class="hint">${escapeHtml(hardwareHint)}</p>
      <table>
        <thead><tr><th>Metric</th><th>Value</th></tr></thead>
        <tbody>${envHardwareRows}</tbody>
      </table>
      ${pgEnv.note && !IS_LOCAL ? `<p class="muted" style="margin:12px 0 0;font-size:0.82rem">${escapeHtml(pgEnv.note)}</p>` : ''}
    </div>
    <div class="card">
      <h2>PostgreSQL settings</h2>
      <p class="hint">${IS_LOCAL ? 'Local GlowTap instance' : 'Neon serverless Postgres knobs'}</p>
      <table>
        <thead><tr><th>Metric</th><th>Value</th></tr></thead>
        <tbody>${envPgRows}</tbody>
      </table>
      ${pgEnv.note && IS_LOCAL ? `<p class="muted" style="margin:12px 0 0;font-size:0.82rem">${escapeHtml(pgEnv.note)}</p>` : ''}
    </div>
    <div class="card">
      <h2>Dataset under test</h2>
      <p class="hint">PERF seed + tracked live rows</p>
      <table>
        <thead><tr><th>Metric</th><th>Value</th></tr></thead>
        <tbody>${datasetRows}</tbody>
      </table>
    </div>
  </div>

  ${
    topWins.length
      ? `<section class="grid-wins">${winCards}</section>`
      : ''
  }

  <div class="grid2">
    <div class="card">
      <h2>Latency spectrum</h2>
      <p class="hint">Avg vs p95 across every benchmark (log scale)</p>
      <div class="chart-box tall"><canvas id="chartLatency"></canvas></div>
    </div>
    <div class="card">
      <h2>Grade mix</h2>
      <p class="hint">Share of results under local SLO bands</p>
      <div class="chart-box med"><canvas id="chartGrades"></canvas></div>
      <div class="health">
        <div class="ring"><span>${healthPct}%</span></div>
        <div>
          <strong style="font-family:Sora,sans-serif">Suite health</strong>
          <p class="muted" style="margin:4px 0 0;font-size:0.88rem">Weighted from grades (Excellent=4 … Slow=0). Target: keep analytics under 1s at this scale.</p>
        </div>
      </div>
    </div>
  </div>

  <div class="grid3">
    <div class="card">
      <h2>By category</h2>
      <p class="hint">Average latency</p>
      <div class="chart-box"><canvas id="chartCategory"></canvas></div>
    </div>
    <div class="card">
      <h2>Category radar</h2>
      <p class="hint">Avg vs p95 profile</p>
      <div class="chart-box"><canvas id="chartRadar"></canvas></div>
    </div>
    <div class="card">
      <h2>Storage by schema</h2>
      <p class="hint">Disk footprint (MB)</p>
      <div class="chart-box"><canvas id="chartStorage"></canvas></div>
    </div>
  </div>

  <div class="grid2">
    <div class="card">
      <h2>${baseline ? 'Optimization impact' : 'Slowest queries'}</h2>
      <p class="hint">${baseline ? 'Before vs after average latency (log scale)' : 'Highest avg ms after warm-up'}</p>
      <div class="chart-box tall"><canvas id="chartCompare"></canvas></div>
    </div>
    <div class="card">
      <h2>${baseline ? 'Top improvements' : 'Largest tables'}</h2>
      <p class="hint">${baseline ? 'Percent faster than baseline' : 'Live rows × size'}</p>
      <div class="chart-box tall"><canvas id="chartWins"></canvas></div>
    </div>
  </div>

  <div class="card" style="margin-bottom:14px">
    <h2>Results matrix${baseline ? ' · Δ vs baseline' : ''}</h2>
    <p class="hint">All timings in milliseconds · sticky header for scanning</p>
    <div class="scroll">
      <table>
        <thead>
          <tr>
            <th>Test</th><th>Category</th><th>Rows</th><th>Avg</th><th>P50</th><th>P95</th><th>Max</th>
            ${baseline ? '<th>Δ avg</th>' : '<th></th>'}
            <th>Grade</th>
          </tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>
    </div>
  </div>

  <div class="grid2">
    <div class="card">
      <h2>Hottest relations</h2>
      <p class="hint">Top tables by on-disk size</p>
      <table>
        <thead><tr><th>Relation</th><th>Live rows</th><th>Size</th></tr></thead>
        <tbody>${hotspotRows}</tbody>
      </table>
    </div>
    <div class="card">
      <h2>Methodology</h2>
      <p class="muted" style="margin:0;font-size:0.92rem">
        Client wall time via <code>perf_hooks</code> around <code>pg</code> queries.
        One warm-up discarded; stats from ${report.rounds} rounds (min / avg / p50 / p95 / p99 / max).
        Covering + partial indexes (<code>076</code>/<code>077</code>), range predicates, and LATERAL aggregates
        for platform analytics. Local SLO bands are tighter than Neon (no WAN RTT).
      </p>
    </div>
  </div>

  <details>
    <summary>Full markdown appendix</summary>
    <pre>${escapeHtml(md)}</pre>
  </details>

  <footer>GlowTap — Database Performance · generated by scripts/run-perf-benchmark.js</footer>
</div>
<script>
const DATA = ${JSON.stringify(chartPayload)};
const hasCompare = DATA.comparison && DATA.comparison.length > 0;
const teal = '#0f766e';
const tealSoft = 'rgba(20,184,166,0.75)';
const sky = 'rgba(2,132,199,0.65)';
const amber = 'rgba(217,119,6,0.7)';
const rose = 'rgba(225,29,72,0.55)';
const emerald = 'rgba(5,150,105,0.8)';

Chart.defaults.color = '#5c726a';
Chart.defaults.borderColor = '#d7e3dc';
Chart.defaults.font.family = '"IBM Plex Sans", system-ui, sans-serif';

const tip = { backgroundColor: '#12201c', titleFont: { family: 'Sora', size: 12 }, bodyFont: { size: 12 }, padding: 10, cornerRadius: 8 };

new Chart(document.getElementById('chartLatency'), {
  type: 'bar',
  data: {
    labels: DATA.labels.map(l => l.length > 34 ? l.slice(0,32)+'…' : l),
    datasets: [
      { label: 'Avg ms', data: DATA.avg, backgroundColor: tealSoft, borderRadius: 6, borderSkipped: false },
      { label: 'P95 ms', data: DATA.p95, backgroundColor: amber, borderRadius: 6, borderSkipped: false }
    ]
  },
  options: {
    indexAxis: 'y', responsive: true, maintainAspectRatio: false,
    scales: {
      x: { type: 'logarithmic', grid: { color: 'rgba(215,227,220,0.7)' }, title: { display: true, text: 'milliseconds (log)' } },
      y: { grid: { display: false }, ticks: { font: { size: 10 } } }
    },
    plugins: { legend: { position: 'top' }, tooltip: tip }
  }
});

new Chart(document.getElementById('chartGrades'), {
  type: 'doughnut',
  data: {
    labels: Object.keys(DATA.grades),
    datasets: [{
      data: Object.values(DATA.grades),
      backgroundColor: ['#059669', '#14b8a6', '#f59e0b', '#e11d48'],
      borderWidth: 0, hoverOffset: 8
    }]
  },
  options: {
    responsive: true, maintainAspectRatio: false, cutout: '62%',
    plugins: { legend: { position: 'bottom', labels: { usePointStyle: true, padding: 16 } }, tooltip: tip }
  }
});

new Chart(document.getElementById('chartCategory'), {
  type: 'bar',
  data: {
    labels: DATA.categories,
    datasets: [{ label: 'Avg ms', data: DATA.categoryAvg, backgroundColor: sky, borderRadius: 8, borderSkipped: false }]
  },
  options: {
    responsive: true, maintainAspectRatio: false,
    scales: { y: { beginAtZero: true, grid: { color: 'rgba(215,227,220,0.7)' } }, x: { grid: { display: false } } },
    plugins: { legend: { display: false }, tooltip: tip }
  }
});

new Chart(document.getElementById('chartRadar'), {
  type: 'radar',
  data: {
    labels: DATA.categories,
    datasets: [
      { label: 'Avg', data: DATA.categoryAvg, borderColor: teal, backgroundColor: 'rgba(15,118,110,0.18)', pointBackgroundColor: teal },
      { label: 'P95', data: DATA.categoryP95, borderColor: '#0284c7', backgroundColor: 'rgba(2,132,199,0.12)', pointBackgroundColor: '#0284c7' }
    ]
  },
  options: {
    responsive: true, maintainAspectRatio: false,
    scales: { r: { beginAtZero: true, angleLines: { color: '#d7e3dc' }, grid: { color: '#d7e3dc' }, pointLabels: { font: { size: 11 } } } },
    plugins: { legend: { position: 'bottom' }, tooltip: tip }
  }
});

new Chart(document.getElementById('chartStorage'), {
  type: 'doughnut',
  data: {
    labels: DATA.storage.map(s => s.schema),
    datasets: [{
      data: DATA.storage.map(s => s.mb),
      backgroundColor: ['#0f766e','#0891b2','#0284c7','#4f46e5','#059669','#ca8a04','#db2777','#64748b','#0ea5e9','#65a30d'],
      borderWidth: 0
    }]
  },
  options: {
    responsive: true, maintainAspectRatio: false, cutout: '55%',
    plugins: { legend: { position: 'bottom', labels: { boxWidth: 10, font: { size: 10 } } }, tooltip: tip }
  }
});

if (hasCompare) {
  const c = DATA.comparison;
  new Chart(document.getElementById('chartCompare'), {
    type: 'bar',
    data: {
      labels: c.map(x => x.name.length > 30 ? x.name.slice(0,28)+'…' : x.name),
      datasets: [
        { label: 'Before', data: c.map(x => x.before), backgroundColor: rose, borderRadius: 5, borderSkipped: false },
        { label: 'After', data: c.map(x => x.after), backgroundColor: emerald, borderRadius: 5, borderSkipped: false }
      ]
    },
    options: {
      indexAxis: 'y', responsive: true, maintainAspectRatio: false,
      scales: { x: { type: 'logarithmic', title: { display: true, text: 'ms (log)' } }, y: { ticks: { font: { size: 10 } }, grid: { display: false } } },
      plugins: { legend: { position: 'top' }, tooltip: tip }
    }
  });
  const wins = DATA.topWins;
  new Chart(document.getElementById('chartWins'), {
    type: 'bar',
    data: {
      labels: wins.map(x => x.name.length > 32 ? x.name.slice(0,30)+'…' : x.name),
      datasets: [{ label: '% faster', data: wins.map(x => x.improvement_pct), backgroundColor: tealSoft, borderRadius: 8, borderSkipped: false }]
    },
    options: {
      indexAxis: 'y', responsive: true, maintainAspectRatio: false,
      scales: { x: { beginAtZero: true, max: 100, title: { display: true, text: '% improvement' } }, y: { grid: { display: false } } },
      plugins: { legend: { display: false }, tooltip: tip }
    }
  });
} else {
  const slow = DATA.slowest;
  new Chart(document.getElementById('chartCompare'), {
    type: 'bar',
    data: {
      labels: slow.map(x => x.name.length > 30 ? x.name.slice(0,28)+'…' : x.name),
      datasets: [
        { label: 'Avg', data: slow.map(x => x.avg), backgroundColor: tealSoft, borderRadius: 6 },
        { label: 'P95', data: slow.map(x => x.p95), backgroundColor: amber, borderRadius: 6 }
      ]
    },
    options: {
      indexAxis: 'y', responsive: true, maintainAspectRatio: false,
      plugins: { legend: { position: 'top' }, tooltip: tip }
    }
  });
  const tables = DATA.inventory.hottest_tables.slice(0, 8);
  new Chart(document.getElementById('chartWins'), {
    type: 'bar',
    data: {
      labels: tables.map(t => t.relation),
      datasets: [{ label: 'Size (MB)', data: tables.map(t => Math.round(Number(t.bytes)/1024/1024)), backgroundColor: sky, borderRadius: 8 }]
    },
    options: {
      indexAxis: 'y', responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false }, tooltip: tip }
    }
  });
}
</script>
</body>
</html>`;
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

async function regenerateHtmlOnly() {
  fs.mkdirSync(OUT_DIR, { recursive: true });
  const jsonPath = path.join(OUT_DIR, `perf-benchmark${OUT_SUFFIX}.json`);
  if (!fs.existsSync(jsonPath)) {
    throw new Error(`Missing ${jsonPath} — run a full benchmark first`);
  }
  const report = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  const md = renderMarkdown(report);
  const html = renderHtml(md, report, null);
  const mdPath = path.join(OUT_DIR, `perf-benchmark${OUT_SUFFIX}.md`);
  const htmlPath = path.join(OUT_DIR, `perf-benchmark${OUT_SUFFIX}.html`);
  fs.writeFileSync(mdPath, md);
  fs.writeFileSync(htmlPath, html);
  console.log('Regenerated:');
  console.log(`  ${htmlPath}`);
  console.log(`  ${mdPath}`);
}

async function main() {
  if (args['html-only']) {
    await regenerateHtmlOnly();
    return;
  }

  fs.mkdirSync(OUT_DIR, { recursive: true });
  const client = await pool.connect();
  const report = {
    generatedAt: new Date().toISOString(),
    rounds: ROUNDS,
    runtime: null,
    inventory: null,
    benchmarks: [],
    explains: [],
  };

  try {
    await client.query('SET statement_timeout = 0');
    if (IS_LOCAL) {
      await client.query('SET max_parallel_workers_per_gather = 4');
      await client.query('SET work_mem = \'64MB\'');
      await client.query('SET enable_partitionwise_aggregate = on');
    }
    console.log('Collecting runtime + inventory...');
    report.runtime = {
      client: collectClientEnv(),
      postgres: await collectPostgresEnv(client),
    };
    report.inventory = await inventory(client);

    console.log('Preparing isolated DML fixtures...');
    const fx = await setupBenchFixtures(client);

    // Sample keys from PERF data
    const sampleOrg = (
      await client.query(
        `SELECT id FROM organizations WHERE slug LIKE 'perf-%' ORDER BY slug LIMIT 1`
      )
    ).rows[0];
    const sampleBranch = (
      await client.query(
        `SELECT id FROM branches WHERE organization_id = $1 LIMIT 1`,
        [sampleOrg.id]
      )
    ).rows[0];
    const sampleAppt = (
      await client.query(
        `SELECT id, booking_number, end_user_ref FROM appointments.appointments
         WHERE booking_number LIKE 'PERF-APT-%' ORDER BY created_at DESC LIMIT 1`
      )
    ).rows[0];
    const sampleEmp = (
      await client.query(
        `SELECT id FROM employee.employees WHERE organization_id = $1 LIMIT 1`,
        [sampleOrg.id]
      )
    ).rows[0];

    const tests = [];

    // --- Point lookups ---
    tests.push(() =>
      bench(
        client,
        'GET organization by slug (unique)',
        'point_lookup',
        `SELECT id, name, status, owner_email FROM organizations WHERE slug = $1`,
        ['perf-org-0001']
      )
    );
    tests.push(() =>
      bench(
        client,
        'GET appointment by booking_number (unique)',
        'point_lookup',
        `SELECT id, status, starts_at, gross_amount FROM appointments.appointments WHERE booking_number = $1`,
        [sampleAppt.booking_number]
      )
    );
    tests.push(() =>
      bench(
        client,
        'GET EUT by transaction_ref (unique)',
        'point_lookup',
        `SELECT id, gross_amount, status, net_to_salon FROM rms.end_user_transactions WHERE transaction_ref = $1`,
        ['PERF-EUT-0001-1-002']
      )
    );
    tests.push(() =>
      bench(
        client,
        'GET employee by org + employee_number',
        'point_lookup',
        `SELECT id, full_name, status FROM employee.employees
         WHERE organization_id = $1 AND employee_number = $2`,
        [sampleOrg.id, 'EMP-0001-1-1']
      )
    );

    // --- Range scans ---
    tests.push(() =>
      bench(
        client,
        'List appointments for branch (30-day window)',
        'range_scan',
        `SELECT id, booking_number, status, starts_at, gross_amount
         FROM appointments.appointments
         WHERE branch_id = $1 AND starts_at >= NOW() - INTERVAL '45 days'
         ORDER BY starts_at DESC LIMIT 50`,
        [sampleBranch.id]
      )
    );
    tests.push(() =>
      bench(
        client,
        'Filter appointments by status + org',
        'range_scan',
        `SELECT id, booking_number, starts_at FROM appointments.appointments
         WHERE organization_id = $1 AND status = 'COMPLETED'
         ORDER BY starts_at DESC LIMIT 100`,
        [sampleOrg.id]
      )
    );
    tests.push(() =>
      bench(
        client,
        'Attendance for employee (date range)',
        'range_scan',
        `SELECT attendance_date, status, check_in_at, check_out_at
         FROM employee.attendance_records
         WHERE employee_id = $1
         ORDER BY attendance_date DESC LIMIT 30`,
        [sampleEmp.id]
      )
    );
    tests.push(() =>
      bench(
        client,
        'EUT success list for org (recent)',
        'range_scan',
        `SELECT transaction_ref, gross_amount, net_to_salon, occurred_at
         FROM rms.end_user_transactions
         WHERE organization_id = $1 AND status = 'SUCCESS'
         ORDER BY occurred_at DESC LIMIT 100`,
        [sampleOrg.id]
      )
    );

    // --- Joins ---
    tests.push(() =>
      bench(
        client,
        'Appointment + service + specialist join',
        'join',
        `SELECT a.booking_number, a.status, a.starts_at, s.name AS service, e.full_name AS specialist, a.gross_amount
         FROM appointments.appointments a
         JOIN services.branch_services s ON s.id = a.branch_service_id
         LEFT JOIN employee.employees e ON e.id = a.specialist_id
         WHERE a.organization_id = $1
         ORDER BY a.starts_at DESC
         LIMIT 50`,
        [sampleOrg.id]
      )
    );
    tests.push(() =>
      bench(
        client,
        'EUT + appointment + branch join',
        'join',
        `SELECT e.transaction_ref, e.gross_amount, e.commission_amount, a.booking_number, b.name AS branch
         FROM rms.end_user_transactions e
         LEFT JOIN appointments.appointments a ON a.booking_number = e.booking_ref
         JOIN branches b ON b.id = e.branch_id
         WHERE e.organization_id = $1
         ORDER BY e.occurred_at DESC LIMIT 50`,
        [sampleOrg.id]
      )
    );
    tests.push(() =>
      bench(
        client,
        'Branch services with specialist count',
        'join',
        `SELECT s.name, s.price, s.duration_minutes, COUNT(ss.employee_id)::int AS specialists
         FROM services.branch_services s
         LEFT JOIN services.branch_service_specialists ss ON ss.branch_service_id = s.id
         WHERE s.branch_id = $1 AND s.status = 'ACTIVE'
         GROUP BY s.id, s.name, s.price, s.duration_minutes
         ORDER BY s.sort_order`,
        [sampleBranch.id]
      )
    );
    tests.push(() =>
      bench(
        client,
        'Invoice + line items + payment join',
        'join',
        `SELECT i.invoice_number, i.total_amount, i.status, COUNT(ili.id)::int AS lines,
                COALESCE(SUM(ip.amount_applied),0) AS paid
         FROM rms.invoices i
         LEFT JOIN rms.invoice_line_items ili ON ili.invoice_id = i.id
         LEFT JOIN rms.invoice_payments ip ON ip.invoice_id = i.id
         WHERE i.organization_id = $1
         GROUP BY i.id
         ORDER BY i.issue_date DESC`,
        [sampleOrg.id]
      )
    );

    // --- Analytics (expensive) ---
    tests.push(() =>
      bench(
        client,
        'Org revenue rollup (EUT sum/count by day)',
        'analytics',
        `SELECT date_trunc('day', occurred_at) AS day,
                COUNT(*)::int AS txns,
                SUM(gross_amount) AS gross,
                SUM(commission_amount) AS commission,
                SUM(net_to_salon) AS net
         FROM rms.end_user_transactions
         WHERE organization_id = $1 AND status = 'SUCCESS'
         GROUP BY 1 ORDER BY 1 DESC`,
        [sampleOrg.id]
      )
    );
    tests.push(() =>
      bench(
        client,
        'Platform-wide appointment status histogram',
        'analytics',
        `SELECT status, COUNT(*)::int AS n, ROUND(AVG(gross_amount)::numeric, 2) AS avg_gross
         FROM appointments.appointments
         WHERE booking_number >= 'PERF-APT-' AND booking_number < 'PERF-APT.'
         GROUP BY status
         ORDER BY n DESC`
      )
    );
    tests.push(() =>
      bench(
        client,
        'Top 20 branches by completed booking GMV',
        'analytics',
        `SELECT b.name, o.slug AS org, x.completed, x.gmv
         FROM (
           SELECT branch_id,
                  COUNT(*)::int AS completed,
                  SUM(gross_amount) AS gmv
           FROM appointments.appointments
           WHERE status = 'COMPLETED'
             AND booking_number >= 'PERF-APT-' AND booking_number < 'PERF-APT.'
           GROUP BY branch_id
           ORDER BY gmv DESC NULLS LAST
           LIMIT 20
         ) x
         JOIN branches b ON b.id = x.branch_id
         JOIN organizations o ON o.id = b.organization_id
         ORDER BY x.gmv DESC`
      )
    );
    tests.push(() =>
      bench(
        client,
        'Specialist utilization (appt hours / specialist)',
        'analytics',
        `SELECT e.full_name, e.employee_number,
                COUNT(*)::int AS bookings,
                SUM(a.service_duration_min)::int AS minutes,
                ROUND(AVG(a.gross_amount)::numeric, 2) AS avg_ticket
         FROM appointments.appointments a
         JOIN employee.employees e ON e.id = a.specialist_id
         WHERE a.organization_id = $1 AND a.status IN ('COMPLETED','CONFIRMED','NO_SHOW')
         GROUP BY e.id
         ORDER BY minutes DESC`,
        [sampleOrg.id]
      )
    );
    tests.push(() =>
      bench(
        client,
        'Attendance present-rate by branch (window)',
        'analytics',
        `SELECT b.name,
                COUNT(*)::int AS records,
                COUNT(*) FILTER (WHERE ar.status = 'PRESENT')::int AS present,
                ROUND(100.0 * COUNT(*) FILTER (WHERE ar.status = 'PRESENT') / NULLIF(COUNT(*),0), 1) AS present_pct
         FROM employee.attendance_records ar
         JOIN branches b ON b.id = ar.branch_id
         WHERE ar.organization_id = $1
         GROUP BY b.id, b.name
         ORDER BY present_pct DESC`,
        [sampleOrg.id]
      )
    );
    tests.push(() =>
      bench(
        client,
        'Running GMV window (org appointments)',
        'analytics',
        `SELECT booking_number, starts_at, gross_amount,
                SUM(gross_amount) OVER (ORDER BY starts_at ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_gmv
         FROM appointments.appointments
         WHERE organization_id = $1 AND status = 'COMPLETED'
         ORDER BY starts_at
         LIMIT 200`,
        [sampleOrg.id]
      )
    );
    tests.push(() =>
      bench(
        client,
        'Cross-schema merchant payable vs appointments',
        'analytics',
        `SELECT o.slug,
                COALESCE(ap.appts, 0)::int AS appts,
                COALESCE(eu.euts, 0)::int AS euts,
                COALESCE(eu.payable_accrued, 0) AS payable_accrued
         FROM organizations o
         LEFT JOIN LATERAL (
           SELECT COUNT(*)::bigint AS appts
           FROM appointments.appointments a
           WHERE a.organization_id = o.id
             AND a.booking_number >= 'PERF-APT-' AND a.booking_number < 'PERF-APT.'
         ) ap ON TRUE
         LEFT JOIN LATERAL (
           SELECT COUNT(*)::bigint AS euts,
                  COALESCE(SUM(e.net_to_salon), 0) AS payable_accrued
           FROM rms.end_user_transactions e
           WHERE e.organization_id = o.id
             AND e.transaction_ref >= 'PERF-EUT-' AND e.transaction_ref < 'PERF-EUT.'
         ) eu ON TRUE
         WHERE o.slug >= 'perf-org-00' AND o.slug < 'perf-org-01'
         ORDER BY payable_accrued DESC
         LIMIT 50`
      )
    );

    // --- Writes (isolated bench org) ---
    let insertCounter = 0;
    tests.push(() =>
      bench(
        client,
        'INSERT appointment (single row)',
        'write',
        `INSERT INTO appointments.appointments (
           booking_number, organization_id, branch_id, branch_service_id, specialist_id,
           end_user_ref, end_user_name, service_name, service_duration_min,
           starts_at, ends_at, status, source, list_price, discount_amount, gross_amount,
           payment_method, payment_status
         ) VALUES (
           $1, $2, $3, $4, $5,
           'EU-BENCH', 'Bench User', 'Bench Cut', 30,
           NOW() + ($6 || ' minutes')::interval,
           NOW() + (($6)::int + 30 || ' minutes')::interval,
           'BOOKED', 'CONSUMER_APP', 499, 0, 499, 'ONLINE', 'PENDING'
         )`,
        () => {
          insertCounter += 1;
          return [
            `PERF-BENCH-APT-${Date.now()}-${insertCounter}`,
            fx.orgId,
            fx.branchId,
            fx.svcId,
            fx.empId,
            String(insertCounter * 35),
          ];
        }
      )
    );
    tests.push(() =>
      bench(
        client,
        'UPDATE appointment status BOOKED→CONFIRMED',
        'write',
        `UPDATE appointments.appointments
         SET status = 'CONFIRMED', confirmed_at = NOW(), updated_at = NOW(), payment_status = 'PAID'
         WHERE organization_id = $1 AND booking_number LIKE 'PERF-BENCH-APT-%' AND status = 'BOOKED'
         RETURNING id`,
        [fx.orgId]
      )
    );
    tests.push(() =>
      bench(
        client,
        'INSERT attendance row',
        'write',
        `INSERT INTO employee.attendance_records (
           organization_id, branch_id, employee_id, attendance_date,
           check_in_at, check_out_at, status, source, marked_by_ref
         ) VALUES (
           $1, $2, $3, CURRENT_DATE + ($4 || ' days')::interval,
           NOW(), NOW() + INTERVAL '8 hours', 'PRESENT', 'SYSTEM', 'perf-bench'
         )
         ON CONFLICT (employee_id, attendance_date) DO UPDATE
           SET status = EXCLUDED.status, updated_at = NOW()
         RETURNING id`,
        (i) => [fx.orgId, fx.branchId, fx.empId, String(i + 1)]
      )
    );
    tests.push(() =>
      bench(
        client,
        'UPDATE org merchant balances',
        'write',
        `UPDATE rms.org_merchant_balances
         SET outstanding_amount = outstanding_amount + 10,
             pending_payout_amount = pending_payout_amount + 25,
             updated_at = NOW()
         WHERE organization_id = $1
         RETURNING outstanding_amount, pending_payout_amount`,
        [fx.orgId]
      )
    );
    tests.push(() =>
      bench(
        client,
        'DELETE bench appointments (cleanup slice)',
        'write',
        `DELETE FROM appointments.appointments
         WHERE organization_id = $1 AND booking_number LIKE 'PERF-BENCH-APT-%'
           AND status = 'CONFIRMED'
         RETURNING id`,
        [fx.orgId]
      )
    );

    // --- Mixed app-style ---
    tests.push(() =>
      bench(
        client,
        'Salon dashboard snapshot (multi-aggregate)',
        'mixed',
        `SELECT
           (SELECT COUNT(*) FROM appointments.appointments WHERE organization_id = $1 AND starts_at::date = CURRENT_DATE) AS todays_appts,
           (SELECT COUNT(*) FROM appointments.appointments WHERE organization_id = $1 AND status = 'COMPLETED') AS completed,
           (SELECT COALESCE(SUM(gross_amount),0) FROM rms.end_user_transactions WHERE organization_id = $1 AND status = 'SUCCESS') AS eut_gross,
           (SELECT COUNT(*) FROM employee.employees WHERE organization_id = $1 AND status = 'ACTIVE') AS active_staff,
           (SELECT COUNT(*) FROM services.branch_services WHERE organization_id = $1 AND status = 'ACTIVE') AS active_services`,
        [sampleOrg.id]
      )
    );
    tests.push(() =>
      bench(
        client,
        'End-user booking history by end_user_ref',
        'mixed',
        `SELECT booking_number, service_name, starts_at, status, gross_amount, payment_status
         FROM appointments.appointments
         WHERE end_user_ref = $1
         ORDER BY starts_at DESC LIMIT 20`,
        [sampleAppt.end_user_ref]
      )
    );

    console.log(`Running ${tests.length} benchmarks × ${ROUNDS} rounds...`);
    for (const t of tests) {
      const result = await t();
      report.benchmarks.push(result);
      const label = result.error
        ? `ERROR ${result.error.slice(0, 60)}`
        : `${result.stats.avg_ms} ms avg · ${result.grade}`;
      console.log(`  ✓ ${result.name} — ${label}`);
    }

    console.log('Running EXPLAIN ANALYZE profiles...');
    const explainTargets = [
      [
        'Branch appointments 45d',
        `SELECT id, booking_number, status, starts_at FROM appointments.appointments
         WHERE branch_id = $1 AND starts_at >= NOW() - INTERVAL '45 days'
         ORDER BY starts_at DESC LIMIT 50`,
        [sampleBranch.id],
      ],
      [
        'Org EUT daily rollup',
        `SELECT date_trunc('day', occurred_at) AS day, COUNT(*), SUM(gross_amount)
         FROM rms.end_user_transactions
         WHERE organization_id = $1 AND status = 'SUCCESS'
         GROUP BY 1 ORDER BY 1 DESC`,
        [sampleOrg.id],
      ],
      [
        'Top branches by GMV',
        `SELECT b.name, o.slug AS org, x.completed, x.gmv
         FROM (
           SELECT branch_id, COUNT(*)::int AS completed, SUM(gross_amount) AS gmv
           FROM appointments.appointments
           WHERE status = 'COMPLETED'
             AND booking_number >= 'PERF-APT-' AND booking_number < 'PERF-APT.'
           GROUP BY branch_id
           ORDER BY gmv DESC NULLS LAST
           LIMIT 20
         ) x
         JOIN branches b ON b.id = x.branch_id
         JOIN organizations o ON o.id = b.organization_id
         ORDER BY x.gmv DESC`,
        [],
      ],
      [
        'Appointment+service+specialist',
        `SELECT a.booking_number, s.name, e.full_name
         FROM appointments.appointments a
         JOIN services.branch_services s ON s.id = a.branch_service_id
         LEFT JOIN employee.employees e ON e.id = a.specialist_id
         WHERE a.organization_id = $1
         ORDER BY a.starts_at DESC LIMIT 50`,
        [sampleOrg.id],
      ],
    ];
    for (const [name, sql, params] of explainTargets) {
      try {
        const ex = await explainAnalyze(client, name, sql, params);
        // strip huge plan from markdown companion — keep summary fields
        report.explains.push({
          name: ex.name,
          planning_ms: ex.planning_ms,
          execution_ms: ex.execution_ms,
          total_cost: ex.total_cost,
          actual_rows: ex.actual_rows,
          node: ex.node,
          wall_ms: ex.wall_ms,
        });
        console.log(`  ✓ EXPLAIN ${name} — ${ex.execution_ms} ms exec`);
      } catch (e) {
        report.explains.push({ name, error: e.message });
        console.log(`  ✗ EXPLAIN ${name}: ${e.message}`);
      }
    }

    console.log('Cleaning bench fixtures...');
    await cleanupBenchFixtures(client);

    const md = renderMarkdown(report);
    const html = renderHtml(md, report, null);
    const jsonPath = path.join(OUT_DIR, `perf-benchmark${OUT_SUFFIX}.json`);
    const mdPath = path.join(OUT_DIR, `perf-benchmark${OUT_SUFFIX}.md`);
    const htmlPath = path.join(OUT_DIR, `perf-benchmark${OUT_SUFFIX}.html`);
    const pdfPath = path.join(OUT_DIR, `perf-benchmark${OUT_SUFFIX}.pdf`);

    // Full JSON includes explains summary; omit giant plan trees
    fs.writeFileSync(jsonPath, JSON.stringify(report, null, 2));
    fs.writeFileSync(mdPath, md);
    fs.writeFileSync(htmlPath, html);

    console.log('\nReports written:');
    console.log(`  ${mdPath}`);
    console.log(`  ${htmlPath}`);
    console.log(`  ${jsonPath}`);

    // Prefer HTML→PDF (charts) via puppeteer; fall back to markdown PDF
    try {
      const genPdf = path.join(__dirname, 'generate-perf-pdf.js');
      require('child_process').execFileSync(process.execPath, [genPdf, ...(IS_LOCAL ? ['--local'] : [])], {
        stdio: 'inherit',
        cwd: path.join(__dirname, '..'),
      });
    } catch (e) {
      try {
        const { mdToPdf } = require('md-to-pdf');
        const pdf = await mdToPdf({ path: mdPath }, { dest: pdfPath });
        if (pdf) console.log(`  ${pdfPath}`);
      } catch (e2) {
        console.log(`  (PDF skipped: ${e2.message})`);
      }
    }
  } finally {
    try {
      await cleanupBenchFixtures(client);
    } catch (_) {}
    client.release();
    await pool.end();
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
