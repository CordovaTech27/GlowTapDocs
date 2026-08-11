/**
 * Neon only: wipe all tenant/business data; keep super admin + platform reference data.
 *
 *   node scripts/wipe-neon-keep-ref.js --confirm
 */
const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

if (!process.argv.includes('--confirm')) {
  console.error('Refusing to run without --confirm');
  process.exit(1);
}

const url = fs
  .readFileSync(path.join(__dirname, '..', '.env'), 'utf8')
  .split(/\r?\n/)
  .find((l) => l.startsWith('DATABASE_URL='))
  .slice('DATABASE_URL='.length)
  .trim();

const host = new URL(url).hostname;
if (!host.includes('neon.tech')) {
  console.error('Refusing: DATABASE_URL host is not Neon:', host);
  process.exit(1);
}

/** Tables to KEEP (super admin + platform reference / config). */
const KEEP = new Set([
  'public.super_admin_users',
  'public.states',
  'public.reason_codes',
  'public.platform_commission_config',
  'rms.billing_cycles',
  'rms.state_tax_configs',
  'rms.billing_discount_configs',
  'subscription.subscription_plans',
  'services.service_categories',
  'services.service_subcategories',
  'employee.leave_types',
  'review.review_abuse_rules',
  'review.review_moderation_actions',
  'review.review_moderation_settings',
  'tickets.support_sla_policies',
  'tickets.support_ticket_categories',
  'tickets.support_ticket_types',
  'tickets.support_ticket_subtypes',
]);

const SCHEMAS = [
  'public',
  'rms',
  'subscription',
  'admin_org',
  'cms',
  'review',
  'tickets',
  'services',
  'employee',
  'appointments',
];

const pool = new Pool({ connectionString: url });

async function main() {
  console.log('Neon wipe → keep super admin + reference config');
  console.log('host:', host);

  const client = await pool.connect();
  try {
    await client.query('SET statement_timeout = 0');

    const beforeSa = await client.query(
      `SELECT id, email, full_name FROM super_admin_users ORDER BY created_at`
    );
    console.log('super_admin_users to preserve:', beforeSa.rows);

    const tables = await client.query(
      `
      SELECT n.nspname AS schema, c.relname AS table
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE c.relkind = 'r'
        AND n.nspname = ANY($1::text[])
      ORDER BY 1, 2
    `,
      [SCHEMAS]
    );

    const wipe = tables.rows
      .map((r) => `${r.schema}.${r.table}`)
      .filter((fq) => !KEEP.has(fq));

    const kept = tables.rows
      .map((r) => `${r.schema}.${r.table}`)
      .filter((fq) => KEEP.has(fq));

    console.log(`keeping ${kept.length} tables:`);
    for (const t of kept) console.log('  KEEP', t);
    console.log(`truncating ${wipe.length} tables...`);

    if (wipe.length === 0) {
      console.log('Nothing to wipe.');
      return;
    }

    const list = wipe.map((fq) => fq.replace(/^([^.]+)\.(.+)$/, '"$1"."$2"')).join(',\n  ');
    await client.query(`TRUNCATE TABLE\n  ${list}\nRESTART IDENTITY CASCADE`);

    const after = await client.query(`
      SELECT
        (SELECT COUNT(*)::int FROM super_admin_users) AS super_admins,
        (SELECT COUNT(*)::int FROM organizations) AS organizations,
        (SELECT COUNT(*)::int FROM branches) AS branches,
        (SELECT COUNT(*)::int FROM states) AS states,
        (SELECT COUNT(*)::int FROM subscription.subscription_plans) AS plans,
        (SELECT COUNT(*)::int FROM services.service_categories) AS service_categories,
        (SELECT COUNT(*)::int FROM employee.leave_types) AS leave_types,
        (SELECT COUNT(*)::int FROM rms.billing_cycles) AS billing_cycles,
        (SELECT COUNT(*)::int FROM appointments.appointments) AS appointments,
        pg_size_pretty(pg_database_size(current_database())) AS db_size
    `);

    console.log('Done. Counts:', after.rows[0]);
    console.log(
      'super_admin_users:',
      (await client.query(`SELECT id, email, full_name FROM super_admin_users`)).rows
    );
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((e) => {
  console.error('Wipe failed:', e.message);
  process.exit(1);
});
