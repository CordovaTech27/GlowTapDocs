/**
 * Interconnected performance seed (additive; keeps demo data).
 *
 * NOTE: Prefer scripts/bulk-seed-perf-append.js to ADD more orgs onto an
 * existing PERF load. This file’s --append/--start path had placeholder
 * breakage — use the append script for incremental loads.
 *
 *   node scripts/bulk-seed-perf-append.js --start=501 --orgs=350
 *   node scripts/cleanup-perf-seed.js   # wipe all PERF-* then reseed
 */
const { pool } = require('../connection');

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const m = a.match(/^--([^=]+)(?:=(.*))?$/);
    return m ? [m[1], m[2] === undefined ? true : m[2]] : [a, true];
  })
);

const ORG_COUNT = Number(args.orgs || 200);
const ORG_START = Number(args.start || 1);
const ORG_END = ORG_START + ORG_COUNT - 1;
const BRANCHES_PER_ORG = Number(args.branches || 5);
const EMP_PER_BRANCH = Number(args.emp || 8);
const SVC_PER_BRANCH = Number(args.services || 10);
const APPT_PER_BRANCH = Number(args.appts || 40);
const ATT_DAYS = Number(args.attendanceDays || 10);
const ORG_CHUNK = Number(args.chunk || 50);
const RESET = Boolean(args.reset);
const APPEND = Boolean(args.append) || ORG_START > 1;
/** @deprecated use ORG_END — kept for any leftover refs */
const ORGS = ORG_END;

function idExpr(kind, expr) {
  // Deterministic UUID from md5(kind || key)
  return `md5('${kind}' || (${expr})::text)::uuid`;
}

async function q(client, sql, params) {
  const started = Date.now();
  await client.query(sql, params);
  return Date.now() - started;
}

async function count(client, sql) {
  const { rows } = await client.query(sql);
  return Number(rows[0].n);
}

async function phase(client, name, fn) {
  process.stdout.write(`\nâ–¶ ${name} ... `);
  const ms = await fn();
  console.log(`done (${(ms / 1000).toFixed(1)}s)`);
}

