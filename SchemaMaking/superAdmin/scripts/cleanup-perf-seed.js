/** Fast DELETE-only cleanup of PERF seed (no UPDATEs — Neon is at 512 MB cap). */
const { pool } = require('../connection');

async function run(label, sql) {
  process.stdout.write(`${label}... `);
  const t0 = Date.now();
  try {
    const r = await pool.query(sql);
    console.log(`ok (${((Date.now() - t0) / 1000).toFixed(1)}s, ${r.rowCount})`);
  } catch (e) {
    console.log(`FAIL: ${e.message}`);
    throw e;
  }
}

async function main() {
  await pool.query('SET statement_timeout = 0');
  console.log(
    'Size:',
    (await pool.query(`SELECT pg_size_pretty(pg_database_size(current_database())) s`)).rows[0].s
  );

  // Children first — no UPDATEs
  await run('status events', `
    DELETE FROM appointments.appointment_status_events e
    USING appointments.appointments a
    WHERE e.appointment_id = a.id AND a.booking_number LIKE 'PERF-APT-%'`);

  await run('appointments', `
    DELETE FROM appointments.appointments WHERE booking_number LIKE 'PERF-APT-%'`);

  await run('payout items', `
    DELETE FROM rms.salon_payout_items poi
    USING rms.salon_payouts p
    WHERE poi.payout_id = p.id AND p.payout_number LIKE 'PERF-PO-%'`);

  await run('ledger', `
    DELETE FROM rms.merchant_ledger_entries WHERE description LIKE 'Perf seed%'`);

  await run('eut', `
    DELETE FROM rms.end_user_transactions WHERE transaction_ref LIKE 'PERF-EUT-%'`);

  await run('payouts', `
    DELETE FROM rms.salon_payouts WHERE payout_number LIKE 'PERF-PO-%'`);

  await run('invoice_payments', `
    DELETE FROM rms.invoice_payments ip
    USING rms.invoices i
    WHERE ip.invoice_id = i.id AND i.invoice_number LIKE 'PERF-INV-%'`);

  await run('invoice lines', `
    DELETE FROM rms.invoice_line_items ili
    USING rms.invoices i
    WHERE ili.invoice_id = i.id AND i.invoice_number LIKE 'PERF-INV-%'`);

  await run('payments', `
    DELETE FROM rms.payments WHERE payment_number LIKE 'PERF-PAY-%'`);

  await run('invoices', `
    DELETE FROM rms.invoices WHERE invoice_number LIKE 'PERF-INV-%'`);

  await run('review replies/reports/images/actions via reviews', `
    DELETE FROM review.review_moderation_actions a
    USING review.reviews r WHERE a.review_id = r.id AND r.booking_ref LIKE 'PERF-APT-%'`);
  await run('review reports', `
    DELETE FROM review.review_reports a
    USING review.reviews r WHERE a.review_id = r.id AND r.booking_ref LIKE 'PERF-APT-%'`);
  await run('review replies', `
    DELETE FROM review.review_replies a
    USING review.reviews r WHERE a.review_id = r.id AND r.booking_ref LIKE 'PERF-APT-%'`);
  await run('review images', `
    DELETE FROM review.review_images a
    USING review.reviews r WHERE a.review_id = r.id AND r.booking_ref LIKE 'PERF-APT-%'`);
  await run('reviews', `
    DELETE FROM review.reviews WHERE booking_ref LIKE 'PERF-APT-%'`);

  await run('ticket msgs', `
    DELETE FROM tickets.support_ticket_messages m
    USING tickets.support_tickets t
    WHERE m.ticket_id = t.id AND t.ticket_number LIKE 'PERF-TKT-%'`);
  await run('tickets', `
    DELETE FROM tickets.support_tickets WHERE ticket_number LIKE 'PERF-TKT-%'`);

  await run('attendance', `
    DELETE FROM employee.attendance_records WHERE marked_by_ref = 'bulk-seed'`);

  await run('leave requests', `
    DELETE FROM employee.leave_requests lr
    USING organizations o
    WHERE lr.organization_id = o.id AND o.slug LIKE 'perf-%'`);

  await run('leave balances', `
    DELETE FROM employee.leave_balances lb
    USING employee.employees e, organizations o
    WHERE lb.employee_id = e.id AND e.organization_id = o.id AND o.slug LIKE 'perf-%'`);

  await run('leave policies', `
    DELETE FROM employee.branch_leave_policies p
    USING organizations o
    WHERE p.organization_id = o.id AND o.slug LIKE 'perf-%'`);

  await run('leave types', `
    DELETE FROM employee.leave_types lt
    USING organizations o
    WHERE lt.organization_id = o.id AND o.slug LIKE 'perf-%'`);

  await run('specialists', `
    DELETE FROM services.branch_service_specialists bs
    USING services.branch_services s, organizations o
    WHERE bs.branch_service_id = s.id AND s.organization_id = o.id AND o.slug LIKE 'perf-%'`);

  await run('branch services', `
    DELETE FROM services.branch_services s
    USING organizations o
    WHERE s.organization_id = o.id AND o.slug LIKE 'perf-%'`);

  await run('employees', `
    DELETE FROM employee.employees e
    USING organizations o
    WHERE e.organization_id = o.id AND o.slug LIKE 'perf-%'`);

  await run('sub modules', `
    DELETE FROM admin_org.sub_admin_modules m
    USING admin_org.sub_admins s, organizations o
    WHERE m.sub_admin_id = s.id AND s.organization_id = o.id AND o.slug LIKE 'perf-%'`);

  await run('sub branches', `
    DELETE FROM admin_org.sub_admin_branches m
    USING admin_org.sub_admins s, organizations o
    WHERE m.sub_admin_id = s.id AND s.organization_id = o.id AND o.slug LIKE 'perf-%'`);

  await run('sub admins', `
    DELETE FROM admin_org.sub_admins s
    USING organizations o
    WHERE s.organization_id = o.id AND o.slug LIKE 'perf-%'`);

  await run('bill structure', `
    DELETE FROM rms.org_bill_structure b
    USING organizations o
    WHERE b.organization_id = o.id AND o.slug LIKE 'perf-%'`);

  await run('merchant balances', `
    DELETE FROM rms.org_merchant_balances b
    USING organizations o
    WHERE b.organization_id = o.id AND o.slug LIKE 'perf-%'`);

  await run('branches', `
    DELETE FROM branches b
    USING organizations o
    WHERE b.organization_id = o.id AND o.slug LIKE 'perf-%'`);

  await run('organizations', `
    DELETE FROM organizations WHERE slug LIKE 'perf-%'`);

  console.log(
    'Done. Size:',
    (await pool.query(`SELECT pg_size_pretty(pg_database_size(current_database())) s`)).rows[0].s,
    'perf orgs',
    (await pool.query(`SELECT COUNT(*)::int n FROM organizations WHERE slug LIKE 'perf-%'`)).rows[0]
      .n
  );
  await pool.end();
}

main().catch(async (e) => {
  console.error(e);
  await pool.end();
  process.exit(1);
});
