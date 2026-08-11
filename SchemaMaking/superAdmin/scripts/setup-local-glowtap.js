/**
 * Create local Postgres database "GlowTap" and clone schema (and optional data)
 * from Neon so pgAdmin matches the live structure.
 *
 * Why not replaying migrations/*.sql from scratch?
 * Historical migrations are not a clean linear bootstrap (e.g. 001 and 008 both
 * CREATE subscription_plans). Dumping Neon is the accurate source of truth.
 *
 * Usage:
 *   node scripts/setup-local-glowtap.js
 *   node scripts/setup-local-glowtap.js --password=postgres --reset
 *   node scripts/setup-local-glowtap.js --password=postgres --reset --with-demo-data
 *
 * --with-demo-data copies non-PERF rows (excludes large PERF-* bulk seed tables' rows
 * by filtering organizations slug NOT LIKE 'perf-%' via a staged approach: full
 * schema + data dump excluding hot PERF fact tables, then keeps demo seeds).
 *
 * pgAdmin: Host localhost · Database GlowTap · User postgres
 */
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const m = a.match(/^--([^=]+)(?:=(.*))?$/);
    return m ? [m[1], m[2] === undefined ? true : m[2]] : [a, true];
  })
);

const PGHOST = args.host || 'localhost';
const PGPORT = args.port || '5432';
const PGUSER = args.user || 'postgres';
const PGPASSWORD = args.password || process.env.PGPASSWORD || 'postgres';
const DB_NAME = args.db || 'GlowTap';
const WITH_DEMO = Boolean(args['with-demo-data']);
const BIN = (() => {
  for (const v of ['18', '17', '16', '15']) {
    const base = `C:\\Program Files\\PostgreSQL\\${v}\\bin`;
    if (fs.existsSync(path.join(base, 'psql.exe'))) return base;
  }
  throw new Error('PostgreSQL bin folder not found under C:\\Program Files\\PostgreSQL');
})();
const PSQL = path.join(BIN, 'psql.exe');
const PG_DUMP = path.join(BIN, 'pg_dump.exe');

function loadNeonUrl() {
  if (process.env.NEON_DATABASE_URL) return process.env.NEON_DATABASE_URL;
  const envPath = path.join(__dirname, '..', '.env');
  const text = fs.readFileSync(envPath, 'utf8');
  const line = text.split(/\r?\n/).find((l) => l.startsWith('DATABASE_URL='));
  if (!line) throw new Error('DATABASE_URL not found in .env');
  return line.slice('DATABASE_URL='.length).trim();
}

function run(cmd, cmdArgs, envExtra = {}) {
  const r = spawnSync(cmd, cmdArgs, {
    env: { ...process.env, PGPASSWORD, ...envExtra },
    encoding: 'utf8',
    maxBuffer: 256 * 1024 * 1024,
  });
  if (r.status !== 0) {
    throw new Error((r.stderr || r.stdout || `${cmd} failed`).trim().slice(0, 2000));
  }
  return r.stdout || '';
}

function psql(db, sql) {
  return run(PSQL, [
    '-U',
    PGUSER,
    '-h',
    PGHOST,
    '-p',
    String(PGPORT),
    '-d',
    db,
    '-v',
    'ON_ERROR_STOP=1',
    '-c',
    sql,
  ]);
}

function psqlFile(db, file) {
  return run(PSQL, [
    '-U',
    PGUSER,
    '-h',
    PGHOST,
    '-p',
    String(PGPORT),
    '-d',
    db,
    '-v',
    'ON_ERROR_STOP=1',
    '-f',
    file,
  ]);
}

