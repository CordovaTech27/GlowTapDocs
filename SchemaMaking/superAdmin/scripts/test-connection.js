const { pool } = require('../connection');

async function main() {
  const result = await pool.query(
    'SELECT current_database() AS database, current_user AS user, now() AS connected_at'
  );

  console.log('Neon connection OK');
  console.log(result.rows[0]);

  await pool.end();
}

main().catch((err) => {
  console.error('Connection failed:', err.message);
  process.exit(1);
});