async function main() {
  const client = await pool.connect();
  const t0 = Date.now();

  try {
    await client.query('SET statement_timeout = 0');
    await client.query('SET idle_in_transaction_session_timeout = 0');

    const existing = await count(
      client,
      `SELECT COUNT(*)::int AS n FROM organizations WHERE slug LIKE 'perf-%'`
    );

    if (existing > 0 && !RESET && !APPEND) {
      console.log(
        `Found ${existing} perf orgs already. Use --append --start=N --orgs=M to add more, or --reset to wipe.`
      );
      return;
    }

    if (RESET && existing > 0) {
      await phase(client, `Reset: delete ${existing} perf orgs (CASCADE)`, async () => {
        const ms = await q(
          client,
          `DELETE FROM organizations WHERE slug LIKE 'perf-%'`
        );
        return ms;
      });
    }

    console.log(
      `Seeding perf data: orgs ${ORG_START}..${ORG_END} (${ORG_COUNT}), ` +
        `${BRANCHES_PER_ORG} branches/org, ` +
        `${EMP_PER_BRANCH} emp/branch, ${SVC_PER_BRANCH} services/branch, ` +
        `${APPT_PER_BRANCH} appts/branch, ${ATT_DAYS} attendance days` +
        (APPEND ? ' [append]' : '')
    );

    const { rows: stateRows } = await client.query(
      `SELECT id FROM states ORDER BY code`
    );
    if (stateRows.length === 0) throw new Error('No states â€” run migrations first');
    const stateIds = stateRows.map((r) => r.id);

    const { rows: planRows } = await client.query(
      `SELECT id FROM subscription.subscription_plans ORDER BY amount`
    );
    const { rows: cycleRows } = await client.query(
      `SELECT id FROM rms.billing_cycles ORDER BY interval_months`
    );
    if (!planRows.length || !cycleRows.length) {
      throw new Error('Need subscription_plans and billing_cycles');
    }

    const { rows: subcatRows } = await client.query(`
      SELECT sc.id AS subcategory_id, sc.category_id, sc.name AS sub_name, cat.name AS cat_name
      FROM services.service_subcategories sc
      JOIN services.service_categories cat ON cat.id = sc.category_id
      WHERE sc.is_active AND cat.is_active
      ORDER BY cat.sort_order, sc.sort_order
    `);
    if (!subcatRows.length) throw new Error('No service subcategories');

    const { rows: ticketMeta } = await client.query(`
      SELECT t.id AS type_id, t.category_id, s.id AS subtype_id
      FROM tickets.support_ticket_types t
      LEFT JOIN tickets.support_ticket_subtypes s ON s.type_id = t.id
      ORDER BY t.code
      LIMIT 20
    `);
    if (!ticketMeta.length) throw new Error('No ticket types');

    const { rows: slaRows } = await client.query(
      `SELECT id FROM tickets.support_sla_policies LIMIT 1`
    );
    const slaId = slaRows[0]?.id || null;

    // Stash lookup arrays in session temp tables for SQL joins
    await client.query(`DROP TABLE IF EXISTS _perf_states`);
    await client.query(`CREATE TEMP TABLE _perf_states (ord int PRIMARY KEY, id uuid NOT NULL)`);
    for (let i = 0; i < stateIds.length; i++) {
      await client.query(`INSERT INTO _perf_states VALUES ($1,$2)`, [i, stateIds[i]]);
    }

    await client.query(`DROP TABLE IF EXISTS _perf_plans`);
    await client.query(`CREATE TEMP TABLE _perf_plans (ord int PRIMARY KEY, id uuid NOT NULL)`);
    for (let i = 0; i < planRows.length; i++) {
      await client.query(`INSERT INTO _perf_plans VALUES ($1,$2)`, [i, planRows[i].id]);
    }

    await client.query(`DROP TABLE IF EXISTS _perf_cycles`);
    await client.query(`CREATE TEMP TABLE _perf_cycles (ord int PRIMARY KEY, id uuid NOT NULL)`);
    for (let i = 0; i < cycleRows.length; i++) {
      await client.query(`INSERT INTO _perf_cycles VALUES ($1,$2)`, [i, cycleRows[i].id]);
    }

    await client.query(`DROP TABLE IF EXISTS _perf_subcats`);
    await client.query(`
      CREATE TEMP TABLE _perf_subcats (
        ord int PRIMARY KEY,
        subcategory_id uuid NOT NULL,
        category_id uuid NOT NULL,
        sub_name text NOT NULL,
        cat_name text NOT NULL
      )
    `);
    for (let i = 0; i < subcatRows.length; i++) {
      const s = subcatRows[i];
      await client.query(
        `INSERT INTO _perf_subcats VALUES ($1,$2,$3,$4,$5)`,
        [i, s.subcategory_id, s.category_id, s.sub_name, s.cat_name]
      );
    }

    await client.query(`DROP TABLE IF EXISTS _perf_ticket_types`);
    await client.query(`
      CREATE TEMP TABLE _perf_ticket_types (
        ord int PRIMARY KEY,
        type_id uuid NOT NULL,
        category_id uuid NOT NULL,
        subtype_id uuid
      )
    `);
    for (let i = 0; i < ticketMeta.length; i++) {
      const t = ticketMeta[i];
      await client.query(`INSERT INTO _perf_ticket_types VALUES ($1,$2,$3,$4)`, [
        i,
        t.type_id,
        t.category_id,
        t.subtype_id,
      ]);
    }

    // -------- Phase 1: organizations --------
    await phase(client, `Organizations (${ORGS})`, async () => {
      let total = 0;
      for (let start = ORG_START; start <= ORG_END; start += ORG_CHUNK) {
        const end = Math.min(ORG_END, start + ORG_CHUNK - 1);
        total += await q(
          client,
          `
          INSERT INTO organizations (
            id, name, slug, legal_name, owner_name, owner_email, owner_phone,
            gst_number, pan_number, registered_address, state_id,
            business_type, gst_registration_type, kyc_status, status,
            is_agreement_signed, onboarded_at, approved_at, created_at, updated_at
          )
          SELECT
            ${idExpr('perf-org-', 'g.i')},
            'Perf Salon ' || lpad(g.i::text, 4, '0'),
            'perf-org-' || lpad(g.i::text, 4, '0'),
            'Perf Salon ' || lpad(g.i::text, 4, '0') || ' Pvt Ltd',
            'Owner ' || g.i,
            'owner' || g.i || '@perf.glowtap.test',
            '9' || lpad((100000000 + g.i)::text, 9, '0'),
            '29ABCDE' || lpad((1000 + (g.i % 9000))::text, 4, '0') || 'F1Z' || (g.i % 5),
            'ABCDE' || lpad((1000 + (g.i % 9000))::text, 4, '0') || 'F',
            jsonb_build_object(
              'line1', g.i || ' MG Road',
              'city', (ARRAY['Bengaluru','Mumbai','Delhi','Hyderabad','Pune','Chennai'])[1 + (g.i % 6)],
              'pincode', lpad((560001 + (g.i % 400))::text, 6, '0'),
              'country', 'IN'
            ),
            (SELECT id FROM _perf_states WHERE ord = (g.i - 1) % (SELECT COUNT(*) FROM _perf_states)),
            (ARRAY['SOLE_PROPRIETOR','PARTNERSHIP','LLP','PRIVATE_LIMITED'])[1 + (g.i % 4)],
            'REGULAR',
            'VERIFIED',
            'ACTIVE',
            TRUE,
            NOW() - ((g.i % 200) || ' days')::interval,
            NOW() - ((g.i % 200) || ' days')::interval,
            NOW() - ((g.i % 200) || ' days')::interval,
            NOW()
          FROM generate_series($1::int, $2::int) AS g(i)
          `,
          [start, end]
        );
      }
      return total;
    });

    // -------- Phase 2: branches --------
    const branchTotal = ORG_COUNT * BRANCHES_PER_ORG;
    await phase(client, `Branches (${branchTotal})`, async () => {
      let total = 0;
      for (let start = ORG_START; start <= ORG_END; start += ORG_CHUNK) {
        const end = Math.min(ORG_END, start + ORG_CHUNK - 1);
        total += await q(
          client,
          `
          INSERT INTO branches (
            id, organization_id, name, slug, address, contact_phone, contact_email,
            operating_hours, weekly_off_days, status, is_primary, state_id,
            kyc_status, is_agreement_signed, approved_at, created_at, updated_at
          )
          SELECT
            ${idExpr('perf-br-', `o.i || '-' || b.n`)},
            ${idExpr('perf-org-', 'o.i')},
            'Branch ' || b.n,
            'br-' || b.n,
            jsonb_build_object(
              'line1', b.n || ' Cross Road',
              'city', (ARRAY['Bengaluru','Mumbai','Delhi','Hyderabad','Pune','Chennai'])[1 + ((o.i + b.n) % 6)],
              'pincode', lpad((560100 + ((o.i * 5 + b.n) % 800))::text, 6, '0'),
              'country', 'IN'
            ),
            '8' || lpad((200000000 + o.i * 10 + b.n)::text, 9, '0'),
            'branch' || o.i || '-' || b.n || '@perf.glowtap.test',
            jsonb_build_object(
              'mon', jsonb_build_object('open','10:00','close','20:00'),
              'tue', jsonb_build_object('open','10:00','close','20:00'),
              'wed', jsonb_build_object('open','10:00','close','20:00'),
              'thu', jsonb_build_object('open','10:00','close','20:00'),
              'fri', jsonb_build_object('open','10:00','close','20:00'),
              'sat', jsonb_build_object('open','10:00','close','21:00'),
              'sun', jsonb_build_object('open','11:00','close','18:00')
            ),
            ARRAY[(CASE WHEN b.n % 3 = 0 THEN 0 ELSE 3 END)::smallint],
            'ACTIVE',
            (b.n = 1),
            (SELECT id FROM _perf_states WHERE ord = (o.i - 1) % (SELECT COUNT(*) FROM _perf_states)),
            'VERIFIED',
            TRUE,
            NOW() - ((o.i % 100) || ' days')::interval,
            NOW() - ((o.i % 100) || ' days')::interval,
            NOW()
          FROM generate_series($1::int, $2::int) AS o(i)
          CROSS JOIN generate_series(1, $4::int) AS b(n)
          `,
          [start, end, BRANCHES_PER_ORG]
        );
      }
      return total;
    });

    // -------- Phase 3: bill structure + merchant balances --------
    await phase(client, `Bill structure + merchant balances (${ORGS})`, async () => {
      let ms = await q(
        client,
        `
        INSERT INTO rms.org_bill_structure (
          id, organization_id, subscription_plan_id, billing_cycle_id, state_id,
          start_date, renewal_date, payment_method, commission_pct, currency,
          auto_renew, status, created_at, updated_at
        )
        SELECT
          ${idExpr('perf-bill-', 'o.i')},
          ${idExpr('perf-org-', 'o.i')},
          (SELECT id FROM _perf_plans WHERE ord = (o.i - 1) % (SELECT COUNT(*) FROM _perf_plans)),
          (SELECT id FROM _perf_cycles WHERE ord = (o.i - 1) % (SELECT COUNT(*) FROM _perf_cycles)),
          (SELECT id FROM _perf_states WHERE ord = (o.i - 1) % (SELECT COUNT(*) FROM _perf_states)),
          (CURRENT_DATE - ((o.i % 60) || ' days')::interval)::date,
          (CURRENT_DATE + ((30 + o.i % 60) || ' days')::interval)::date,
          (ARRAY['UPI','CARD','NACH','NET_BANKING'])[1 + (o.i % 4)],
          5.00 + (o.i % 5),
          'INR',
          TRUE,
          'ACTIVE',
          NOW(), NOW()
        FROM generate_series($2::int, $3::int) AS o(i)
        `,
        [ORG_START, ORG_END]
      );
      ms += await q(
        client,
        `
        INSERT INTO rms.org_merchant_balances (
          organization_id, outstanding_amount, pending_payout_amount, currency, updated_at
        )
        SELECT
          ${idExpr('perf-org-', 'o.i')},
          (o.i % 50) * 100,
          (o.i % 80) * 250,
          'INR',
          NOW()
        FROM generate_series($1::int, $2::int) AS o(i)
        ON CONFLICT (organization_id) DO NOTHING
        `,
        [ORG_START, ORG_END]
      );
      return ms;
    });

    // -------- Phase 4: sub-admins --------
    await phase(client, `Sub-admins (${ORGS * 2})`, async () => {
      let ms = await q(
        client,
        `
        INSERT INTO admin_org.sub_admins (
          id, organization_id, full_name, email, phone, status, created_at, updated_at
        )
        SELECT
          ${idExpr('perf-sa-', `o.i || '-' || s.n`)},
          ${idExpr('perf-org-', 'o.i')},
          'Sub Admin ' || o.i || '-' || s.n,
          'sa' || o.i || '-' || s.n || '@perf.glowtap.test',
          '7' || lpad((300000000 + o.i * 10 + s.n)::text, 9, '0'),
          'ACTIVE',
          NOW(), NOW()
        FROM generate_series($1::int, $2::int) AS o(i)
        CROSS JOIN generate_series(1, 2) AS s(n)
        `,
        [ORG_START, ORG_END]
      );
      ms += await q(
        client,
        `
        INSERT INTO admin_org.sub_admin_branches (sub_admin_id, branch_id)
        SELECT
          ${idExpr('perf-sa-', `o.i || '-' || s.n`)},
          ${idExpr('perf-br-', `o.i || '-' || b.n`)}
        FROM generate_series($1::int, $2::int) AS o(i)
        CROSS JOIN generate_series(1, 2) AS s(n)
        CROSS JOIN generate_series(1, $3::int) AS b(n)
        WHERE b.n <= CASE WHEN s.n = 1 THEN $3 ELSE 2 END
        `,
        [ORG_START, ORG_END, BRANCHES_PER_ORG]
      );
      ms += await q(
        client,
        `
        INSERT INTO admin_org.sub_admin_modules (sub_admin_id, module)
        SELECT
          ${idExpr('perf-sa-', `o.i || '-' || s.n`)},
          m.code
        FROM generate_series($1::int, $2::int) AS o(i)
        CROSS JOIN generate_series(1, 2) AS s(n)
        CROSS JOIN (VALUES
          ('APPOINTMENTS'),('EMPLOYEES'),('SERVICES'),('ATTENDANCE'),
          ('LEAVE_HOLIDAYS'),('TRANSACTIONS'),('REPORTS'),('BRANCH_PROFILE')
        ) AS m(code)
        `,
        [ORG_START, ORG_END]
      );
      return ms;
    });

    // -------- Phase 5: employees + leave --------
    await phase(client, `Employees + leave types/policies/balances`, async () => {
      try {
        await client.query(
          `ALTER TABLE employee.employees DISABLE TRIGGER trg_employee_branch_same_org`
        );
      } catch (_) {
        /* ignore if no permission / missing */
      }

      let ms = 0;
      for (let start = ORG_START; start <= ORG_END; start += ORG_CHUNK) {
        const end = Math.min(ORG_END, start + ORG_CHUNK - 1);
        ms += await q(
          client,
          `
          INSERT INTO employee.employees (
            id, organization_id, branch_id, employee_number, full_name, email, phone,
            designation, date_of_joining, status, created_at, updated_at
          )
          SELECT
            ${idExpr('perf-emp-', `o.i || '-' || b.n || '-' || e.n`)},
            ${idExpr('perf-org-', 'o.i')},
            ${idExpr('perf-br-', `o.i || '-' || b.n`)},
            'EMP-' || lpad(o.i::text, 4, '0') || '-' || b.n || '-' || e.n,
            (ARRAY['Asha','Ravi','Neha','Imran','Priya','Karan','Sneha','Vikram'])[1 + ((e.n - 1) % 8)]
              || ' ' || (ARRAY['Sharma','Patel','Khan','Reddy','Nair','Iyer','Das','Mehta'])[1 + ((o.i + e.n) % 8)],
            'emp' || o.i || '-' || b.n || '-' || e.n || '@perf.glowtap.test',
            '6' || lpad((400000000 + o.i * 100 + b.n * 10 + e.n)::text, 9, '0'),
            (ARRAY['Stylist','Senior Stylist','Therapist','Receptionist','Colorist','Manager'])[1 + ((e.n - 1) % 6)],
            (CURRENT_DATE - ((180 + e.n * 10 + o.i % 90) || ' days')::interval)::date,
            'ACTIVE',
            NOW(), NOW()
          FROM generate_series($1::int, $2::int) AS o(i)
          CROSS JOIN generate_series(1, $4::int) AS b(n)
          CROSS JOIN generate_series(1, $5::int) AS e(n)
          `,
          [start, end, BRANCHES_PER_ORG, EMP_PER_BRANCH]
        );
      }

      ms += await q(
        client,
        `
        INSERT INTO employee.leave_types (
          id, organization_id, code, name, is_paid, is_active, sort_order, created_at, updated_at
        )
        SELECT
          ${idExpr('perf-lt-', `o.i || '-' || lt.code`)},
          ${idExpr('perf-org-', 'o.i')},
          lt.code,
          lt.name,
          TRUE,
          TRUE,
          lt.sort_order,
          NOW(), NOW()
        FROM generate_series($2::int, $3::int) AS o(i)
        CROSS JOIN (VALUES
          ('CL', 'Casual Leave', 10),
          ('SL', 'Sick Leave', 20),
          ('EL', 'Earned Leave', 30)
        ) AS lt(code, name, sort_order)
        `,
        [ORG_START, ORG_END]
      );

      ms += await q(
        client,
        `
        INSERT INTO employee.branch_leave_policies (
          id, organization_id, branch_id, leave_type_id,
          days_per_month, carry_forward_allowed, carry_forward_pct, leave_year_end_month,
          is_active, created_at, updated_at
        )
        SELECT
          ${idExpr('perf-blp-', `o.i || '-' || b.n || '-' || lt.code`)},
          ${idExpr('perf-org-', 'o.i')},
          ${idExpr('perf-br-', `o.i || '-' || b.n`)},
          ${idExpr('perf-lt-', `o.i || '-' || lt.code`)},
          lt.dpm,
          lt.cf,
          lt.cfp,
          3,
          TRUE,
          NOW(), NOW()
        FROM generate_series($1::int, $2::int) AS o(i)
        CROSS JOIN generate_series(1, $3::int) AS b(n)
        CROSS JOIN (VALUES
          ('CL', 1.0, FALSE, 0),
          ('SL', 1.0, FALSE, 0),
          ('EL', 1.5, TRUE, 50)
        ) AS lt(code, dpm, cf, cfp)
        `,
        [ORG_START, ORG_END, BRANCHES_PER_ORG]
      );

      // Leave balances â€” chunked
      for (let start = ORG_START; start <= ORG_END; start += ORG_CHUNK) {
        const end = Math.min(ORG_END, start + ORG_CHUNK - 1);
        ms += await q(
          client,
          `
          INSERT INTO employee.leave_balances (
            id, employee_id, leave_type_id, year, entitled_days, used_days, carried_forward, updated_at
          )
          SELECT
            ${idExpr('perf-lb-', `o.i || '-' || b.n || '-' || e.n || '-' || lt.code`)},
            ${idExpr('perf-emp-', `o.i || '-' || b.n || '-' || e.n`)},
            ${idExpr('perf-lt-', `o.i || '-' || lt.code`)},
            EXTRACT(YEAR FROM CURRENT_DATE)::int,
            lt.ent,
            (e.n % 3),
            CASE WHEN lt.code = 'EL' THEN 2 ELSE 0 END,
            NOW()
          FROM generate_series($1::int, $2::int) AS o(i)
          CROSS JOIN generate_series(1, $4::int) AS b(n)
          CROSS JOIN generate_series(1, $5::int) AS e(n)
          CROSS JOIN (VALUES ('CL', 12), ('SL', 12), ('EL', 18)) AS lt(code, ent)
          `,
          [start, end, BRANCHES_PER_ORG, EMP_PER_BRANCH]
        );
      }

      // ~0.5 leave requests per employee
      ms += await q(
        client,
        `
        INSERT INTO employee.leave_requests (
          id, organization_id, branch_id, employee_id, leave_type_id,
          start_date, end_date, total_days, status, reason, decided_by_ref, decided_at,
          created_at, updated_at
        )
        SELECT
          ${idExpr('perf-lr-', `o.i || '-' || b.n || '-' || e.n`)},
          ${idExpr('perf-org-', 'o.i')},
          ${idExpr('perf-br-', `o.i || '-' || b.n`)},
          ${idExpr('perf-emp-', `o.i || '-' || b.n || '-' || e.n`)},
          ${idExpr('perf-lt-', `o.i || '-' || (ARRAY['CL','SL','EL'])[1 + (e.n % 3)]`)},
          (CURRENT_DATE - ((e.n * 3 + b.n) || ' days')::interval)::date,
          (CURRENT_DATE - ((e.n * 3 + b.n) || ' days')::interval)::date,
          1,
          (ARRAY['APPROVED','APPROVED','PENDING','REJECTED'])[1 + (e.n % 4)],
          'Personal work',
          'sa' || o.i || '-1@perf.glowtap.test',
          NOW() - ((e.n) || ' days')::interval,
          NOW(), NOW()
        FROM generate_series($2::int, $3::int) AS o(i)
        CROSS JOIN generate_series(1, $3::int) AS b(n)
        CROSS JOIN generate_series(1, $4::int) AS e(n)
        WHERE e.n % 2 = 0
        `,
        [ORG_START, ORG_END, BRANCHES_PER_ORG, EMP_PER_BRANCH]
      );

      try {
        await client.query(
          `ALTER TABLE employee.employees ENABLE TRIGGER trg_employee_branch_same_org`
        );
      } catch (_) {}

      return ms;
    });

    // -------- Phase 6: branch services + specialists --------
    await phase(client, `Branch services + specialists`, async () => {
      try {
        await client.query(
          `ALTER TABLE services.branch_services DISABLE TRIGGER trg_branch_service_refs`
        );
        await client.query(
          `ALTER TABLE services.branch_service_specialists DISABLE TRIGGER trg_service_specialist_same_scope`
        );
      } catch (_) {}

      const serviceNames = [
        'Classic Hair Cut',
        'Hair Spa',
        'Beard Trim',
        'Hair Color',
        'Keratin',
        'Facial Glow',
        'Manicure',
        'Pedicure',
        'Head Massage',
        'Bridal Makeup',
      ];

      let ms = 0;
      for (let start = ORG_START; start <= ORG_END; start += ORG_CHUNK) {
        const end = Math.min(ORG_END, start + ORG_CHUNK - 1);
        ms += await q(
          client,
          `
          INSERT INTO services.branch_services (
            id, organization_id, branch_id, category_id, subcategory_id,
            name, description, price, currency, duration_minutes,
            discount_percent, offline_payment_allowed, status, sort_order,
            created_at, updated_at
          )
          SELECT
            ${idExpr('perf-svc-', `o.i || '-' || b.n || '-' || s.n`)},
            ${idExpr('perf-org-', 'o.i')},
            ${idExpr('perf-br-', `o.i || '-' || b.n`)},
            sc.category_id,
            sc.subcategory_id,
            names.nm,
            names.nm || ' at branch ' || b.n,
            (299 + (s.n * 100) + (o.i % 50))::numeric,
            'INR',
            (ARRAY[30,45,60,45,90,60,45,45,30,120])[s.n],
            CASE WHEN s.n % 4 = 0 THEN 10 ELSE NULL END,
            TRUE,
            'ACTIVE',
            s.n * 10,
            NOW(), NOW()
          FROM generate_series($1::int, $2::int) AS o(i)
          CROSS JOIN generate_series(1, $4::int) AS b(n)
          CROSS JOIN generate_series(1, $5::int) AS s(n)
          JOIN _perf_subcats sc ON sc.ord = (s.n - 1) % (SELECT COUNT(*) FROM _perf_subcats)
          JOIN (SELECT * FROM unnest($6::text[]) WITH ORDINALITY AS x(nm, n)) names ON names.n = s.n
          `,
          [start, end, BRANCHES_PER_ORG, SVC_PER_BRANCH, serviceNames]
        );
      }

      // 2 specialists per service (employees 1..2 of same branch)
      for (let start = ORG_START; start <= ORG_END; start += ORG_CHUNK) {
        const end = Math.min(ORG_END, start + ORG_CHUNK - 1);
        ms += await q(
          client,
          `
          INSERT INTO services.branch_service_specialists (
            branch_service_id, employee_id, is_primary, created_at
          )
          SELECT
            ${idExpr('perf-svc-', `o.i || '-' || b.n || '-' || s.n`)},
            ${idExpr('perf-emp-', `o.i || '-' || b.n || '-' || sp.n`)},
            (sp.n = 1),
            NOW()
          FROM generate_series($2::int, $3::int) AS o(i)
          CROSS JOIN generate_series(1, $4::int) AS b(n)
          CROSS JOIN generate_series(1, $5::int) AS s(n)
          CROSS JOIN generate_series(1, 2) AS sp(n)
          `,
          [start, end, BRANCHES_PER_ORG, SVC_PER_BRANCH]
        );
      }

      try {
        await client.query(
          `ALTER TABLE services.branch_services ENABLE TRIGGER trg_branch_service_refs`
        );
        await client.query(
          `ALTER TABLE services.branch_service_specialists ENABLE TRIGGER trg_service_specialist_same_scope`
        );
      } catch (_) {}

      return ms;
    });

    // -------- Phase 7: appointments + status events --------
    await phase(client, `Appointments + status events`, async () => {
      try {
        await client.query(
          `ALTER TABLE appointments.appointments DISABLE TRIGGER trg_appointment_scope`
        );
      } catch (_) {}

      let ms = 0;
      for (let start = ORG_START; start <= ORG_END; start += Math.min(ORG_CHUNK, 25)) {
        const end = Math.min(ORG_END, start + Math.min(ORG_CHUNK, 25) - 1);
        ms += await q(
          client,
          `
          INSERT INTO appointments.appointments (
            id, booking_number, organization_id, branch_id, branch_service_id, specialist_id,
            end_user_ref, end_user_name, end_user_phone, end_user_email,
            service_name, service_duration_min, starts_at, ends_at,
            status, source, list_price, discount_amount, gross_amount,
            payment_method, payment_status, confirmed_at, completed_at, cancelled_at, no_show_at,
            created_at, updated_at
          )
          SELECT
            ${idExpr('perf-apt-', `o.i || '-' || b.n || '-' || a.n`)},
            'PERF-APT-' || lpad(o.i::text, 4, '0') || '-' || b.n || '-' || lpad(a.n::text, 3, '0'),
            ${idExpr('perf-org-', 'o.i')},
            ${idExpr('perf-br-', `o.i || '-' || b.n`)},
            ${idExpr('perf-svc-', `o.i || '-' || b.n || '-' || ((a.n - 1) % $5 + 1)`)},
            ${idExpr('perf-emp-', `o.i || '-' || b.n || '-' || ((a.n - 1) % $6 + 1)`)},
            'EU-PERF-' || lpad(((o.i * 1000 + b.n * 100 + a.n) % 50000)::text, 5, '0'),
            (ARRAY['Ananya','Rahul','Meera','Arjun','Diya','Kabir','Isha','Rohan'])[1 + (a.n % 8)]
              || ' ' || (ARRAY['Rao','Singh','Gupta','Joshi','Kapoor','Ali','Fernandes','Pillai'])[1 + ((o.i + a.n) % 8)],
            '9' || lpad((500000000 + ((o.i * 97 + a.n) % 499999999))::text, 9, '0'),
            'user' || ((o.i * 1000 + a.n) % 50000) || '@perf.glowtap.test',
            (ARRAY[
              'Classic Hair Cut','Hair Spa','Beard Trim','Hair Color','Keratin',
              'Facial Glow','Manicure','Pedicure','Head Massage','Bridal Makeup'
            ])[((a.n - 1) % $5) + 1],
            (ARRAY[30,45,60,45,90,60,45,45,30,120])[((a.n - 1) % $5) + 1],
            (
              date_trunc('day', NOW() - ((a.n % 45) || ' days')::interval)
              + TIME '10:00'
              + make_interval(mins => ((a.n * 30) % 480))
            ),
            (
              date_trunc('day', NOW() - ((a.n % 45) || ' days')::interval)
              + TIME '10:00'
              + make_interval(mins => ((a.n * 30) % 480))
              + make_interval(mins => (ARRAY[30,45,60,45,90,60,45,45,30,120])[((a.n - 1) % $5) + 1])
            ),
            st.status,
            (ARRAY['CONSUMER_APP','CONSUMER_APP','WALK_IN','ADMIN'])[1 + (a.n % 4)],
            (299 + ((((a.n - 1) % $5) + 1) * 100))::numeric,
            CASE WHEN a.n % 5 = 0 THEN 50 ELSE 0 END,
            (299 + ((((a.n - 1) % $5) + 1) * 100) - CASE WHEN a.n % 5 = 0 THEN 50 ELSE 0 END)::numeric,
            CASE WHEN a.n % 7 = 0 THEN 'OFFLINE' ELSE 'ONLINE' END,
            CASE
              WHEN st.status IN ('COMPLETED','CONFIRMED','IN_PROGRESS') THEN 'PAID'
              WHEN st.status = 'CANCELLED' THEN 'REFUNDED'
              WHEN st.status = 'NO_SHOW' THEN 'PAID'
              ELSE 'PENDING'
            END,
            CASE WHEN st.status IN ('CONFIRMED','IN_PROGRESS','COMPLETED','NO_SHOW') THEN NOW() - ((a.n % 40) || ' days')::interval END,
            CASE WHEN st.status = 'COMPLETED' THEN NOW() - ((a.n % 30) || ' days')::interval END,
            CASE WHEN st.status = 'CANCELLED' THEN NOW() - ((a.n % 20) || ' days')::interval END,
            CASE WHEN st.status = 'NO_SHOW' THEN NOW() - ((a.n % 15) || ' days')::interval END,
            NOW() - ((a.n % 45) || ' days')::interval,
            NOW()
          FROM generate_series($2::int, $3::int) AS o(i)
          CROSS JOIN generate_series(1, $4::int) AS b(n)
          CROSS JOIN generate_series(1, $7::int) AS a(n)
          CROSS JOIN LATERAL (
            SELECT (ARRAY[
              'COMPLETED','COMPLETED','COMPLETED','COMPLETED','COMPLETED',
              'CONFIRMED','CONFIRMED','BOOKED','CANCELLED','NO_SHOW'
            ])[1 + (a.n % 10)] AS status
          ) st
          `,
          [start, end, BRANCHES_PER_ORG, SVC_PER_BRANCH, EMP_PER_BRANCH, APPT_PER_BRANCH]
        );

        ms += await q(
          client,
          `
          INSERT INTO appointments.appointment_status_events (
            id, appointment_id, from_status, to_status, performed_by_type, performed_by_ref, performed_at
          )
          SELECT
            ${idExpr('perf-ase-', `o.i || '-' || b.n || '-' || a.n`)},
            ${idExpr('perf-apt-', `o.i || '-' || b.n || '-' || a.n`)},
            NULL,
            ap.status,
            'SYSTEM',
            'bulk-seed',
            ap.created_at
          FROM generate_series($2::int, $3::int) AS o(i)
          CROSS JOIN generate_series(1, $4::int) AS b(n)
          CROSS JOIN generate_series(1, $5::int) AS a(n)
          JOIN appointments.appointments ap
            ON ap.id = ${idExpr('perf-apt-', `o.i || '-' || b.n || '-' || a.n`)}
          `,
          [start, end, BRANCHES_PER_ORG, APPT_PER_BRANCH]
        );
      }

      try {
        await client.query(
          `ALTER TABLE appointments.appointments ENABLE TRIGGER trg_appointment_scope`
        );
      } catch (_) {}

      return ms;
    });

    // -------- Phase 8: EUT + ledger (completed + paid online subset) --------
    await phase(client, `EUT + merchant ledger`, async () => {
      let ms = 0;
      for (let start = ORG_START; start <= ORG_END; start += Math.min(ORG_CHUNK, 25)) {
        const end = Math.min(ORG_END, start + Math.min(ORG_CHUNK, 25) - 1);
        // ~half of appointments become EUT (a.n % 2 = 0 and status completed-ish via formula)
        ms += await q(
          client,
          `
          WITH chosen AS (
            SELECT
              o.i AS oi, b.n AS bn, a.n AS an,
              ap.id AS appt_id,
              ap.organization_id,
              ap.branch_id,
              ap.booking_number,
              ap.end_user_ref,
              ap.gross_amount,
              ap.service_name,
              ap.completed_at,
              ap.starts_at
            FROM generate_series($2::int, $3::int) AS o(i)
            CROSS JOIN generate_series(1, $4::int) AS b(n)
            CROSS JOIN generate_series(1, $5::int) AS a(n)
            JOIN appointments.appointments ap
              ON ap.id = ${idExpr('perf-apt-', `o.i || '-' || b.n || '-' || a.n`)}
            WHERE a.n % 2 = 0
              AND ap.status IN ('COMPLETED', 'CONFIRMED', 'NO_SHOW')
              AND ap.payment_method = 'ONLINE'
          )
          INSERT INTO rms.end_user_transactions (
            id, transaction_ref, organization_id, branch_id, booking_ref, end_user_ref,
            payment_channel, collection_model, gross_amount, commission_pct, commission_amount,
            gateway_fee_amount, net_to_salon, currency, payment_method, status,
            gateway, gateway_order_id, gateway_payment_id,
            service_details, occurred_at, created_at, updated_at
          )
          SELECT
            ${idExpr('perf-eut-', `c.oi || '-' || c.bn || '-' || c.an`)},
            'PERF-EUT-' || lpad(c.oi::text, 4, '0') || '-' || c.bn || '-' || lpad(c.an::text, 3, '0'),
            c.organization_id,
            c.branch_id,
            c.booking_number,
            c.end_user_ref,
            'ONLINE',
            'MARKETPLACE',
            c.gross_amount,
            5.00,
            ROUND(c.gross_amount * 0.05, 2),
            ROUND(c.gross_amount * 0.02, 2),
            ROUND(c.gross_amount - c.gross_amount * 0.05 - c.gross_amount * 0.02, 2),
            'INR',
            'UPI',
            'SUCCESS',
            'RAZORPAY',
            'order_perf_' || c.oi || '_' || c.bn || '_' || c.an,
            'pay_perf_' || c.oi || '_' || c.bn || '_' || c.an,
            jsonb_build_object('service', c.service_name),
            COALESCE(c.completed_at, c.starts_at),
            NOW(), NOW()
          FROM chosen c
          `,
          [start, end, BRANCHES_PER_ORG, APPT_PER_BRANCH]
        );

        ms += await q(
          client,
          `
          UPDATE appointments.appointments ap
          SET eut_transaction_id = ${idExpr('perf-eut-', `o.i || '-' || b.n || '-' || a.n`)}
          FROM generate_series($2::int, $3::int) AS o(i)
          CROSS JOIN generate_series(1, $4::int) AS b(n)
          CROSS JOIN generate_series(1, $5::int) AS a(n)
          WHERE ap.id = ${idExpr('perf-apt-', `o.i || '-' || b.n || '-' || a.n`)}
            AND a.n % 2 = 0
            AND EXISTS (
              SELECT 1 FROM rms.end_user_transactions e
              WHERE e.id = ${idExpr('perf-eut-', `o.i || '-' || b.n || '-' || a.n`)}
            )
          `,
          [start, end, BRANCHES_PER_ORG, APPT_PER_BRANCH]
        );

        ms += await q(
          client,
          `
          INSERT INTO rms.merchant_ledger_entries (
            id, organization_id, balance_bucket, direction, entry_type, amount, balance_after,
            currency, end_user_transaction_id, description, occurred_at, created_at
          )
          SELECT
            ${idExpr('perf-led-', `o.i || '-' || b.n || '-' || a.n`)},
            ${idExpr('perf-org-', 'o.i')},
            'PAYABLE',
            'INCREASE',
            'PAYABLE_ACCRUAL',
            e.net_to_salon,
            e.net_to_salon,
            'INR',
            e.id,
            'Perf seed accrual for ' || e.transaction_ref,
            e.occurred_at,
            NOW()
          FROM generate_series($2::int, $3::int) AS o(i)
          CROSS JOIN generate_series(1, $4::int) AS b(n)
          CROSS JOIN generate_series(1, $5::int) AS a(n)
          JOIN rms.end_user_transactions e
            ON e.id = ${idExpr('perf-eut-', `o.i || '-' || b.n || '-' || a.n`)}
          `,
          [start, end, BRANCHES_PER_ORG, APPT_PER_BRANCH]
        );
      }
      return ms;
    });

    // -------- Phase 9: payouts (headers + sample items) --------
    await phase(client, `Salon payouts`, async () => {
      let ms = await q(
        client,
        `
        INSERT INTO rms.salon_payouts (
          id, payout_number, organization_id, status, currency,
          gross_collected, commission_deducted, gateway_fees_deducted, outstanding_recovered,
          net_payout_amount, gateway, period_start, period_end, paid_at, created_at, updated_at
        )
        SELECT
          ${idExpr('perf-po-', `o.i || '-' || p.n`)},
          'PERF-PO-' || lpad(o.i::text, 4, '0') || '-' || p.n,
          ${idExpr('perf-org-', 'o.i')},
          'PAID',
          'INR',
          50000 + (o.i % 100) * 100,
          2500 + (o.i % 50) * 10,
          1000,
          0,
          46500 + (o.i % 100) * 90,
          'RAZORPAY',
          NOW() - ((p.n * 30 + 30) || ' days')::interval,
          NOW() - ((p.n * 30) || ' days')::interval,
          NOW() - ((p.n * 30 - 1) || ' days')::interval,
          NOW(), NOW()
        FROM generate_series($2::int, $3::int) AS o(i)
        CROSS JOIN generate_series(1, 6) AS p(n)
        `,
        [ORG_START, ORG_END]
      );
      // Link a small slice of EUT to payouts + payout items
      ms += await q(
        client,
        `
        UPDATE rms.end_user_transactions e
        SET salon_payout_id = ${idExpr('perf-po-', `o.i || '-' || ((a.n % 6) + 1)`)}
        FROM generate_series($1::int, $2::int) AS o(i)
        CROSS JOIN generate_series(1, $3::int) AS b(n)
        CROSS JOIN generate_series(1, $4::int) AS a(n)
        WHERE e.id = ${idExpr('perf-eut-', `o.i || '-' || b.n || '-' || a.n`)}
          AND a.n % 4 = 0
        `,
        [ORG_START, ORG_END, BRANCHES_PER_ORG, APPT_PER_BRANCH]
      );
      ms += await q(
        client,
        `
        INSERT INTO rms.salon_payout_items (
          id, payout_id, end_user_transaction_id, item_type, amount, description, sort_order, created_at
        )
        SELECT
          ${idExpr('perf-poi-', `o.i || '-' || b.n || '-' || a.n`)},
          e.salon_payout_id,
          e.id,
          'BOOKING_GROSS',
          e.net_to_salon,
          'Settlement ' || e.transaction_ref,
          a.n,
          NOW()
        FROM generate_series($1::int, $2::int) AS o(i)
        CROSS JOIN generate_series(1, $3::int) AS b(n)
        CROSS JOIN generate_series(1, $4::int) AS a(n)
        JOIN rms.end_user_transactions e
          ON e.id = ${idExpr('perf-eut-', `o.i || '-' || b.n || '-' || a.n`)}
        WHERE e.salon_payout_id IS NOT NULL
        `,
        [ORG_START, ORG_END, BRANCHES_PER_ORG, APPT_PER_BRANCH]
      );
      return ms;
    });

    // -------- Phase 10: attendance --------
    await phase(client, `Attendance (${ATT_DAYS} days)`, async () => {
      let ms = 0;
      for (let start = ORG_START; start <= ORG_END; start += Math.min(ORG_CHUNK, 20)) {
        const end = Math.min(ORG_END, start + Math.min(ORG_CHUNK, 20) - 1);
        ms += await q(
          client,
          `
          INSERT INTO employee.attendance_records (
            id, organization_id, branch_id, employee_id, attendance_date,
            check_in_at, check_out_at, status, source, marked_by_ref, created_at, updated_at
          )
          SELECT
            ${idExpr('perf-att-', `o.i || '-' || b.n || '-' || e.n || '-' || d.n`)},
            ${idExpr('perf-org-', 'o.i')},
            ${idExpr('perf-br-', `o.i || '-' || b.n`)},
            ${idExpr('perf-emp-', `o.i || '-' || b.n || '-' || e.n`)},
            (CURRENT_DATE - ((d.n - 1) || ' days')::interval)::date,
            CASE WHEN st.status = 'PRESENT' THEN
              ((CURRENT_DATE - ((d.n - 1) || ' days')::interval)::date + TIME '09:55')::timestamptz
            END,
            CASE WHEN st.status = 'PRESENT' THEN
              ((CURRENT_DATE - ((d.n - 1) || ' days')::interval)::date + TIME '19:05')::timestamptz
            END,
            st.status,
            'SYSTEM',
            'bulk-seed',
            NOW(), NOW()
          FROM generate_series($1::int, $2::int) AS o(i)
          CROSS JOIN generate_series(1, $4::int) AS b(n)
          CROSS JOIN generate_series(1, $5::int) AS e(n)
          CROSS JOIN generate_series(1, $6::int) AS d(n)
          CROSS JOIN LATERAL (
            SELECT CASE
              WHEN EXTRACT(DOW FROM (CURRENT_DATE - ((d.n - 1) || ' days')::interval))::int =
                   CASE WHEN b.n % 3 = 0 THEN 0 ELSE 3 END
                THEN 'WEEKLY_OFF'
              WHEN (e.n + d.n) % 17 = 0 THEN 'ABSENT'
              WHEN (e.n + d.n) % 23 = 0 THEN 'ON_LEAVE'
              ELSE 'PRESENT'
            END AS status
          ) st
          `,
          [start, end, BRANCHES_PER_ORG, EMP_PER_BRANCH, ATT_DAYS]
        );
      }
      return ms;
    });

    // -------- Phase 11: invoices + payments --------
    await phase(client, `Invoices + payments (12 / org)`, async () => {
      let ms = await q(
        client,
        `
        INSERT INTO rms.invoices (
          id, organization_id, org_bill_structure_id, invoice_number, invoice_type, status,
          currency, subtotal_amount, discount_amount, taxable_amount, tax_amount,
          total_amount, amount_paid, amount_due,
          billing_period_start, billing_period_end, issue_date, due_date, paid_at,
          created_at, updated_at
        )
        SELECT
          ${idExpr('perf-inv-', `o.i || '-' || inv.n`)},
          ${idExpr('perf-org-', 'o.i')},
          ${idExpr('perf-bill-', 'o.i')},
          'PERF-INV-' || lpad(o.i::text, 4, '0') || '-' || lpad(inv.n::text, 2, '0'),
          CASE WHEN inv.n = 1 THEN 'PURCHASE' ELSE 'RENEWAL' END,
          'PAID',
          'INR',
          4999, 0, 4999, 900, 5899, 5899, 0,
          (CURRENT_DATE - ((inv.n * 30 + 29) || ' days')::interval)::date,
          (CURRENT_DATE - ((inv.n * 30) || ' days')::interval)::date,
          (CURRENT_DATE - ((inv.n * 30) || ' days')::interval)::date,
          (CURRENT_DATE - ((inv.n * 30 - 7) || ' days')::interval)::date,
          NOW() - ((inv.n * 30 - 1) || ' days')::interval,
          NOW(), NOW()
        FROM generate_series($2::int, $3::int) AS o(i)
        CROSS JOIN generate_series(1, 12) AS inv(n)
        `,
        [ORG_START, ORG_END]
      );
      ms += await q(
        client,
        `
        INSERT INTO rms.invoice_line_items (
          id, invoice_id, line_type, description, subscription_plan_id, billing_cycle_id,
          quantity, unit_amount, amount, discount_amount, taxable_amount, created_at
        )
        SELECT
          ${idExpr('perf-ili-', `o.i || '-' || inv.n`)},
          ${idExpr('perf-inv-', `o.i || '-' || inv.n`)},
          'PLAN',
          'Subscription renewal',
          (SELECT id FROM _perf_plans WHERE ord = (o.i - 1) % (SELECT COUNT(*) FROM _perf_plans)),
          (SELECT id FROM _perf_cycles WHERE ord = (o.i - 1) % (SELECT COUNT(*) FROM _perf_cycles)),
          1, 4999, 4999, 0, 4999, NOW()
        FROM generate_series($1::int, $2::int) AS o(i)
        CROSS JOIN generate_series(1, 12) AS inv(n)
        `,
        [ORG_START, ORG_END]
      );
      ms += await q(
        client,
        `
        INSERT INTO rms.payments (
          id, organization_id, payment_number, amount, currency, status,
          payment_method, gateway, gateway_payment_id, paid_at, created_at, updated_at
        )
        SELECT
          ${idExpr('perf-pay-', `o.i || '-' || inv.n`)},
          ${idExpr('perf-org-', 'o.i')},
          'PERF-PAY-' || lpad(o.i::text, 4, '0') || '-' || lpad(inv.n::text, 2, '0'),
          5899, 'INR', 'SUCCEEDED',
          'UPI', 'RAZORPAY',
          'rzp_perf_' || o.i || '_' || inv.n,
          NOW() - ((inv.n * 30 - 1) || ' days')::interval,
          NOW(), NOW()
        FROM generate_series($1::int, $2::int) AS o(i)
        CROSS JOIN generate_series(1, 12) AS inv(n)
        `,
        [ORG_START, ORG_END]
      );
      ms += await q(
        client,
        `
        INSERT INTO rms.invoice_payments (invoice_id, payment_id, amount_applied, created_at)
        SELECT
          ${idExpr('perf-inv-', `o.i || '-' || inv.n`)},
          ${idExpr('perf-pay-', `o.i || '-' || inv.n`)},
          5899,
          NOW()
        FROM generate_series($1::int, $2::int) AS o(i)
        CROSS JOIN generate_series(1, 12) AS inv(n)
        `,
        [ORG_START, ORG_END]
      );
      return ms;
    });

    // -------- Phase 12: reviews (from completed bookings) --------
    await phase(client, `Reviews`, async () => {
      const ms = await q(
        client,
        `
        INSERT INTO review.reviews (
          id, organization_id, branch_id, booking_ref, end_user_ref, specialist_ref,
          overall_rating, rating_service, rating_specialist, rating_cleanliness, rating_value,
          body, status, submitted_at, published_at, created_at, updated_at
        )
        SELECT
          ${idExpr('perf-rev-', `o.i || '-' || b.n || '-' || a.n`)},
          ap.organization_id,
          ap.branch_id,
          ap.booking_number,
          ap.end_user_ref,
          ap.specialist_id::text,
          3 + (a.n % 3),
          3 + (a.n % 3),
          3 + ((a.n + 1) % 3),
          4,
          3 + ((a.n + 2) % 3),
          'Good experience at the salon. Booking ' || ap.booking_number,
          'PUBLISHED',
          COALESCE(ap.completed_at, ap.starts_at),
          COALESCE(ap.completed_at, ap.starts_at),
          NOW(), NOW()
        FROM generate_series($1::int, $2::int) AS o(i)
        CROSS JOIN generate_series(1, $3::int) AS b(n)
        CROSS JOIN generate_series(1, $4::int) AS a(n)
        JOIN appointments.appointments ap
          ON ap.id = ${idExpr('perf-apt-', `o.i || '-' || b.n || '-' || a.n`)}
        WHERE ap.status = 'COMPLETED'
          AND a.n % 5 = 0
        `,
        [ORG_START, ORG_END, BRANCHES_PER_ORG, APPT_PER_BRANCH]
      );
      return ms;
    });

    // -------- Phase 13: support tickets --------
    await phase(client, `Support tickets + messages`, async () => {
      let ms = await q(
        client,
        `
        INSERT INTO tickets.support_tickets (
          id, ticket_number, source, organization_id, branch_id, end_user_ref, booking_ref,
          requester_name, requester_email, category_id, type_id, subtype_id,
          subject, description, priority, status, sla_policy_id,
          created_at, updated_at
        )
        SELECT
          ${idExpr('perf-tkt-', `o.i || '-' || t.n`)},
          'PERF-TKT-' || lpad(o.i::text, 4, '0') || '-' || lpad(t.n::text, 2, '0'),
          (ARRAY['SALON','END_USER','SALON','END_USER'])[1 + (t.n % 4)],
          ${idExpr('perf-org-', 'o.i')},
          ${idExpr('perf-br-', `o.i || '-1'`)},
          'EU-PERF-' || lpad(((o.i * 10 + t.n) % 50000)::text, 5, '0'),
          CASE WHEN t.n % 3 = 0 THEN
            'PERF-APT-' || lpad(o.i::text, 4, '0') || '-1-' || lpad(((t.n % $2) + 1)::text, 3, '0')
          END,
          'Requester ' || o.i || '-' || t.n,
          'ticket' || o.i || '-' || t.n || '@perf.glowtap.test',
          tt.category_id,
          tt.type_id,
          tt.subtype_id,
          'Perf issue ' || o.i || '-' || t.n,
          'Dummy performance ticket for load testing.',
          (ARRAY['LOW','MEDIUM','HIGH','CRITICAL'])[1 + (t.n % 4)],
          (ARRAY['CREATED','IN_PROGRESS','RESOLVED','CLOSED'])[1 + (t.n % 4)],
          $3::uuid,
          NOW() - ((t.n) || ' days')::interval,
          NOW()
        FROM generate_series($1::int, $2::int) AS o(i)
        CROSS JOIN generate_series(1, 20) AS t(n)
        JOIN _perf_ticket_types tt ON tt.ord = (t.n - 1) % (SELECT COUNT(*) FROM _perf_ticket_types)
        `,
        [ORG_START, ORG_END, APPT_PER_BRANCH, slaId]
      );
      ms += await q(
        client,
        `
        INSERT INTO tickets.support_ticket_messages (
          id, ticket_id, author_type, author_ref, body, is_first_response, created_at
        )
        SELECT
          ${idExpr('perf-tmsg-', `o.i || '-' || t.n || '-' || m.n`)},
          ${idExpr('perf-tkt-', `o.i || '-' || t.n`)},
          CASE WHEN m.n = 1 THEN 'END_USER' ELSE 'AGENT' END,
          CASE WHEN m.n = 1 THEN 'EU-PERF' ELSE 'agent-bulk' END,
          CASE WHEN m.n = 1 THEN 'Initial description of the issue.'
               ELSE 'We are looking into this. Thanks for reporting.' END,
          (m.n = 2),
          NOW() - ((t.n) || ' days')::interval + (m.n || ' hours')::interval
        FROM generate_series($1::int, $2::int) AS o(i)
        CROSS JOIN generate_series(1, 20) AS t(n)
        CROSS JOIN generate_series(1, 2) AS m(n)
        `,
        [ORG_START, ORG_END]
      );
      return ms;
    });

    // -------- Summary --------
    const tables = [
      ['organizations (perf)', `SELECT COUNT(*)::int n FROM organizations WHERE slug LIKE 'perf-%'`],
      ['branches (perf)', `SELECT COUNT(*)::int n FROM branches b JOIN organizations o ON o.id=b.organization_id WHERE o.slug LIKE 'perf-%'`],
      ['employees', `SELECT COUNT(*)::int n FROM employee.employees e JOIN organizations o ON o.id=e.organization_id WHERE o.slug LIKE 'perf-%'`],
      ['branch_services', `SELECT COUNT(*)::int n FROM services.branch_services s JOIN organizations o ON o.id=s.organization_id WHERE o.slug LIKE 'perf-%'`],
      ['specialists', `SELECT COUNT(*)::int n FROM services.branch_service_specialists bs JOIN services.branch_services s ON s.id=bs.branch_service_id JOIN organizations o ON o.id=s.organization_id WHERE o.slug LIKE 'perf-%'`],
      ['appointments', `SELECT COUNT(*)::int n FROM appointments.appointments WHERE booking_number LIKE 'PERF-APT-%'`],
      ['status_events', `SELECT COUNT(*)::int n FROM appointments.appointment_status_events e JOIN appointments.appointments a ON a.id=e.appointment_id WHERE a.booking_number LIKE 'PERF-APT-%'`],
      ['end_user_txns', `SELECT COUNT(*)::int n FROM rms.end_user_transactions WHERE transaction_ref LIKE 'PERF-EUT-%'`],
      ['ledger', `SELECT COUNT(*)::int n FROM rms.merchant_ledger_entries WHERE description LIKE 'Perf seed%'`],
      ['attendance', `SELECT COUNT(*)::int n FROM employee.attendance_records WHERE marked_by_ref='bulk-seed'`],
      ['reviews', `SELECT COUNT(*)::int n FROM review.reviews WHERE booking_ref LIKE 'PERF-APT-%'`],
      ['tickets', `SELECT COUNT(*)::int n FROM tickets.support_tickets WHERE ticket_number LIKE 'PERF-TKT-%'`],
      ['invoices', `SELECT COUNT(*)::int n FROM rms.invoices WHERE invoice_number LIKE 'PERF-INV-%'`],
      ['payouts', `SELECT COUNT(*)::int n FROM rms.salon_payouts WHERE payout_number LIKE 'PERF-PO-%'`],
    ];

    console.log('\n=== Perf seed counts ===');
    let grand = 0;
    for (const [label, sql] of tables) {
      const n = await count(client, sql);
      grand += n;
      console.log(`  ${label.padEnd(22)} ${n.toLocaleString('en-IN')}`);
    }
    console.log(`  ${'TOTAL (listed)'.padEnd(22)} ${grand.toLocaleString('en-IN')}`);
    console.log(`\nFinished in ${((Date.now() - t0) / 1000 / 60).toFixed(1)} min`);
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((err) => {
  console.error('\nBulk seed failed:', err.message);
  console.error(err);
  process.exit(1);
});