function main() {
  const neonUrl = loadNeonUrl();
  const tmpDir = path.join(__dirname, '..', '.tmp-local-setup');
  fs.mkdirSync(tmpDir, { recursive: true });
  const schemaFile = path.join(tmpDir, 'glowtap-schema.sql');
  const dataFile = path.join(tmpDir, 'glowtap-demo-data.sql');

  console.log(`Local: ${PGUSER}@${PGHOST}:${PGPORT}`);
  console.log(`Database: ${DB_NAME}`);
  console.log(`Source: Neon (schema${WITH_DEMO ? ' + demo data' : ' only'})`);

  psql('postgres', 'SELECT 1');

  const exists = psql(
    'postgres',
    `SELECT 1 FROM pg_database WHERE datname = '${DB_NAME.replace(/'/g, "''")}'`
  );
  if (exists.includes('1')) {
    if (!args.reset) {
      console.log(`Database "${DB_NAME}" already exists. Re-run with --reset to recreate.`);
      process.exit(0);
    }
    console.log('Dropping existing database...');
    psql(
      'postgres',
      `SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME.replace(/'/g, "''")}' AND pid <> pg_backend_pid()`
    );
    psql('postgres', `DROP DATABASE "${DB_NAME}"`);
  }

  console.log(`Creating "${DB_NAME}"...`);
  psql('postgres', `CREATE DATABASE "${DB_NAME}"`);

  console.log('Creating role authenticated (Neon Data API compatibility)...');
  psql(
    DB_NAME,
    `DO $$ BEGIN
       CREATE ROLE authenticated NOLOGIN;
     EXCEPTION WHEN duplicate_object THEN NULL;
     END $$;`
  );

  console.log('Dumping schema from Neon (this may take a minute)...');
  const dumpUrl = neonUrl.replace('-pooler', '');
  run(
    PG_DUMP,
    [
      dumpUrl,
      '--schema-only',
      '--no-owner',
      '--no-privileges',
      '--no-comments',
      '-f',
      schemaFile,
    ]
  );
  console.log(`  Wrote ${schemaFile}`);

  let schemaSql = fs.readFileSync(schemaFile, 'utf8');
  // pg_dump 18 restrict token — not needed for local restore
  schemaSql = schemaSql.replace(/^\\restrict .*$/gm, '');
  schemaSql = schemaSql.replace(/^\\unrestrict .*$/gm, '');
  // Neon-only extension (not available on stock local Postgres)
  schemaSql = schemaSql.replace(
    /CREATE EXTENSION IF NOT EXISTS pg_session_jwt[^;]*;/gi,
    '-- skipped: pg_session_jwt (Neon-only)\n'
  );
  schemaSql = schemaSql.replace(/^ALTER .* OWNER TO .*;$/gm, '');
  schemaSql = schemaSql.replace(/^GRANT .* TO neon_superuser;$/gim, '');
  schemaSql = schemaSql.replace(/^GRANT .* TO cloud_admin;$/gim, '');
  schemaSql = schemaSql.replace(/^REVOKE .* FROM .*;$/gim, '');
  // Idempotent schemas if a partial restore left leftovers
  schemaSql = schemaSql.replace(/CREATE SCHEMA (\w+);/g, 'CREATE SCHEMA IF NOT EXISTS $1;');
  fs.writeFileSync(schemaFile, schemaSql);

  // Fresh DB already — ensure extensions available locally
  psql(DB_NAME, 'CREATE EXTENSION IF NOT EXISTS pgcrypto');
  psql(DB_NAME, 'CREATE EXTENSION IF NOT EXISTS citext');

  console.log('Restoring schema into local GlowTap...');
  psqlFile(DB_NAME, schemaFile);

  if (WITH_DEMO) {
    console.log('Dumping demo data from Neon (excluding large PERF fact tables)...');
    const exclude = [
      '--exclude-table-data=appointments.appointments',
      '--exclude-table-data=appointments.appointment_status_events',
      '--exclude-table-data=appointments.appointment_holds',
      '--exclude-table-data=appointments.appointment_reschedules',
      '--exclude-table-data=employee.attendance_records',
      '--exclude-table-data=employee.attendance_audit_actions',
      '--exclude-table-data=rms.end_user_transactions',
      '--exclude-table-data=rms.merchant_ledger_entries',
      '--exclude-table-data=rms.salon_payout_items',
      '--exclude-table-data=services.branch_service_specialists',
    ];
    run(PG_DUMP, [
      dumpUrl,
      '--data-only',
      '--no-owner',
      '--disable-triggers',
      ...exclude,
      '-f',
      dataFile,
    ]);
    console.log('Restoring demo data (may include PERF dimension rows; fact tables skipped)...');
    // Soft restore: continue on errors for FK orphans from excluded facts
    run(PSQL, [
      '-U',
      PGUSER,
      '-h',
      PGHOST,
      '-p',
      String(PGPORT),
      '-d',
      DB_NAME,
      '-f',
      dataFile,
    ]);
    console.log('Pruning PERF-* bulk orgs (keeps demo)...');
    psql(DB_NAME, `DELETE FROM organizations WHERE slug LIKE 'perf-%'`);
  }

  const schemas = psql(
    DB_NAME,
    `SELECT nspname FROM pg_namespace WHERE nspname IN (
      'public','rms','subscription','admin_org','cms','review','tickets','services','employee','appointments'
     ) ORDER BY 1`
  );
  const tables = psql(
    DB_NAME,
    `SELECT COUNT(*) FROM information_schema.tables
     WHERE table_type='BASE TABLE' AND table_schema IN (
      'public','rms','subscription','admin_org','cms','review','tickets','services','employee','appointments'
     )`
  );

  const localUrl = `postgresql://${encodeURIComponent(PGUSER)}:${encodeURIComponent(PGPASSWORD)}@${PGHOST}:${PGPORT}/${encodeURIComponent(DB_NAME)}`;
  fs.writeFileSync(
    path.join(__dirname, '..', '.env.local'),
    `# Local GlowTap for pgAdmin / scripts (Neon remains in .env)
DATABASE_URL=${localUrl}
`
  );

  console.log('\n=== Local GlowTap ready ===');
  console.log(schemas);
  console.log('Base tables count:', tables.trim().split(/\s+/).pop());
  console.log('\npgAdmin:');
  console.log(`  Host: ${PGHOST}`);
  console.log(`  Port: ${PGPORT}`);
  console.log(`  Database: ${DB_NAME}`);
  console.log(`  Username: ${PGUSER}`);
  console.log(`  Password: (your local postgres password)`);
  console.log(`\nConnection string saved to SchemaMaking/superAdmin/.env.local`);
}

try {
  main();
} catch (e) {
  console.error('\nSetup failed:', e.message);
  process.exit(1);
}
