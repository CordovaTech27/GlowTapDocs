const { pool } = require("../connection");
(async () => {
  const size = await pool.query(`SELECT pg_size_pretty(pg_database_size(current_database())) AS db_size`);
  const perf = await pool.query(`SELECT COUNT(*)::int n FROM organizations WHERE slug LIKE 'perf-%'`);
  console.log(size.rows[0], "perf orgs", perf.rows[0].n);
  console.log("Deleting perf orgs...");
  await pool.query(`DELETE FROM organizations WHERE slug LIKE 'perf-%'`);
  const size2 = await pool.query(`SELECT pg_size_pretty(pg_database_size(current_database())) AS db_size`);
  console.log("after delete", size2.rows[0]);
  await pool.end();
})().catch(async(e)=>{console.error(e); process.exit(1);});
