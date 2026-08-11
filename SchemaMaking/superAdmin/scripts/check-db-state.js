const { pool } = require('../connection');

async function main() {
  const tables = await pool.query(`
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_schema IN ('public', 'rms', 'admin_org', 'cms', 'review', 'tickets', 'services', 'subscription')
    ORDER BY table_schema, table_name
  `);

  console.log('Tables by schema:');
  console.table(tables.rows);

  const planTable = tables.rows.find(
    (r) => r.table_schema === 'subscription' && r.table_name === 'subscription_plans'
  );
  if (planTable) {
    const plans = await pool.query(
      'SELECT id, name, max_branches FROM subscription.subscription_plans ORDER BY max_branches'
    );
    console.log('\nsubscription.subscription_plans rows:');
    console.table(plans.rows);
  }

  const orgCols = await pool.query(`
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'organizations'
    ORDER BY ordinal_position
  `);
  console.log('\norganizations columns:', orgCols.rows.map((r) => r.column_name).join(', '));

  await pool.end();
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
