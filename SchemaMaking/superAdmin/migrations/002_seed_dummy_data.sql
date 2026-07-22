-- Dummy seed data: one Super Admin, salon orgs (Zomato-style chains), branches with locations

-- Fixed UUIDs keep docs and API examples stable across re-seeds.

INSERT INTO super_admin_users (id, full_name, email, phone, role, status, mfa_enabled, last_login_at)
VALUES (
  'a1000000-0000-4000-8000-000000000001',
  'Arjun Nair',
  'admin@glowtap.com',
  '+91 98765 43210',
  'SUPER_ADMIN',
  'ACTIVE',
  TRUE,
  '2026-07-11 09:30:00+05:30'
)
ON CONFLICT (id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  email = EXCLUDED.email,
  updated_at = NOW();

INSERT INTO subscription_plans (id, name, description, max_branches) VALUES
(
  'd1000000-0000-4000-8000-000000000001',
  'Starter',
  'Single-location salon. 1 branch included.',
  1
),
(
  'd1000000-0000-4000-8000-000000000002',
  'Growth',
  'Small multi-location chain. Up to 3 branches.',
  3
),
(
  'd1000000-0000-4000-8000-000000000003',
  'Professional',
  'Mid-size salon chain. Up to 10 branches.',
  10
),
(
  'd1000000-0000-4000-8000-000000000004',
  'Enterprise',
  'Large franchise or national chain. Unlimited branches.',
  999
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  max_branches = EXCLUDED.max_branches,
  updated_at = NOW();

INSERT INTO organizations (
  id, name, slug, legal_name, owner_name, owner_email, owner_phone,
  gst_number, pan_number, registered_address, city, state, pincode,
  status, subscription_plan_id, commission_pct,
  onboarded_at, approved_at, approved_by
) VALUES
(
  'b1000000-0000-4000-8000-000000000001',
  'Looks Salon & Spa',
  'looks-salon-spa',
  'Looks Beauty Ventures Pvt Ltd',
  'Priya Kapoor',
  'priya@lookssalon.in',
  '+91 98200 11223',
  '27AABCL1234F1Z5',
  'AABCL1234F',
  '{"line1":"402, Oberoi Commerz II","line2":"Goregaon East","landmark":"Near Oberoi Mall","city":"Mumbai","state":"Maharashtra","pincode":"400063","country":"India"}',
  'Mumbai', 'Maharashtra', '400063',
  'ACTIVE', 'd1000000-0000-4000-8000-000000000002', 8.00,
  '2025-11-15 14:00:00+05:30', '2025-11-16 10:00:00+05:30',
  'a1000000-0000-4000-8000-000000000001'
),
(
  'b1000000-0000-4000-8000-000000000002',
  'Glamour Zone',
  'glamour-zone',
  'Glamour Zone Salons LLP',
  'Rahul Mehta',
  'rahul@glamourzone.in',
  '+91 98100 44556',
  '07AABCG5678G1Z2',
  'AABCG5678G',
  '{"line1":"B-14, Inner Circle","line2":"Connaught Place","landmark":"Opposite Rajiv Chowk Metro","city":"New Delhi","state":"Delhi","pincode":"110001","country":"India"}',
  'New Delhi', 'Delhi', '110001',
  'ACTIVE', 'd1000000-0000-4000-8000-000000000003', 6.50,
  '2026-01-08 11:30:00+05:30', '2026-01-09 09:15:00+05:30',
  'a1000000-0000-4000-8000-000000000001'
),
(
  'b1000000-0000-4000-8000-000000000003',
  'Enrich Salon',
  'enrich-salon',
  'Enrich Hair & Skin Pvt Ltd',
  'Meera Reddy',
  'meera@enrichsalon.com',
  '+91 98450 77889',
  '29AABCE9012H1Z8',
  'AABCE9012H',
  '{"line1":"88, 5th Block","line2":"Koramangala","landmark":"Near Forum Mall","city":"Bengaluru","state":"Karnataka","pincode":"560095","country":"India"}',
  'Bengaluru', 'Karnataka', '560095',
  'ACTIVE', 'd1000000-0000-4000-8000-000000000001', 10.00,
  '2026-03-20 16:45:00+05:30', '2026-03-21 08:30:00+05:30',
  'a1000000-0000-4000-8000-000000000001'
),
(
  'b1000000-0000-4000-8000-000000000004',
  'Naturals Salon Partners',
  'naturals-salon-partners',
  'Naturals Franchise South India Pvt Ltd',
  'Karthik Subramanian',
  'karthik@naturalssouth.in',
  '+91 94440 55667',
  '33AABCN3456J1Z1',
  'AABCN3456J',
  '{"line1":"12, Usman Road","line2":"T Nagar","landmark":"Near Panagal Park","city":"Chennai","state":"Tamil Nadu","pincode":"600017","country":"India"}',
  'Chennai', 'Tamil Nadu', '600017',
  'ACTIVE', 'd1000000-0000-4000-8000-000000000004', 5.00,
  '2025-06-01 10:00:00+05:30', '2025-06-02 11:00:00+05:30',
  'a1000000-0000-4000-8000-000000000001'
),
(
  'b1000000-0000-4000-8000-000000000005',
  'Blush & Bloom',
  'blush-and-bloom',
  NULL,
  'Kavya Desai',
  'kavya@blushbloom.in',
  '+91 98220 33445',
  NULL,
  NULL,
  '{"line1":"Shop 3, Phoenix Market City","line2":"Viman Nagar","landmark":"Ground floor near main atrium","city":"Pune","state":"Maharashtra","pincode":"411014","country":"India"}',
  'Pune', 'Maharashtra', '411014',
  'PENDING', 'd1000000-0000-4000-8000-000000000002', 5.00,
  NULL, NULL, NULL
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  status = EXCLUDED.status,
  updated_at = NOW();

INSERT INTO branches (
  id, organization_id, name, slug, address, contact_phone, contact_email,
  operating_hours, latitude, longitude, status, is_primary,
  approved_at, approved_by
) VALUES
-- Looks Salon & Spa (3 branches: 2 live, 1 pending approval)
(
  'c1000000-0000-4000-8000-000000000001',
  'b1000000-0000-4000-8000-000000000001',
  'Looks — Andheri West',
  'andheri-west',
  '{"line1":"Shop 7, Infiniti Mall","line2":"Link Road, Andheri West","landmark":"Infiniti Mall, 2nd floor","city":"Mumbai","state":"Maharashtra","pincode":"400053","country":"India"}',
  '+91 98200 11224', 'andheri@lookssalon.in',
  '{"mon":{"open":"10:00","close":"21:00"},"tue":{"open":"10:00","close":"21:00"},"wed":{"open":"10:00","close":"21:00"},"thu":{"open":"10:00","close":"21:00"},"fri":{"open":"10:00","close":"21:00"},"sat":{"open":"10:00","close":"22:00"},"sun":{"open":"11:00","close":"20:00"}}',
  19.1404000, 72.8354000, 'ACTIVE', TRUE,
  '2025-11-16 10:30:00+05:30', 'a1000000-0000-4000-8000-000000000001'
),
(
  'c1000000-0000-4000-8000-000000000002',
  'b1000000-0000-4000-8000-000000000001',
  'Looks — Bandra',
  'bandra',
  '{"line1":"14, Hill Road","line2":"Bandra West","landmark":"Opposite St. Andrews Church","city":"Mumbai","state":"Maharashtra","pincode":"400050","country":"India"}',
  '+91 98200 11225', 'bandra@lookssalon.in',
  '{"mon":{"open":"10:00","close":"21:00"},"tue":{"open":"10:00","close":"21:00"},"wed":{"open":"10:00","close":"21:00"},"thu":{"open":"10:00","close":"21:00"},"fri":{"open":"10:00","close":"21:00"},"sat":{"open":"10:00","close":"22:00"},"sun":{"open":"11:00","close":"20:00"}}',
  19.0596000, 72.8295000, 'ACTIVE', FALSE,
  '2026-02-10 15:00:00+05:30', 'a1000000-0000-4000-8000-000000000001'
),
(
  'c1000000-0000-4000-8000-000000000003',
  'b1000000-0000-4000-8000-000000000001',
  'Looks — Powai',
  'powai',
  '{"line1":"Unit 9, Hiranandani Gardens","line2":"Powai","landmark":"Near Powai Lake","city":"Mumbai","state":"Maharashtra","pincode":"400076","country":"India"}',
  '+91 98200 11226', 'powai@lookssalon.in',
  '{"mon":{"open":"10:00","close":"21:00"},"tue":{"open":"10:00","close":"21:00"},"wed":{"open":"10:00","close":"21:00"},"thu":{"open":"10:00","close":"21:00"},"fri":{"open":"10:00","close":"21:00"},"sat":{"open":"10:00","close":"22:00"},"sun":{"open":"11:00","close":"20:00"}}',
  19.1176000, 72.9060000, 'PENDING', FALSE,
  NULL, NULL
),
-- Glamour Zone (2 branches: 1 live, 1 pending)
(
  'c1000000-0000-4000-8000-000000000004',
  'b1000000-0000-4000-8000-000000000002',
  'Glamour Zone — Connaught Place',
  'connaught-place',
  '{"line1":"B-14, Inner Circle","line2":"Connaught Place","landmark":"Opposite Rajiv Chowk Metro Exit 4","city":"New Delhi","state":"Delhi","pincode":"110001","country":"India"}',
  '+91 98100 44557', 'cp@glamourzone.in',
  '{"mon":{"open":"09:30","close":"21:30"},"tue":{"open":"09:30","close":"21:30"},"wed":{"open":"09:30","close":"21:30"},"thu":{"open":"09:30","close":"21:30"},"fri":{"open":"09:30","close":"21:30"},"sat":{"open":"09:30","close":"22:00"},"sun":{"open":"10:00","close":"20:00"}}',
  28.6315000, 77.2167000, 'ACTIVE', TRUE,
  '2026-01-09 09:30:00+05:30', 'a1000000-0000-4000-8000-000000000001'
),
(
  'c1000000-0000-4000-8000-000000000005',
  'b1000000-0000-4000-8000-000000000002',
  'Glamour Zone — Saket',
  'saket',
  '{"line1":"F-42, Select Citywalk","line2":"Saket","landmark":"Select Citywalk Mall, Level 1","city":"New Delhi","state":"Delhi","pincode":"110017","country":"India"}',
  '+91 98100 44558', 'saket@glamourzone.in',
  '{"mon":{"open":"10:00","close":"22:00"},"tue":{"open":"10:00","close":"22:00"},"wed":{"open":"10:00","close":"22:00"},"thu":{"open":"10:00","close":"22:00"},"fri":{"open":"10:00","close":"22:00"},"sat":{"open":"10:00","close":"22:30"},"sun":{"open":"10:00","close":"21:00"}}',
  28.5244000, 77.2066000, 'PENDING', FALSE,
  NULL, NULL
),
-- Enrich Salon (single branch starter plan)
(
  'c1000000-0000-4000-8000-000000000006',
  'b1000000-0000-4000-8000-000000000003',
  'Enrich — Koramangala',
  'koramangala',
  '{"line1":"88, 5th Block","line2":"Koramangala","landmark":"Near Forum Mall signal","city":"Bengaluru","state":"Karnataka","pincode":"560095","country":"India"}',
  '+91 98450 77890', 'koramangala@enrichsalon.com',
  '{"mon":{"open":"10:00","close":"20:30"},"tue":{"open":"10:00","close":"20:30"},"wed":{"open":"10:00","close":"20:30"},"thu":{"open":"10:00","close":"20:30"},"fri":{"open":"10:00","close":"20:30"},"sat":{"open":"10:00","close":"21:00"},"sun":{"closed":true}}',
  12.9352000, 77.6245000, 'ACTIVE', TRUE,
  '2026-03-21 08:45:00+05:30', 'a1000000-0000-4000-8000-000000000001'
),
-- Naturals (multi-branch enterprise chain)
(
  'c1000000-0000-4000-8000-000000000007',
  'b1000000-0000-4000-8000-000000000004',
  'Naturals — T Nagar',
  't-nagar',
  '{"line1":"12, Usman Road","line2":"T Nagar","landmark":"Near Panagal Park","city":"Chennai","state":"Tamil Nadu","pincode":"600017","country":"India"}',
  '+91 94440 55668', 'tnagar@naturalssouth.in',
  '{"mon":{"open":"09:00","close":"21:00"},"tue":{"open":"09:00","close":"21:00"},"wed":{"open":"09:00","close":"21:00"},"thu":{"open":"09:00","close":"21:00"},"fri":{"open":"09:00","close":"21:00"},"sat":{"open":"09:00","close":"21:30"},"sun":{"open":"10:00","close":"20:00"}}',
  13.0418000, 80.2341000, 'ACTIVE', TRUE,
  '2025-06-02 11:30:00+05:30', 'a1000000-0000-4000-8000-000000000001'
),
(
  'c1000000-0000-4000-8000-000000000008',
  'b1000000-0000-4000-8000-000000000004',
  'Naturals — Anna Nagar',
  'anna-nagar',
  '{"line1":"W-48, 2nd Avenue","line2":"Anna Nagar West","landmark":"Near Tower Park","city":"Chennai","state":"Tamil Nadu","pincode":"600040","country":"India"}',
  '+91 94440 55669', 'annanagar@naturalssouth.in',
  '{"mon":{"open":"09:00","close":"21:00"},"tue":{"open":"09:00","close":"21:00"},"wed":{"open":"09:00","close":"21:00"},"thu":{"open":"09:00","close":"21:00"},"fri":{"open":"09:00","close":"21:00"},"sat":{"open":"09:00","close":"21:30"},"sun":{"open":"10:00","close":"20:00"}}',
  13.0878000, 80.2085000, 'ACTIVE', FALSE,
  '2025-08-14 10:00:00+05:30', 'a1000000-0000-4000-8000-000000000001'
),
(
  'c1000000-0000-4000-8000-000000000009',
  'b1000000-0000-4000-8000-000000000004',
  'Naturals — Adyar',
  'adyar',
  '{"line1":"15, Lattice Bridge Road","line2":"Adyar","landmark":"Opposite Adyar Bus Depot","city":"Chennai","state":"Tamil Nadu","pincode":"600020","country":"India"}',
  '+91 94440 55670', 'adyar@naturalssouth.in',
  '{"mon":{"open":"09:00","close":"21:00"},"tue":{"open":"09:00","close":"21:00"},"wed":{"open":"09:00","close":"21:00"},"thu":{"open":"09:00","close":"21:00"},"fri":{"open":"09:00","close":"21:00"},"sat":{"open":"09:00","close":"21:30"},"sun":{"open":"10:00","close":"20:00"}}',
  13.0067000, 80.2575000, 'ACTIVE', FALSE,
  '2025-10-01 14:00:00+05:30', 'a1000000-0000-4000-8000-000000000001'
),
(
  'c1000000-0000-4000-8000-000000000010',
  'b1000000-0000-4000-8000-000000000004',
  'Naturals — OMR Sholinganallur',
  'omr-sholinganallur',
  '{"line1":"Plot 22, OMR","line2":"Sholinganallur","landmark":"Near SRP Tools signal","city":"Chennai","state":"Tamil Nadu","pincode":"600119","country":"India"}',
  '+91 94440 55671', 'omr@naturalssouth.in',
  '{"mon":{"open":"09:00","close":"21:00"},"tue":{"open":"09:00","close":"21:00"},"wed":{"open":"09:00","close":"21:00"},"thu":{"open":"09:00","close":"21:00"},"fri":{"open":"09:00","close":"21:00"},"sat":{"open":"09:00","close":"21:30"},"sun":{"open":"10:00","close":"20:00"}}',
  12.9010000, 80.2279000, 'PENDING', FALSE,
  NULL, NULL
),
-- Blush & Bloom (org still pending — branch submitted with signup)
(
  'c1000000-0000-4000-8000-000000000011',
  'b1000000-0000-4000-8000-000000000005',
  'Blush & Bloom — Viman Nagar',
  'viman-nagar',
  '{"line1":"Shop 3, Phoenix Market City","line2":"Viman Nagar","landmark":"Ground floor near main atrium","city":"Pune","state":"Maharashtra","pincode":"411014","country":"India"}',
  '+91 98220 33446', 'kavya@blushbloom.in',
  '{"mon":{"open":"10:00","close":"21:00"},"tue":{"open":"10:00","close":"21:00"},"wed":{"open":"10:00","close":"21:00"},"thu":{"open":"10:00","close":"21:00"},"fri":{"open":"10:00","close":"21:00"},"sat":{"open":"10:00","close":"22:00"},"sun":{"open":"11:00","close":"19:00"}}',
  18.5679000, 73.9143000, 'PENDING', TRUE,
  NULL, NULL
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  status = EXCLUDED.status,
  updated_at = NOW();
