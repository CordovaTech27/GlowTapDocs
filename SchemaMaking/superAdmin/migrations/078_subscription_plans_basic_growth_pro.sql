-- Replace SaaS plans with Basic / Growth / Pro
-- description JSON: { tagline, billing, features: [{ name, desc, isAllowed }] }

DELETE FROM rms.billing_discount_configs
WHERE subscription_plan_id = 'd1000000-0000-4000-8000-000000000004';

UPDATE rms.billing_discount_configs
SET name = 'Growth Yearly — extra ₹500 off',
    updated_at = NOW()
WHERE id = 'c1000000-0000-4000-8000-000000000003';

DELETE FROM subscription.subscription_plans
WHERE id = 'd1000000-0000-4000-8000-000000000004';

INSERT INTO subscription.subscription_plans (id, name, description, max_branches, amount, updated_at)
VALUES
(
  'd1000000-0000-4000-8000-000000000001',
  'Basic',
  $json${
    "tagline": "Core salon ops & reporting",
    "billing": "₹999/month",
    "features": [
      { "name": "Revenue Dashboard", "desc": "Overview of salon revenue and earnings.", "isAllowed": true },
      { "name": "Appointment Analytics", "desc": "Track bookings, volume, and appointment trends.", "isAllowed": true },
      { "name": "Daily/Weekly/Monthly Reports", "desc": "Standard period reports for operations.", "isAllowed": true },
      { "name": "Customer Count & Growth", "desc": "Customer base size and growth over time.", "isAllowed": false },
      { "name": "Top Services Report", "desc": "Best-performing services by demand and revenue.", "isAllowed": false },
      { "name": "Peak Business Hours", "desc": "Identify busiest hours to plan staffing.", "isAllowed": false },
      { "name": "Repeat vs New Customers", "desc": "Split returning vs first-time customers.", "isAllowed": false },
      { "name": "Customer Retention Rate", "desc": "Measure how well you keep customers.", "isAllowed": false },
      { "name": "Stylist Performance Dashboard", "desc": "Compare stylist productivity and outcomes.", "isAllowed": false },
      { "name": "Service-wise Revenue Analysis", "desc": "Revenue breakdown by service.", "isAllowed": false },
      { "name": "Average Bill Value", "desc": "Track average ticket size.", "isAllowed": false },
      { "name": "No-show & Cancellation Analysis", "desc": "Monitor missed and cancelled appointments.", "isAllowed": true },
      { "name": "Product Sales Analytics", "desc": "Retail product sales insights.", "isAllowed": false },
      { "name": "Customer Segmentation", "desc": "Group customers by behaviour and value.", "isAllowed": false },
      { "name": "AI Revenue Recommendations", "desc": "AI suggestions to grow revenue.", "isAllowed": false },
      { "name": "Customer Churn Prediction", "desc": "Predict customers at risk of leaving.", "isAllowed": false },
      { "name": "Revenue Forecasting", "desc": "Forecast future revenue trends.", "isAllowed": false },
      { "name": "Demand Forecasting", "desc": "Forecast demand for services and slots.", "isAllowed": false },
      { "name": "Marketing Campaign ROI", "desc": "Measure return on marketing campaigns.", "isAllowed": false },
      { "name": "Membership & Package Analytics", "desc": "Insights on memberships and packages.", "isAllowed": false },
      { "name": "Multi-Branch Dashboard", "desc": "Cross-outlet dashboard (single location on Basic).", "isAllowed": false },
      { "name": "Custom Reports", "desc": "Build custom report views.", "isAllowed": false },
      { "name": "Export Reports (Excel/PDF)", "desc": "Download reports as Excel or PDF.", "isAllowed": true },
      { "name": "Priority Support", "desc": "Faster support response priority.", "isAllowed": false },
      { "name": "Dedicated Account Manager", "desc": "Named account manager for the salon.", "isAllowed": false },
      { "name": "Staff Management", "desc": "Manage staff, roles, and schedules.", "isAllowed": true }
    ]
  }$json$::text,
  1,
  999.00,
  NOW()
),
(
  'd1000000-0000-4000-8000-000000000002',
  'Growth',
  $json${
    "tagline": "Multi-outlet analytics up to 5 branches",
    "billing": "₹2,999/month",
    "features": [
      { "name": "Revenue Dashboard", "desc": "Overview of salon revenue and earnings.", "isAllowed": true },
      { "name": "Appointment Analytics", "desc": "Track bookings, volume, and appointment trends.", "isAllowed": true },
      { "name": "Daily/Weekly/Monthly Reports", "desc": "Standard period reports for operations.", "isAllowed": true },
      { "name": "Customer Count & Growth", "desc": "Customer base size and growth over time.", "isAllowed": true },
      { "name": "Top Services Report", "desc": "Best-performing services by demand and revenue.", "isAllowed": true },
      { "name": "Peak Business Hours", "desc": "Identify busiest hours to plan staffing.", "isAllowed": true },
      { "name": "Repeat vs New Customers", "desc": "Split returning vs first-time customers.", "isAllowed": false },
      { "name": "Customer Retention Rate", "desc": "Measure how well you keep customers.", "isAllowed": false },
      { "name": "Stylist Performance Dashboard", "desc": "Compare stylist productivity and outcomes.", "isAllowed": true },
      { "name": "Service-wise Revenue Analysis", "desc": "Revenue breakdown by service.", "isAllowed": true },
      { "name": "Average Bill Value", "desc": "Track average ticket size.", "isAllowed": true },
      { "name": "No-show & Cancellation Analysis", "desc": "Monitor missed and cancelled appointments.", "isAllowed": true },
      { "name": "Product Sales Analytics", "desc": "Retail product sales insights.", "isAllowed": true },
      { "name": "Customer Segmentation", "desc": "Group customers by behaviour and value.", "isAllowed": false },
      { "name": "AI Revenue Recommendations", "desc": "AI suggestions to grow revenue.", "isAllowed": false },
      { "name": "Customer Churn Prediction", "desc": "Predict customers at risk of leaving.", "isAllowed": false },
      { "name": "Revenue Forecasting", "desc": "Forecast future revenue trends.", "isAllowed": false },
      { "name": "Demand Forecasting", "desc": "Forecast demand for services and slots.", "isAllowed": false },
      { "name": "Marketing Campaign ROI", "desc": "Measure return on marketing campaigns.", "isAllowed": true },
      { "name": "Membership & Package Analytics", "desc": "Insights on memberships and packages.", "isAllowed": false },
      { "name": "Multi-Branch Dashboard", "desc": "Cross-outlet dashboard — included up to 5 outlets.", "isAllowed": true },
      { "name": "Custom Reports", "desc": "Build custom report views.", "isAllowed": false },
      { "name": "Export Reports (Excel/PDF)", "desc": "Download reports as Excel or PDF.", "isAllowed": true },
      { "name": "Priority Support", "desc": "Faster support response priority.", "isAllowed": true },
      { "name": "Dedicated Account Manager", "desc": "Named account manager for the salon.", "isAllowed": false },
      { "name": "Staff Management", "desc": "Manage staff, roles, and schedules.", "isAllowed": true }
    ]
  }$json$::text,
  5,
  2999.00,
  NOW()
),
(
  'd1000000-0000-4000-8000-000000000003',
  'Pro',
  $json${
    "tagline": "Full AI analytics, unlimited outlets",
    "billing": "₹4,999/month",
    "features": [
      { "name": "Revenue Dashboard", "desc": "Overview of salon revenue and earnings.", "isAllowed": true },
      { "name": "Appointment Analytics", "desc": "Track bookings, volume, and appointment trends.", "isAllowed": true },
      { "name": "Daily/Weekly/Monthly Reports", "desc": "Standard period reports for operations.", "isAllowed": true },
      { "name": "Customer Count & Growth", "desc": "Customer base size and growth over time.", "isAllowed": true },
      { "name": "Top Services Report", "desc": "Best-performing services by demand and revenue.", "isAllowed": true },
      { "name": "Peak Business Hours", "desc": "Identify busiest hours to plan staffing.", "isAllowed": true },
      { "name": "Repeat vs New Customers", "desc": "Split returning vs first-time customers.", "isAllowed": true },
      { "name": "Customer Retention Rate", "desc": "Measure how well you keep customers.", "isAllowed": true },
      { "name": "Stylist Performance Dashboard", "desc": "Compare stylist productivity and outcomes.", "isAllowed": true },
      { "name": "Service-wise Revenue Analysis", "desc": "Revenue breakdown by service.", "isAllowed": true },
      { "name": "Average Bill Value", "desc": "Track average ticket size.", "isAllowed": true },
      { "name": "No-show & Cancellation Analysis", "desc": "Monitor missed and cancelled appointments.", "isAllowed": true },
      { "name": "Product Sales Analytics", "desc": "Retail product sales insights.", "isAllowed": true },
      { "name": "Customer Segmentation", "desc": "Group customers by behaviour and value.", "isAllowed": true },
      { "name": "AI Revenue Recommendations", "desc": "AI suggestions to grow revenue.", "isAllowed": true },
      { "name": "Customer Churn Prediction", "desc": "Predict customers at risk of leaving.", "isAllowed": true },
      { "name": "Revenue Forecasting", "desc": "Forecast future revenue trends.", "isAllowed": true },
      { "name": "Demand Forecasting", "desc": "Forecast demand for services and slots.", "isAllowed": true },
      { "name": "Marketing Campaign ROI", "desc": "Measure return on marketing campaigns.", "isAllowed": true },
      { "name": "Membership & Package Analytics", "desc": "Insights on memberships and packages.", "isAllowed": true },
      { "name": "Multi-Branch Dashboard", "desc": "Cross-outlet dashboard for unlimited branches.", "isAllowed": true },
      { "name": "Custom Reports", "desc": "Build custom report views.", "isAllowed": true },
      { "name": "Export Reports (Excel/PDF)", "desc": "Download reports as Excel or PDF.", "isAllowed": true },
      { "name": "Priority Support", "desc": "Faster support response priority.", "isAllowed": true },
      { "name": "Dedicated Account Manager", "desc": "Named account manager for the salon.", "isAllowed": true },
      { "name": "Staff Management", "desc": "Manage staff, roles, and schedules.", "isAllowed": true }
    ]
  }$json$::text,
  999,
  4999.00,
  NOW()
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  max_branches = EXCLUDED.max_branches,
  amount = EXCLUDED.amount,
  updated_at = NOW();
