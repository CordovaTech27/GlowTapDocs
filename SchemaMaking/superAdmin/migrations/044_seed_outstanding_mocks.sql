-- Mock open outstanding balances (cash commissions not yet fully settled)

INSERT INTO org_merchant_balances (organization_id, outstanding_amount, pending_payout_amount)
VALUES
  ('b1000000-0000-4000-8000-000000000002', 0, 0), -- Glamour Zone
  ('b1000000-0000-4000-8000-000000000004', 0, 0)  -- Naturals
ON CONFLICT (organization_id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Glamour Zone (6.5%): two cash bookings → outstanding ₹325 (still open)
-- ---------------------------------------------------------------------------
INSERT INTO end_user_transactions (
  id, transaction_ref, organization_id, branch_id, booking_ref, end_user_ref,
  payment_channel, collection_model,
  gross_amount, commission_pct, commission_amount, gateway_fee_amount, net_to_salon,
  payment_method, status, service_details, outstanding_recovered, occurred_at
) VALUES
(
  'f5000000-0000-4000-8000-000000000301',
  'GT-B2C-2026-00010',
  'b1000000-0000-4000-8000-000000000002',
  'c1000000-0000-4000-8000-000000000004',
  'BK-GLZ-2010', 'EU-9101',
  'CASH', 'MERCHANT',
  2000.00, 6.50, 130.00, 0, 0,
  'CASH', 'SUCCESS',
  '{"service":"Bridal makeup trial"}'::jsonb,
  0,
  TIMESTAMPTZ '2026-07-18 12:10:00+05:30'
),
(
  'f5000000-0000-4000-8000-000000000302',
  'GT-B2C-2026-00011',
  'b1000000-0000-4000-8000-000000000002',
  'c1000000-0000-4000-8000-000000000005',
  'BK-GLZ-2011', 'EU-9102',
  'CASH', 'MERCHANT',
  3000.00, 6.50, 195.00, 0, 0,
  'UPI', 'SUCCESS',
  '{"service":"Hair colour + cut","notes":"UPI at salon"}'::jsonb,
  0,
  TIMESTAMPTZ '2026-07-20 15:40:00+05:30'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO merchant_ledger_entries (
  id, organization_id, balance_bucket, direction, entry_type, amount, balance_after,
  end_user_transaction_id, description, occurred_at
) VALUES
(
  'f5000000-0000-4000-8000-000000000401',
  'b1000000-0000-4000-8000-000000000002',
  'OUTSTANDING', 'INCREASE', 'COMMISSION_ACCRUAL', 130.00, 130.00,
  'f5000000-0000-4000-8000-000000000301',
  'Cash booking commission GT-B2C-2026-00010',
  TIMESTAMPTZ '2026-07-18 12:10:00+05:30'
),
(
  'f5000000-0000-4000-8000-000000000402',
  'b1000000-0000-4000-8000-000000000002',
  'OUTSTANDING', 'INCREASE', 'COMMISSION_ACCRUAL', 195.00, 325.00,
  'f5000000-0000-4000-8000-000000000302',
  'UPI-at-salon commission GT-B2C-2026-00011',
  TIMESTAMPTZ '2026-07-20 15:40:00+05:30'
)
ON CONFLICT (id) DO NOTHING;

UPDATE org_merchant_balances
SET outstanding_amount = 325.00, pending_payout_amount = 0, updated_at = NOW()
WHERE organization_id = 'b1000000-0000-4000-8000-000000000002';

-- ---------------------------------------------------------------------------
-- Naturals (5%): cash outstanding ₹2,500; online recovers ₹1,860 only
-- → leftover outstanding ₹640; salon payout ₹0
-- ---------------------------------------------------------------------------
INSERT INTO end_user_transactions (
  id, transaction_ref, organization_id, branch_id, booking_ref, end_user_ref,
  payment_channel, collection_model,
  gross_amount, commission_pct, commission_amount, gateway_fee_amount, net_to_salon,
  payment_method, status, service_details, outstanding_recovered, occurred_at
) VALUES
(
  'f5000000-0000-4000-8000-000000000303',
  'GT-B2C-2026-00012',
  'b1000000-0000-4000-8000-000000000004',
  'c1000000-0000-4000-8000-000000000007',
  'BK-NAT-3012', 'EU-9201',
  'CASH', 'MERCHANT',
  20000.00, 5.00, 1000.00, 0, 0,
  'CASH', 'SUCCESS',
  '{"service":"Wedding package (advance)"}'::jsonb,
  0,
  TIMESTAMPTZ '2026-07-10 10:00:00+05:30'
),
(
  'f5000000-0000-4000-8000-000000000304',
  'GT-B2C-2026-00013',
  'b1000000-0000-4000-8000-000000000004',
  'c1000000-0000-4000-8000-000000000008',
  'BK-NAT-3013', 'EU-9202',
  'CASH', 'MERCHANT',
  30000.00, 5.00, 1500.00, 0, 0,
  'CASH', 'SUCCESS',
  '{"service":"Spa day package"}'::jsonb,
  0,
  TIMESTAMPTZ '2026-07-14 18:20:00+05:30'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO merchant_ledger_entries (
  id, organization_id, balance_bucket, direction, entry_type, amount, balance_after,
  end_user_transaction_id, description, occurred_at
) VALUES
(
  'f5000000-0000-4000-8000-000000000403',
  'b1000000-0000-4000-8000-000000000004',
  'OUTSTANDING', 'INCREASE', 'COMMISSION_ACCRUAL', 1000.00, 1000.00,
  'f5000000-0000-4000-8000-000000000303',
  'Cash booking commission GT-B2C-2026-00012',
  TIMESTAMPTZ '2026-07-10 10:00:00+05:30'
),
(
  'f5000000-0000-4000-8000-000000000404',
  'b1000000-0000-4000-8000-000000000004',
  'OUTSTANDING', 'INCREASE', 'COMMISSION_ACCRUAL', 1500.00, 2500.00,
  'f5000000-0000-4000-8000-000000000304',
  'Cash booking commission GT-B2C-2026-00013',
  TIMESTAMPTZ '2026-07-14 18:20:00+05:30'
)
ON CONFLICT (id) DO NOTHING;

-- Online ₹2,000: available = 2000 − 100 − 40 = 1860; recover 1860; payout 0; leftover 640
INSERT INTO salon_payouts (
  id, payout_number, organization_id, status, currency,
  gross_collected, commission_deducted, gateway_fees_deducted, outstanding_recovered,
  net_payout_amount, gateway, gateway_payout_id, gateway_ref,
  period_start, period_end, paid_at, notes, created_by
) VALUES (
  'f5000000-0000-4000-8000-000000000501',
  'GT-PO-2026-00010',
  'b1000000-0000-4000-8000-000000000004',
  'PAID', 'INR',
  2000.00, 100.00, 40.00, 1860.00,
  0.00, 'RAZORPAY', 'pout_naturals_20260721', 'RAZORPAYX-NAT-0721',
  TIMESTAMPTZ '2026-07-21 14:00:00+05:30',
  TIMESTAMPTZ '2026-07-21 14:10:00+05:30',
  TIMESTAMPTZ '2026-07-21 23:15:00+05:30',
  'Outstanding larger than available — salon payout ₹0; leftover outstanding remains.',
  'a1000000-0000-4000-8000-000000000001'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO end_user_transactions (
  id, transaction_ref, organization_id, branch_id, booking_ref, end_user_ref,
  payment_channel, collection_model,
  gross_amount, commission_pct, commission_amount, gateway_fee_amount, net_to_salon,
  payment_method, status, gateway, gateway_order_id, gateway_payment_id, gateway_ref,
  service_details, outstanding_recovered, salon_payout_id, occurred_at
) VALUES (
  'f5000000-0000-4000-8000-000000000305',
  'GT-B2C-2026-00014',
  'b1000000-0000-4000-8000-000000000004',
  'c1000000-0000-4000-8000-000000000009',
  'BK-NAT-3014', 'EU-9203',
  'ONLINE', 'MARKETPLACE',
  2000.00, 5.00, 100.00, 40.00, 0.00,
  'CARD', 'SUCCESS', 'RAZORPAY',
  'order_naturals_online_0721', 'pay_naturals_online_0721', 'card_naturals_0721',
  '{"service":"Hair spa"}'::jsonb,
  1860.00,
  'f5000000-0000-4000-8000-000000000501',
  TIMESTAMPTZ '2026-07-21 14:05:00+05:30'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO salon_payout_items (
  id, payout_id, end_user_transaction_id, item_type, amount, description, sort_order
) VALUES
(
  'f5000000-0000-4000-8000-000000000511',
  'f5000000-0000-4000-8000-000000000501',
  'f5000000-0000-4000-8000-000000000305',
  'BOOKING_GROSS', 2000.00, 'Customer paid online', 10
),
(
  'f5000000-0000-4000-8000-000000000512',
  'f5000000-0000-4000-8000-000000000501',
  'f5000000-0000-4000-8000-000000000305',
  'COMMISSION', -100.00, 'GlowTap commission 5%', 20
),
(
  'f5000000-0000-4000-8000-000000000513',
  'f5000000-0000-4000-8000-000000000501',
  'f5000000-0000-4000-8000-000000000305',
  'GATEWAY_FEE', -40.00, 'Payment gateway fee', 30
),
(
  'f5000000-0000-4000-8000-000000000514',
  'f5000000-0000-4000-8000-000000000501',
  'f5000000-0000-4000-8000-000000000305',
  'OUTSTANDING_RECOVERY', -1860.00, 'Recover cash commission (capped at available)', 40
),
(
  'f5000000-0000-4000-8000-000000000515',
  'f5000000-0000-4000-8000-000000000501',
  'f5000000-0000-4000-8000-000000000305',
  'NET_TRANSFER', 0.00, 'Nothing left to pay salon', 50
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO merchant_ledger_entries (
  id, organization_id, balance_bucket, direction, entry_type, amount, balance_after,
  end_user_transaction_id, salon_payout_id, description, occurred_at
) VALUES (
  'f5000000-0000-4000-8000-000000000405',
  'b1000000-0000-4000-8000-000000000004',
  'OUTSTANDING', 'DECREASE', 'OUTSTANDING_RECOVERY', 1860.00, 640.00,
  'f5000000-0000-4000-8000-000000000305',
  'f5000000-0000-4000-8000-000000000501',
  'Recovered ₹1,860 from online payout GT-PO-2026-00010; leftover outstanding ₹640',
  TIMESTAMPTZ '2026-07-21 23:15:00+05:30'
)
ON CONFLICT (id) DO NOTHING;

UPDATE org_merchant_balances
SET outstanding_amount = 640.00, pending_payout_amount = 0, updated_at = NOW()
WHERE organization_id = 'b1000000-0000-4000-8000-000000000004';
