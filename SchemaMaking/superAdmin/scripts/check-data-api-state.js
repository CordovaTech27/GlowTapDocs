const { pool } = require('../connection');

async function main() {
  const schemas = await pool.query(`
    SELECT schema_name
    FROM information_schema.schemata
    WHERE schema_name NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
    ORDER BY 1
  `);
  console.log('Schemas:', schemas.rows.map((r) => r.schema_name).join(', '));

  const tables = await pool.query(`
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_schema IN ('public', 'admin', 'neon_auth')
    ORDER BY 1, 2
  `);
  console.log('\nTables (public/admin/neon_auth):');
  console.table(tables.rows);

  const roles = await pool.query(`
    SELECT rolname
    FROM pg_roles
    WHERE rolname IN ('authenticated', 'anonymous', 'authenticator')
    ORDER BY 1
  `);
  console.log('\nAPI roles:', roles.rows.map((r) => r.rolname).join(', ') || '(none)');

  const rls = await pool.query(`
    SELECT c.relname AS table_name, c.relrowsecurity AS rls_enabled
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'r'
    ORDER BY 1
  `);
  console.log('\nRLS on public tables:');
  console.table(rls.rows);

  const grants = await pool.query(`
    SELECT table_name, grantee, privilege_type
    FROM information_schema.role_table_grants
    WHERE table_schema = 'public'
      AND grantee IN ('authenticated', 'anonymous')
    ORDER BY table_name, grantee, privilege_type
  `);
  console.log('\nGrants for authenticated/anonymous:');
  console.table(grants.rows);

  await pool.end();
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
