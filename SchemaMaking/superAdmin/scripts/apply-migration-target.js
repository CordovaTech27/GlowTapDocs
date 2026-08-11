const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

const target = process.argv[2] || 'neon'; // neon | local
const migration = process.argv[3] || '076b_performance_indexes_neon_lite.sql';

const envFile = target === 'local' ? '.env.local' : '.env';
const envPath = path.join(__dirname, '..', envFile);
const env = fs.readFileSync(envPath, 'utf8');
const line = env.split(/\r?\n/).find((l) => l.startsWith('DATABASE_URL='));
if (!line) throw new Error('No DATABASE_URL in ' + envFile);
const url = line.slice('DATABASE_URL='.length).trim();
const u = new URL(url);
console.log(`Applying ${migration} → ${target} (${u.hostname}/${u.pathname.slice(1)})`);

const sql = fs.readFileSync(path.join(__dirname, '..', 'migrations', migration), 'utf8');
const pool = new Pool({ connectionString: url });

(async () => {
  await pool.query(sql);
  const s = await pool.query(`
    SELECT pg_size_pretty(pg_database_size(current_database())) AS sz,
           (SELECT COUNT(*)::int FROM organizations) AS orgs,
           EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_appointments_org_starts') AS has_org_starts,
           EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_appointments_status_incl') AS has_status_incl,
           EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_appointments_org_status_starts_incl') AS has_full_covering
  `);
  console.log('Done:', s.rows[0]);
  await pool.end();
})().catch(async (e) => {
  console.error('Failed:', e.message);
  await pool.end();
  process.exit(1);
});
