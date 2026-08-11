require('../connection');
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

(async () => {
  const rows = await pool.query(`
    SELECT
      s.relname AS table,
      s.n_live_tup AS rows,
      s.n_dead_tup AS dead_tuples,
      pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
      pg_size_pretty(pg_indexes_size(c.oid)) AS index_size,
      CASE WHEN pg_total_relation_size(c.oid) = 0 THEN 0
           ELSE ROUND(100.0 * pg_indexes_size(c.oid) / pg_total_relation_size(c.oid), 1)
      END AS index_pct,
      (SELECT count(*) FROM pg_index i WHERE i.indrelid = c.oid) AS index_count,
      pg_total_relation_size(c.oid) AS total_bytes
    FROM pg_stat_user_tables s
    JOIN pg_class c ON c.relname = s.relname
    JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = 'public'
    WHERE c.relkind = 'r'
    ORDER BY pg_total_relation_size(c.oid) DESC, s.relname
  `);

  const idx = await pool.query(
    `SELECT count(*)::int AS indexes FROM pg_indexes WHERE schemaname = 'public'`
  );
  const fk = await pool.query(`
    SELECT count(*)::int AS fks
    FROM information_schema.table_constraints
    WHERE table_schema = 'public' AND constraint_type = 'FOREIGN KEY'
  `);

  const data = {
    generated_at: new Date().toISOString(),
    summary: {
      tables: rows.rows.length,
      indexes: idx.rows[0].indexes,
      foreign_keys: fk.rows[0].fks,
      live_rows: rows.rows.reduce((a, r) => a + Number(r.rows), 0),
      dead_tuples: rows.rows.reduce((a, r) => a + Number(r.dead_tuples), 0),
    },
    tables: rows.rows.map((r) => ({
      table: r.table,
      rows: Number(r.rows),
      dead_tuples: Number(r.dead_tuples),
      total_size: r.total_size,
      index_size: r.index_size,
      index_pct: Number(r.index_pct),
      index_count: Number(r.index_count),
      total_bytes: Number(r.total_bytes),
    })),
  };

  const outDir = path.join(__dirname, '../reports');
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(path.join(outDir, 'db-stats.json'), JSON.stringify(data, null, 2));
  console.log('Wrote reports/db-stats.json');
  await pool.end();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
