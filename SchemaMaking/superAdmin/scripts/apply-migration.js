const fs = require('fs');
const path = require('path');
const { pool } = require('../connection');

const migrationsDir = path.join(__dirname, '..', 'migrations');
const targetFile = process.argv[2];

async function applyFile(filePath) {
  const sql = fs.readFileSync(filePath, 'utf8');
  const relative = path.relative(migrationsDir, filePath);

  console.log(`Applying: ${relative}`);
  await pool.query(sql);
  console.log(`  Done.`);
}

async function main() {
  const files = fs
    .readdirSync(migrationsDir)
    .filter((name) => name.endsWith('.sql'))
    .sort();

  const selected = targetFile
    ? files.filter((name) => name === targetFile || name.includes(targetFile))
    : files;

  if (selected.length === 0) {
    console.error('No migration files matched.');
    process.exit(1);
  }

  for (const file of selected) {
    await applyFile(path.join(migrationsDir, file));
  }

  const summary = await pool.query(`
    SELECT
      (SELECT COUNT(*)::int FROM super_admin_users) AS super_admins,
      (SELECT COUNT(*)::int FROM organizations) AS organizations,
      (SELECT COUNT(*)::int FROM branches) AS branches
  `);

  console.log('Database summary:', summary.rows[0]);
  await pool.end();
}

main().catch((err) => {
  console.error('Migration failed:', err.message);
  process.exit(1);
});
