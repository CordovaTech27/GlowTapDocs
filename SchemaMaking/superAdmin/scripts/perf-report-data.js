const { pool } = require('../connection');

async function main() {
  const summary = await pool.query(`
    SELECT
      (SELECT count(*)::int FROM pg_tables WHERE schemaname = 'public') AS tables,
      (SELECT count(*)::int FROM pg_indexes WHERE schemaname = 'public') AS indexes,
      (SELECT count(*)::int FROM pg_constraint WHERE contype = 'p' AND connamespace = 'public'::regnamespace) AS primary_keys,
      (SELECT count(*)::int FROM pg_constraint WHERE contype = 'f' AND connamespace = 'public'::regnamespace) AS foreign_keys,
      (SELECT count(*)::int FROM pg_constraint WHERE contype = 'u' AND connamespace = 'public'::regnamespace) AS unique_constraints,
      pg_size_pretty(sum(pg_total_relation_size(c.oid))) AS total_db_size
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'r'
  `);

  const tables = await pool.query(`
    SELECT
      c.relname AS table_name,
      COALESCE(s.n_live_tup, 0)::bigint AS live_rows,
      COALESCE(s.n_dead_tup, 0)::bigint AS dead_rows,
      pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
      pg_size_pretty(pg_relation_size(c.oid)) AS heap_size,
      pg_size_pretty(pg_indexes_size(c.oid)) AS index_size,
      round(100.0 * pg_indexes_size(c.oid) / NULLIF(pg_total_relation_size(c.oid), 0), 1) AS index_pct,
      (SELECT count(*) FROM pg_index ix WHERE ix.indrelid = c.oid)::int AS index_count,
      EXISTS (SELECT 1 FROM pg_index ix WHERE ix.indrelid = c.oid AND ix.indisprimary) AS has_pk,
      s.last_analyze,
      s.last_autoanalyze
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    LEFT JOIN pg_stat_user_tables s ON s.relid = c.oid
    WHERE n.nspname = 'public' AND c.relkind = 'r'
    ORDER BY pg_total_relation_size(c.oid) DESC, c.relname
  `);

  const indexes = await pool.query(`
    SELECT
      t.relname AS table_name,
      i.relname AS index_name,
      ix.indisprimary AS is_pk,
      ix.indisunique AS is_unique,
      pg_size_pretty(pg_relation_size(i.oid)) AS index_size,
      COALESCE(si.idx_scan, 0)::bigint AS scans,
      pg_get_indexdef(i.oid) AS definition
    FROM pg_index ix
    JOIN pg_class t ON t.oid = ix.indrelid
    JOIN pg_class i ON i.oid = ix.indexrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    LEFT JOIN pg_stat_user_indexes si ON si.indexrelid = i.oid
    WHERE n.nspname = 'public'
    ORDER BY t.relname, ix.indisprimary DESC, i.relname
  `);

  const fkCoverage = await pool.query(`
    WITH fk_cols AS (
      SELECT
        c.conrelid AS table_oid,
        replace(c.conrelid::regclass::text, 'public.', '') AS table_name,
        a.attname AS column_name
      FROM pg_constraint c
      JOIN LATERAL unnest(c.conkey) WITH ORDINALITY AS u(attnum, ord) ON true
      JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = u.attnum
      WHERE c.contype = 'f'
        AND c.connamespace = 'public'::regnamespace
        AND u.ord = 1
    )
    SELECT
      f.table_name,
      f.column_name,
      EXISTS (
        SELECT 1
        FROM pg_index ix
        WHERE ix.indrelid = f.table_oid
          AND ix.indkey[0] = (
            SELECT a.attnum FROM pg_attribute a
            WHERE a.attrelid = f.table_oid AND a.attname = f.column_name AND NOT a.attisdropped
          )
      ) AS has_leading_index
    FROM fk_cols f
    ORDER BY has_leading_index, f.table_name, f.column_name
  `);

  const missingPk = await pool.query(`
    SELECT c.relname AS table_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'r'
      AND NOT EXISTS (
        SELECT 1 FROM pg_index ix WHERE ix.indrelid = c.oid AND ix.indisprimary
      )
  `);

  const report = {
    generatedAt: new Date().toISOString(),
    summary: summary.rows[0],
    missingPrimaryKeys: missingPk.rows,
    tables: tables.rows,
    indexes: indexes.rows.map((r) => ({
      ...r,
      definition: r.definition.replace(/^CREATE (UNIQUE )?INDEX .* ON /, '').replace(/USING btree /, ''),
    })),
    fkCoverage: fkCoverage.rows,
    fkCovered: fkCoverage.rows.filter((r) => r.has_leading_index).length,
    fkUncovered: fkCoverage.rows.filter((r) => !r.has_leading_index).length,
  };

  const fs = require('fs');
  const path = require('path');
  const outPath = path.join(__dirname, 'perf-report.json');
  const billing = [
    'invoices',
    'invoice_line_items',
    'invoice_tax_lines',
    'payments',
    'invoice_payments',
    'credit_notes',
    'credit_note_line_items',
    'refunds',
    'org_bill_structure',
    'org_subscription_changes',
    'org_status_actions',
    'reason_codes',
  ];
  const lite = {
    generatedAt: report.generatedAt,
    summary: report.summary,
    missingPkCount: report.missingPrimaryKeys.length,
    fkCovered: report.fkCovered,
    fkUncovered: report.fkUncovered,
    uncovered: report.fkCoverage.filter((x) => !x.has_leading_index),
    tables: report.tables.map((t) => ({
      name: t.table_name,
      rows: Number(t.live_rows),
      dead: Number(t.dead_rows),
      total: t.total_size,
      idx: t.index_size,
      idxPct: Number(t.index_pct),
      indexes: Number(t.index_count),
      hasPk: t.has_pk,
      analyzed: Boolean(t.last_analyze),
    })),
    billingIndexes: report.indexes
      .filter((i) => billing.includes(i.table_name))
      .map((i) => ({
        table: i.table_name,
        name: i.index_name,
        pk: i.is_pk,
        unique: i.is_unique,
        size: i.index_size,
        scans: Number(i.scans),
        def: i.definition,
      })),
  };
  fs.writeFileSync(outPath, JSON.stringify(report, null, 2));
  fs.writeFileSync(path.join(__dirname, 'perf-report-lite.json'), JSON.stringify(lite));
  console.log('Wrote', outPath);
  console.log(
    'Summary',
    report.summary,
    'fk covered/uncovered',
    report.fkCovered,
    report.fkUncovered
  );
  await pool.end();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
