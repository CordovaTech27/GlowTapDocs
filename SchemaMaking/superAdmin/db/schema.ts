import {
  pgSchema,
  pgTable,
  uuid,
  varchar,
  text,
  boolean,
  timestamp,
  jsonb,
  numeric,
  integer,
  bigint,
  unique,
  primaryKey,
  date,
} from 'drizzle-orm/pg-core';

/** Revenue Management System — billing, invoices, payments, marketplace settlement */
export const rms = pgSchema('rms');

/** Salon Admin org portal — sub-admins, branch/module access (not Super Admin) */
export const adminOrg = pgSchema('admin_org');

/** CMS & portal banners — website content + salon portal promos */
export const cms = pgSchema('cms');

/** Reviews & ratings moderation */
export const review = pgSchema('review');

/** Support ticketing — CTS, SLA, tickets thread */
export const tickets = pgSchema('tickets');

/** Platform service catalog — Category → Subcategory */
export const services = pgSchema('services');

/** SaaS subscription plans + org plan-change history */
export const subscription = pgSchema('subscription');

/** Salon staff — employees, offs, leave, holidays, attendance */
export const employee = pgSchema('employee');

/** Bookings — holds, appointments, audit (slots from service duration) */
export const appointments = pgSchema('appointments');

export const superAdminUsers = pgTable('super_admin_users', {
  id: uuid('id').primaryKey().defaultRandom(),
  fullName: varchar('full_name', { length: 255 }).notNull(),
  email: varchar('email', { length: 255 }).notNull().unique(),
  phone: varchar('phone', { length: 20 }),
  role: varchar('role', { length: 30 }).notNull().default('SUPER_ADMIN'),
  status: varchar('status', { length: 20 }).notNull().default('ACTIVE'),
  mfaEnabled: boolean('mfa_enabled').notNull().default(false),
  lastLoginAt: timestamp('last_login_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const subscriptionPlans = subscription.table('subscription_plans', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: varchar('name', { length: 100 }).notNull(),
  description: text('description'),
  maxBranches: integer('max_branches').notNull(),
  amount: numeric('amount', { precision: 12, scale: 2 }).notNull().default('0'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const billingCycles = rms.table('billing_cycles', {
  id: uuid('id').primaryKey().defaultRandom(),
  code: varchar('code', { length: 30 }).notNull().unique(),
  name: varchar('name', { length: 50 }).notNull(),
  description: text('description'),
  intervalMonths: integer('interval_months').notNull(),
  isActive: boolean('is_active').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const billingDiscountConfigs = rms.table('billing_discount_configs', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: varchar('name', { length: 100 }).notNull(),
  subscriptionPlanId: uuid('subscription_plan_id').references(() => subscriptionPlans.id, {
    onDelete: 'cascade',
  }),
  billingCycleId: uuid('billing_cycle_id').references(() => billingCycles.id, {
    onDelete: 'cascade',
  }),
  discountType: varchar('discount_type', { length: 20 }).notNull(),
  discountValue: numeric('discount_value', { precision: 12, scale: 2 }).notNull(),
  priority: integer('priority').notNull().default(100),
  isStackable: boolean('is_stackable').notNull().default(false),
  isActive: boolean('is_active').notNull().default(true),
  effectiveFrom: date('effective_from').notNull(),
  effectiveTo: date('effective_to'),
  notes: text('notes'),
  createdBy: uuid('created_by').references(() => superAdminUsers.id),
  updatedBy: uuid('updated_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const states = pgTable('states', {
  id: uuid('id').primaryKey().defaultRandom(),
  code: varchar('code', { length: 2 }).notNull().unique(),
  name: varchar('name', { length: 100 }).notNull(),
  isoCode: varchar('iso_code', { length: 3 }),
  isUnionTerritory: boolean('is_union_territory').notNull().default(false),
  isActive: boolean('is_active').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const stateTaxConfigs = rms.table(
  'state_tax_configs',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    stateId: uuid('state_id')
      .notNull()
      .references(() => states.id, { onDelete: 'cascade' }),
    taxCode: varchar('tax_code', { length: 30 }).notNull(),
    taxName: varchar('tax_name', { length: 100 }).notNull(),
    ratePct: numeric('rate_pct', { precision: 5, scale: 2 }).notNull(),
    hsnSacCode: varchar('hsn_sac_code', { length: 10 }),
    componentType: varchar('component_type', { length: 20 }).notNull(),
    appliesTo: varchar('applies_to', { length: 20 }).notNull().default('SERVICE'),
    effectiveFrom: date('effective_from').notNull(),
    effectiveTo: date('effective_to'),
    isActive: boolean('is_active').notNull().default(true),
    notes: text('notes'),
    createdBy: uuid('created_by').references(() => superAdminUsers.id),
    updatedBy: uuid('updated_by').references(() => superAdminUsers.id),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [unique().on(table.stateId, table.taxCode, table.effectiveFrom)]
);

export const reasonCodes = pgTable(
  'reason_codes',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    category: varchar('category', { length: 20 }).notNull(),
    code: varchar('code', { length: 50 }).notNull(),
    label: varchar('label', { length: 255 }).notNull(),
    description: text('description'),
    pricingImpact: jsonb('pricing_impact'),
    isActive: boolean('is_active').notNull().default(true),
    sortOrder: integer('sort_order').notNull().default(0),
    createdBy: uuid('created_by').references(() => superAdminUsers.id),
    updatedBy: uuid('updated_by').references(() => superAdminUsers.id),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [unique().on(table.category, table.code)]
);

export const organizations = pgTable('organizations', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: varchar('name', { length: 255 }).notNull(),
  slug: varchar('slug', { length: 100 }).notNull().unique(),
  legalName: varchar('legal_name', { length: 255 }),
  ownerName: varchar('owner_name', { length: 255 }).notNull(),
  ownerEmail: varchar('owner_email', { length: 255 }).notNull(),
  ownerPhone: varchar('owner_phone', { length: 20 }),
  gstNumber: varchar('gst_number', { length: 50 }),
  panNumber: varchar('pan_number', { length: 20 }),
  logoUrl: text('logo_url'),
  kycDocumentUrl: text('kyc_document_url'),
  gstCertificateUrl: text('gst_certificate_url'),
  photoUrl: text('photo_url'),
  registeredAddress: jsonb('registered_address').notNull(),
  stateId: uuid('state_id')
    .notNull()
    .references(() => states.id),
  campaignAttribution: jsonb('campaign_attribution'),
  businessType: varchar('business_type', { length: 30 }),
  cin: varchar('cin', { length: 21 }),
  udyamMsmeNumber: varchar('udyam_msme_number', { length: 20 }),
  gstRegistrationType: varchar('gst_registration_type', { length: 20 }),
  kycStatus: varchar('kyc_status', { length: 20 }).notNull().default('NOT_SUBMITTED'),
  kycVerifiedAt: timestamp('kyc_verified_at', { withTimezone: true }),
  kycVerifiedBy: uuid('kyc_verified_by').references(() => superAdminUsers.id),
  signedAgreementUrl: text('signed_agreement_url'),
  isAgreementSigned: boolean('is_agreement_signed').notNull().default(false),
  status: varchar('status', { length: 20 }).notNull().default('PENDING'),
  statusReasonId: uuid('status_reason_id').references(() => reasonCodes.id),
  statusNotes: text('status_notes'),
  statusChangedAt: timestamp('status_changed_at', { withTimezone: true }),
  statusChangedBy: uuid('status_changed_by').references(() => superAdminUsers.id),
  suspendedAt: timestamp('suspended_at', { withTimezone: true }),
  resumedAt: timestamp('resumed_at', { withTimezone: true }),
  terminatedAt: timestamp('terminated_at', { withTimezone: true }),
  onboardedAt: timestamp('onboarded_at', { withTimezone: true }),
  approvedAt: timestamp('approved_at', { withTimezone: true }),
  approvedBy: uuid('approved_by').references(() => superAdminUsers.id),
  /** Salon Admin portal login (§4.8.1) — profile remains owner_* */
  ownerPortalStatus: varchar('owner_portal_status', { length: 20 }).notNull().default('ACTIVE'),
  ownerLastLoginAt: timestamp('owner_last_login_at', { withTimezone: true }),
  ownerDisabledAt: timestamp('owner_disabled_at', { withTimezone: true }),
  ownerDisabledBy: uuid('owner_disabled_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const branches = pgTable(
  'branches',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    organizationId: uuid('organization_id')
      .notNull()
      .references(() => organizations.id, { onDelete: 'cascade' }),
    name: varchar('name', { length: 255 }).notNull(),
    slug: varchar('slug', { length: 100 }).notNull(),
    address: jsonb('address').notNull(),
    contactPhone: varchar('contact_phone', { length: 20 }),
    contactEmail: varchar('contact_email', { length: 255 }),
    operatingHours: jsonb('operating_hours'),
    weeklyOffDays: integer('weekly_off_days').array().notNull().default([]),
    latitude: numeric('latitude', { precision: 10, scale: 7 }),
    longitude: numeric('longitude', { precision: 10, scale: 7 }),
    status: varchar('status', { length: 20 }).notNull().default('PENDING'),
    isPrimary: boolean('is_primary').notNull().default(false),
    kycDocumentUrl: text('kyc_document_url'),
    gstCertificateUrl: text('gst_certificate_url'),
    photoUrl: text('photo_url'),
    stateId: uuid('state_id').references(() => states.id),
    shopEstablishmentLicenseUrl: text('shop_establishment_license_url'),
    shopEstablishmentLicenseNumber: varchar('shop_establishment_license_number', { length: 50 }),
    tradeLicenseUrl: text('trade_license_url'),
    tradeLicenseNumber: varchar('trade_license_number', { length: 50 }),
    branchGstNumber: varchar('branch_gst_number', { length: 50 }),
    kycStatus: varchar('kyc_status', { length: 20 }).notNull().default('NOT_SUBMITTED'),
    kycVerifiedAt: timestamp('kyc_verified_at', { withTimezone: true }),
    kycVerifiedBy: uuid('kyc_verified_by').references(() => superAdminUsers.id),
    signedAgreementUrl: text('signed_agreement_url'),
    isAgreementSigned: boolean('is_agreement_signed').notNull().default(false),
    approvedAt: timestamp('approved_at', { withTimezone: true }),
    approvedBy: uuid('approved_by').references(() => superAdminUsers.id),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [unique().on(table.organizationId, table.slug)]
);

/** §4.8.2 Sub Admins — created by Salon Admin; Super Admin view + disable only */
export const subAdmins = adminOrg.table('sub_admins', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  fullName: varchar('full_name', { length: 255 }).notNull(),
  email: varchar('email', { length: 255 }).notNull(),
  phone: varchar('phone', { length: 20 }),
  status: varchar('status', { length: 20 }).notNull().default('ACTIVE'),
  disabledByRole: varchar('disabled_by_role', { length: 20 }),
  disabledAt: timestamp('disabled_at', { withTimezone: true }),
  disabledBySuperAdminId: uuid('disabled_by_super_admin_id').references(() => superAdminUsers.id),
  lastLoginAt: timestamp('last_login_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const subAdminBranches = adminOrg.table(
  'sub_admin_branches',
  {
    subAdminId: uuid('sub_admin_id')
      .notNull()
      .references(() => subAdmins.id, { onDelete: 'cascade' }),
    branchId: uuid('branch_id')
      .notNull()
      .references(() => branches.id, { onDelete: 'cascade' }),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [primaryKey({ columns: [table.subAdminId, table.branchId] })]
);

export const subAdminModules = adminOrg.table(
  'sub_admin_modules',
  {
    subAdminId: uuid('sub_admin_id')
      .notNull()
      .references(() => subAdmins.id, { onDelete: 'cascade' }),
    module: varchar('module', { length: 30 }).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [primaryKey({ columns: [table.subAdminId, table.module] })]
);

export const userAccessActions = pgTable('user_access_actions', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  targetType: varchar('target_type', { length: 20 }).notNull(),
  subAdminId: uuid('sub_admin_id').references(() => subAdmins.id, { onDelete: 'set null' }),
  action: varchar('action', { length: 30 }).notNull(),
  reason: text('reason'),
  metadata: jsonb('metadata'),
  performedBy: uuid('performed_by').references(() => superAdminUsers.id),
  performedAt: timestamp('performed_at', { withTimezone: true }).notNull().defaultNow(),
});

export const orgStatusActions = pgTable('org_status_actions', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  action: varchar('action', { length: 20 }).notNull(),
  fromStatus: varchar('from_status', { length: 20 }).notNull(),
  toStatus: varchar('to_status', { length: 20 }).notNull(),
  reasonCodeId: uuid('reason_code_id').references(() => reasonCodes.id),
  notes: text('notes'),
  performedBy: uuid('performed_by').references(() => superAdminUsers.id),
  performedAt: timestamp('performed_at', { withTimezone: true }).notNull().defaultNow(),
});

export const orgBillStructure = rms.table('org_bill_structure', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  subscriptionPlanId: uuid('subscription_plan_id')
    .notNull()
    .references(() => subscriptionPlans.id),
  billingCycleId: uuid('billing_cycle_id')
    .notNull()
    .references(() => billingCycles.id),
  stateId: uuid('state_id').references(() => states.id),
  startDate: date('start_date').notNull(),
  renewalDate: date('renewal_date').notNull(),
  paymentMethod: varchar('payment_method', { length: 30 }).notNull(),
  commissionPct: numeric('commission_pct', { precision: 5, scale: 2 }).notNull().default('5.00'),
  platformFeeAmount: numeric('platform_fee_amount', { precision: 12, scale: 2 }),
  currency: varchar('currency', { length: 3 }).notNull().default('INR'),
  autoRenew: boolean('auto_renew').notNull().default(true),
  gracePeriodDays: integer('grace_period_days').notNull().default(7),
  freeUsageDays: integer('free_usage_days').notNull().default(0),
  lastPaymentAt: timestamp('last_payment_at', { withTimezone: true }),
  paymentReference: varchar('payment_reference', { length: 100 }),
  status: varchar('status', { length: 20 }).notNull().default('ACTIVE'),
  notes: text('notes'),
  configuredBy: uuid('configured_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const orgSubscriptionChanges = subscription.table('org_subscription_changes', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  orgBillStructureId: uuid('org_bill_structure_id')
    .notNull()
    .references(() => orgBillStructure.id, { onDelete: 'cascade' }),
  changeType: varchar('change_type', { length: 20 }).notNull(),
  fromSubscriptionPlanId: uuid('from_subscription_plan_id')
    .notNull()
    .references(() => subscriptionPlans.id),
  toSubscriptionPlanId: uuid('to_subscription_plan_id')
    .notNull()
    .references(() => subscriptionPlans.id),
  fromBillingCycleId: uuid('from_billing_cycle_id').references(() => billingCycles.id),
  toBillingCycleId: uuid('to_billing_cycle_id').references(() => billingCycles.id),
  effectiveDate: date('effective_date').notNull(),
  notes: text('notes'),
  performedBy: uuid('performed_by').references(() => superAdminUsers.id),
  performedAt: timestamp('performed_at', { withTimezone: true }).notNull().defaultNow(),
});

/** Salon → GlowTap subscription invoices (Stripe/Chargebee-style + GST lines) */
export const invoices = rms.table('invoices', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  orgBillStructureId: uuid('org_bill_structure_id').references(() => orgBillStructure.id, {
    onDelete: 'set null',
  }),
  invoiceNumber: varchar('invoice_number', { length: 50 }).notNull().unique(),
  invoiceType: varchar('invoice_type', { length: 20 }).notNull(),
  status: varchar('status', { length: 20 }).notNull().default('DRAFT'),
  currency: varchar('currency', { length: 3 }).notNull().default('INR'),
  subtotalAmount: numeric('subtotal_amount', { precision: 12, scale: 2 }).notNull().default('0'),
  discountAmount: numeric('discount_amount', { precision: 12, scale: 2 }).notNull().default('0'),
  taxableAmount: numeric('taxable_amount', { precision: 12, scale: 2 }).notNull().default('0'),
  taxAmount: numeric('tax_amount', { precision: 12, scale: 2 }).notNull().default('0'),
  totalAmount: numeric('total_amount', { precision: 12, scale: 2 }).notNull().default('0'),
  amountPaid: numeric('amount_paid', { precision: 12, scale: 2 }).notNull().default('0'),
  amountDue: numeric('amount_due', { precision: 12, scale: 2 }).notNull().default('0'),
  billingPeriodStart: date('billing_period_start'),
  billingPeriodEnd: date('billing_period_end'),
  issueDate: date('issue_date').notNull(),
  dueDate: date('due_date'),
  paidAt: timestamp('paid_at', { withTimezone: true }),
  pdfUrl: text('pdf_url'),
  notes: text('notes'),
  orgSubscriptionChangeId: uuid('org_subscription_change_id').references(
    () => orgSubscriptionChanges.id,
    { onDelete: 'set null' }
  ),
  createdBy: uuid('created_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const invoiceLineItems = rms.table('invoice_line_items', {
  id: uuid('id').primaryKey().defaultRandom(),
  invoiceId: uuid('invoice_id')
    .notNull()
    .references(() => invoices.id, { onDelete: 'cascade' }),
  lineType: varchar('line_type', { length: 20 }).notNull(),
  description: varchar('description', { length: 255 }).notNull(),
  subscriptionPlanId: uuid('subscription_plan_id').references(() => subscriptionPlans.id),
  billingCycleId: uuid('billing_cycle_id').references(() => billingCycles.id),
  quantity: numeric('quantity', { precision: 12, scale: 2 }).notNull().default('1'),
  unitAmount: numeric('unit_amount', { precision: 12, scale: 2 }).notNull().default('0'),
  amount: numeric('amount', { precision: 12, scale: 2 }).notNull().default('0'),
  discountAmount: numeric('discount_amount', { precision: 12, scale: 2 }).notNull().default('0'),
  taxableAmount: numeric('taxable_amount', { precision: 12, scale: 2 }).notNull().default('0'),
  sortOrder: integer('sort_order').notNull().default(0),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const invoiceTaxLines = rms.table('invoice_tax_lines', {
  id: uuid('id').primaryKey().defaultRandom(),
  invoiceLineItemId: uuid('invoice_line_item_id')
    .notNull()
    .references(() => invoiceLineItems.id, { onDelete: 'cascade' }),
  stateTaxConfigId: uuid('state_tax_config_id')
    .notNull()
    .references(() => stateTaxConfigs.id),
  taxableAmount: numeric('taxable_amount', { precision: 12, scale: 2 }).notNull(),
  taxAmount: numeric('tax_amount', { precision: 12, scale: 2 }).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const payments = rms.table('payments', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  paymentNumber: varchar('payment_number', { length: 50 }).notNull().unique(),
  amount: numeric('amount', { precision: 12, scale: 2 }).notNull(),
  currency: varchar('currency', { length: 3 }).notNull().default('INR'),
  status: varchar('status', { length: 20 }).notNull().default('PENDING'),
  paymentMethod: varchar('payment_method', { length: 30 }).notNull(),
  gateway: varchar('gateway', { length: 30 }).notNull().default('MANUAL'),
  gatewayOrderId: varchar('gateway_order_id', { length: 100 }),
  gatewayPaymentId: varchar('gateway_payment_id', { length: 100 }),
  gatewayRef: varchar('gateway_ref', { length: 255 }),
  failureCode: varchar('failure_code', { length: 50 }),
  failureMessage: text('failure_message'),
  initiatedAt: timestamp('initiated_at', { withTimezone: true }).notNull().defaultNow(),
  paidAt: timestamp('paid_at', { withTimezone: true }),
  notes: text('notes'),
  createdBy: uuid('created_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const invoicePayments = rms.table(
  'invoice_payments',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    invoiceId: uuid('invoice_id')
      .notNull()
      .references(() => invoices.id, { onDelete: 'cascade' }),
    paymentId: uuid('payment_id')
      .notNull()
      .references(() => payments.id, { onDelete: 'cascade' }),
    amountApplied: numeric('amount_applied', { precision: 12, scale: 2 }).notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [unique().on(table.invoiceId, table.paymentId)]
);

export const creditNotes = rms.table('credit_notes', {
  id: uuid('id').primaryKey().defaultRandom(),
  invoiceId: uuid('invoice_id')
    .notNull()
    .references(() => invoices.id, { onDelete: 'restrict' }),
  creditNoteNumber: varchar('credit_note_number', { length: 50 }).notNull().unique(),
  status: varchar('status', { length: 20 }).notNull().default('DRAFT'),
  reason: text('reason'),
  subtotalAmount: numeric('subtotal_amount', { precision: 12, scale: 2 }).notNull().default('0'),
  taxAmount: numeric('tax_amount', { precision: 12, scale: 2 }).notNull().default('0'),
  totalAmount: numeric('total_amount', { precision: 12, scale: 2 }).notNull().default('0'),
  settlementMethod: varchar('settlement_method', { length: 30 }).notNull(),
  appliedToInvoiceId: uuid('applied_to_invoice_id').references(() => invoices.id, {
    onDelete: 'set null',
  }),
  settledAt: timestamp('settled_at', { withTimezone: true }),
  pdfUrl: text('pdf_url'),
  issuedAt: timestamp('issued_at', { withTimezone: true }),
  createdBy: uuid('created_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const creditNoteLineItems = rms.table('credit_note_line_items', {
  id: uuid('id').primaryKey().defaultRandom(),
  creditNoteId: uuid('credit_note_id')
    .notNull()
    .references(() => creditNotes.id, { onDelete: 'cascade' }),
  invoiceLineItemId: uuid('invoice_line_item_id').references(() => invoiceLineItems.id, {
    onDelete: 'set null',
  }),
  description: varchar('description', { length: 255 }).notNull(),
  amount: numeric('amount', { precision: 12, scale: 2 }).notNull().default('0'),
  taxAmount: numeric('tax_amount', { precision: 12, scale: 2 }).notNull().default('0'),
  sortOrder: integer('sort_order').notNull().default(0),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const refunds = rms.table('refunds', {
  id: uuid('id').primaryKey().defaultRandom(),
  paymentId: uuid('payment_id')
    .notNull()
    .references(() => payments.id, { onDelete: 'restrict' }),
  creditNoteId: uuid('credit_note_id').references(() => creditNotes.id, { onDelete: 'set null' }),
  amount: numeric('amount', { precision: 12, scale: 2 }).notNull(),
  status: varchar('status', { length: 20 }).notNull().default('PENDING'),
  gatewayRefundId: varchar('gateway_refund_id', { length: 100 }),
  reason: text('reason'),
  refundedAt: timestamp('refunded_at', { withTimezone: true }),
  createdBy: uuid('created_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

/** Marketplace B2C — Uber / Stripe Connect style commission + settlement */

export const platformCommissionConfig = pgTable('platform_commission_config', {
  id: uuid('id').primaryKey().defaultRandom(),
  defaultPct: numeric('default_pct', { precision: 5, scale: 2 }).notNull().default('5.00'),
  minPct: numeric('min_pct', { precision: 5, scale: 2 }).notNull().default('1.00'),
  maxPct: numeric('max_pct', { precision: 5, scale: 2 }).notNull().default('25.00'),
  applyOnRefunds: boolean('apply_on_refunds').notNull().default(true),
  monthlyInvoiceDay: integer('monthly_invoice_day').notNull().default(1),
  invoiceDueDays: integer('invoice_due_days').notNull().default(7),
  outstandingInvoiceThreshold: numeric('outstanding_invoice_threshold', {
    precision: 12,
    scale: 2,
  })
    .notNull()
    .default('5000.00'),
  autoRecoverFromPayouts: boolean('auto_recover_from_payouts').notNull().default(true),
  currency: varchar('currency', { length: 3 }).notNull().default('INR'),
  notes: text('notes'),
  updatedBy: uuid('updated_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const commissionRateHistory = rms.table('commission_rate_history', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  previousPct: numeric('previous_pct', { precision: 5, scale: 2 }),
  newPct: numeric('new_pct', { precision: 5, scale: 2 }).notNull(),
  effectiveFrom: timestamp('effective_from', { withTimezone: true }).notNull().defaultNow(),
  reason: text('reason'),
  changedBy: uuid('changed_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const orgMerchantBalances = rms.table('org_merchant_balances', {
  organizationId: uuid('organization_id')
    .primaryKey()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  outstandingAmount: numeric('outstanding_amount', { precision: 12, scale: 2 })
    .notNull()
    .default('0'),
  pendingPayoutAmount: numeric('pending_payout_amount', { precision: 12, scale: 2 })
    .notNull()
    .default('0'),
  currency: varchar('currency', { length: 3 }).notNull().default('INR'),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const salonPayouts = rms.table('salon_payouts', {
  id: uuid('id').primaryKey().defaultRandom(),
  payoutNumber: varchar('payout_number', { length: 50 }).notNull().unique(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  status: varchar('status', { length: 20 }).notNull().default('PENDING'),
  currency: varchar('currency', { length: 3 }).notNull().default('INR'),
  grossCollected: numeric('gross_collected', { precision: 12, scale: 2 }).notNull().default('0'),
  commissionDeducted: numeric('commission_deducted', { precision: 12, scale: 2 })
    .notNull()
    .default('0'),
  gatewayFeesDeducted: numeric('gateway_fees_deducted', { precision: 12, scale: 2 })
    .notNull()
    .default('0'),
  outstandingRecovered: numeric('outstanding_recovered', { precision: 12, scale: 2 })
    .notNull()
    .default('0'),
  netPayoutAmount: numeric('net_payout_amount', { precision: 12, scale: 2 }).notNull().default('0'),
  gateway: varchar('gateway', { length: 30 }),
  gatewayPayoutId: varchar('gateway_payout_id', { length: 100 }),
  gatewayRef: varchar('gateway_ref', { length: 255 }),
  periodStart: timestamp('period_start', { withTimezone: true }),
  periodEnd: timestamp('period_end', { withTimezone: true }),
  paidAt: timestamp('paid_at', { withTimezone: true }),
  failureMessage: text('failure_message'),
  notes: text('notes'),
  createdBy: uuid('created_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const endUserTransactions = rms.table('end_user_transactions', {
  id: uuid('id').primaryKey().defaultRandom(),
  transactionRef: varchar('transaction_ref', { length: 50 }).notNull().unique(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  branchId: uuid('branch_id')
    .notNull()
    .references(() => branches.id),
  bookingRef: varchar('booking_ref', { length: 50 }),
  endUserRef: varchar('end_user_ref', { length: 50 }),
  paymentChannel: varchar('payment_channel', { length: 20 }).notNull(),
  collectionModel: varchar('collection_model', { length: 20 }).notNull(),
  grossAmount: numeric('gross_amount', { precision: 12, scale: 2 }).notNull(),
  commissionPct: numeric('commission_pct', { precision: 5, scale: 2 }).notNull(),
  commissionAmount: numeric('commission_amount', { precision: 12, scale: 2 }).notNull(),
  gatewayFeeAmount: numeric('gateway_fee_amount', { precision: 12, scale: 2 }).notNull().default('0'),
  netToSalon: numeric('net_to_salon', { precision: 12, scale: 2 }).notNull(),
  currency: varchar('currency', { length: 3 }).notNull().default('INR'),
  paymentMethod: varchar('payment_method', { length: 30 }).notNull(),
  status: varchar('status', { length: 20 }).notNull().default('PENDING'),
  gateway: varchar('gateway', { length: 30 }),
  gatewayOrderId: varchar('gateway_order_id', { length: 100 }),
  gatewayPaymentId: varchar('gateway_payment_id', { length: 100 }),
  gatewayRef: varchar('gateway_ref', { length: 255 }),
  failureCode: varchar('failure_code', { length: 50 }),
  failureMessage: text('failure_message'),
  serviceDetails: jsonb('service_details'),
  outstandingRecovered: numeric('outstanding_recovered', { precision: 12, scale: 2 })
    .notNull()
    .default('0'),
  salonPayoutId: uuid('salon_payout_id').references(() => salonPayouts.id, { onDelete: 'set null' }),
  occurredAt: timestamp('occurred_at', { withTimezone: true }).notNull().defaultNow(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const salonPayoutItems = rms.table('salon_payout_items', {
  id: uuid('id').primaryKey().defaultRandom(),
  payoutId: uuid('payout_id')
    .notNull()
    .references(() => salonPayouts.id, { onDelete: 'cascade' }),
  endUserTransactionId: uuid('end_user_transaction_id').references(() => endUserTransactions.id, {
    onDelete: 'set null',
  }),
  itemType: varchar('item_type', { length: 30 }).notNull(),
  amount: numeric('amount', { precision: 12, scale: 2 }).notNull(),
  description: varchar('description', { length: 255 }),
  sortOrder: integer('sort_order').notNull().default(0),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const merchantLedgerEntries = rms.table('merchant_ledger_entries', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  balanceBucket: varchar('balance_bucket', { length: 20 }).notNull(),
  direction: varchar('direction', { length: 10 }).notNull(),
  entryType: varchar('entry_type', { length: 30 }).notNull(),
  amount: numeric('amount', { precision: 12, scale: 2 }).notNull(),
  balanceAfter: numeric('balance_after', { precision: 12, scale: 2 }).notNull(),
  currency: varchar('currency', { length: 3 }).notNull().default('INR'),
  endUserTransactionId: uuid('end_user_transaction_id').references(() => endUserTransactions.id, {
    onDelete: 'set null',
  }),
  salonPayoutId: uuid('salon_payout_id').references(() => salonPayouts.id, { onDelete: 'set null' }),
  invoiceId: uuid('invoice_id').references(() => invoices.id, { onDelete: 'set null' }),
  paymentId: uuid('payment_id').references(() => payments.id, { onDelete: 'set null' }),
  description: text('description'),
  occurredAt: timestamp('occurred_at', { withTimezone: true }).notNull().defaultNow(),
  createdBy: uuid('created_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

/** §4.9 CMS & Banner Management */
export const cmsMedia = cms.table('cms_media', {
  id: uuid('id').primaryKey().defaultRandom(),
  fileName: varchar('file_name', { length: 255 }).notNull(),
  storageUrl: text('storage_url').notNull(),
  mimeType: varchar('mime_type', { length: 100 }).notNull(),
  mediaType: varchar('media_type', { length: 20 }).notNull().default('IMAGE'),
  fileSizeBytes: bigint('file_size_bytes', { mode: 'number' }),
  altText: varchar('alt_text', { length: 255 }),
  widthPx: integer('width_px'),
  heightPx: integer('height_px'),
  durationSec: integer('duration_sec'),
  uploadedBy: uuid('uploaded_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const cmsPages = cms.table('cms_pages', {
  id: uuid('id').primaryKey().defaultRandom(),
  slug: varchar('slug', { length: 100 }).notNull().unique(),
  title: varchar('title', { length: 255 }).notNull(),
  pageType: varchar('page_type', { length: 30 }).notNull().default('CUSTOM'),
  body: jsonb('body').notNull().default({}),
  seoTitle: varchar('seo_title', { length: 255 }),
  seoDescription: text('seo_description'),
  ogImageMediaId: uuid('og_image_media_id').references(() => cmsMedia.id, { onDelete: 'set null' }),
  status: varchar('status', { length: 20 }).notNull().default('DRAFT'),
  publishAt: timestamp('publish_at', { withTimezone: true }),
  publishedAt: timestamp('published_at', { withTimezone: true }),
  previewToken: varchar('preview_token', { length: 64 }),
  sortOrder: integer('sort_order').notNull().default(0),
  createdBy: uuid('created_by').references(() => superAdminUsers.id),
  updatedBy: uuid('updated_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const cmsPosts = cms.table('cms_posts', {
  id: uuid('id').primaryKey().defaultRandom(),
  slug: varchar('slug', { length: 150 }).notNull().unique(),
  title: varchar('title', { length: 255 }).notNull(),
  excerpt: text('excerpt'),
  body: jsonb('body').notNull().default({}),
  coverMediaId: uuid('cover_media_id').references(() => cmsMedia.id, { onDelete: 'set null' }),
  seoTitle: varchar('seo_title', { length: 255 }),
  seoDescription: text('seo_description'),
  tags: text('tags').array().notNull().default([]),
  status: varchar('status', { length: 20 }).notNull().default('DRAFT'),
  publishAt: timestamp('publish_at', { withTimezone: true }),
  publishedAt: timestamp('published_at', { withTimezone: true }),
  previewToken: varchar('preview_token', { length: 64 }),
  authorId: uuid('author_id').references(() => superAdminUsers.id),
  createdBy: uuid('created_by').references(() => superAdminUsers.id),
  updatedBy: uuid('updated_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const portalBanners = cms.table('portal_banners', {
  id: uuid('id').primaryKey().defaultRandom(),
  title: varchar('title', { length: 255 }).notNull(),
  bodyText: text('body_text'),
  imageMediaId: uuid('image_media_id').references(() => cmsMedia.id, { onDelete: 'set null' }),
  imageUrl: text('image_url'),
  ctaText: varchar('cta_text', { length: 100 }),
  ctaLink: text('cta_link'),
  targetingRules: jsonb('targeting_rules').notNull().default({}),
  displayPriority: integer('display_priority').notNull().default(100),
  activeFrom: timestamp('active_from', { withTimezone: true }).notNull().defaultNow(),
  activeUntil: timestamp('active_until', { withTimezone: true }),
  isActive: boolean('is_active').notNull().default(true),
  abVariant: varchar('ab_variant', { length: 20 }),
  createdBy: uuid('created_by').references(() => superAdminUsers.id),
  updatedBy: uuid('updated_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

/** §4.12 Reviews & Ratings Moderation (Super Admin) — rule-based, no ML */
export const reviewModerationSettings = review.table('review_moderation_settings', {
  id: uuid('id').primaryKey().defaultRandom(),
  maxImageSizeMb: numeric('max_image_size_mb', { precision: 6, scale: 2 }).notNull().default('5.00'),
  maxImagesPerReview: integer('max_images_per_review').notNull().default(3),
  allowedMimeTypes: text('allowed_mime_types')
    .array()
    .notNull()
    .default(['image/jpeg', 'image/png', 'image/webp']),
  editWindowDays: integer('edit_window_days').notNull().default(7),
  autoPublishHighRating: boolean('auto_publish_high_rating').notNull().default(true),
  autoPublishMinRating: integer('auto_publish_min_rating').notNull().default(4),
  autoPublishRequiresNoText: boolean('auto_publish_requires_no_text').notNull().default(true),
  autoPublishRequiresNoImage: boolean('auto_publish_requires_no_image').notNull().default(true),
  queueIfHasImage: boolean('queue_if_has_image').notNull().default(true),
  queueIfHasUrlOrPhone: boolean('queue_if_has_url_or_phone').notNull().default(true),
  maxReviewsPerUserPerDay: integer('max_reviews_per_user_per_day').notNull().default(10),
  isActive: boolean('is_active').notNull().default(true),
  updatedBy: uuid('updated_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const reviewAbuseRules = review.table('review_abuse_rules', {
  id: uuid('id').primaryKey().defaultRandom(),
  code: varchar('code', { length: 50 }).notNull().unique(),
  label: varchar('label', { length: 255 }).notNull(),
  description: text('description'),
  condition: jsonb('condition').notNull().default({}),
  action: varchar('action', { length: 20 }).notNull().default('QUEUE'),
  isActive: boolean('is_active').notNull().default(true),
  sortOrder: integer('sort_order').notNull().default(0),
  createdBy: uuid('created_by').references(() => superAdminUsers.id),
  updatedBy: uuid('updated_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const reviews = review.table('reviews', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  branchId: uuid('branch_id')
    .notNull()
    .references(() => branches.id, { onDelete: 'cascade' }),
  bookingRef: varchar('booking_ref', { length: 50 }).notNull().unique(),
  endUserRef: varchar('end_user_ref', { length: 50 }).notNull(),
  specialistRef: varchar('specialist_ref', { length: 50 }),
  overallRating: integer('overall_rating').notNull(),
  ratingService: integer('rating_service'),
  ratingSpecialist: integer('rating_specialist'),
  ratingCleanliness: integer('rating_cleanliness'),
  ratingValue: integer('rating_value'),
  body: text('body'),
  status: varchar('status', { length: 20 }).notNull().default('PENDING'),
  matchedRuleCodes: text('matched_rule_codes').array().notNull().default([]),
  submittedAt: timestamp('submitted_at', { withTimezone: true }).notNull().defaultNow(),
  editedAt: timestamp('edited_at', { withTimezone: true }),
  editDeadlineAt: timestamp('edit_deadline_at', { withTimezone: true }),
  publishedAt: timestamp('published_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const reviewImages = review.table('review_images', {
  id: uuid('id').primaryKey().defaultRandom(),
  reviewId: uuid('review_id')
    .notNull()
    .references(() => reviews.id, { onDelete: 'cascade' }),
  storageUrl: text('storage_url').notNull(),
  fileName: varchar('file_name', { length: 255 }),
  mimeType: varchar('mime_type', { length: 100 }).notNull(),
  fileSizeBytes: bigint('file_size_bytes', { mode: 'number' }).notNull(),
  status: varchar('status', { length: 20 }).notNull().default('ACTIVE'),
  sortOrder: integer('sort_order').notNull().default(0),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const reviewReplies = review.table('review_replies', {
  id: uuid('id').primaryKey().defaultRandom(),
  reviewId: uuid('review_id')
    .notNull()
    .unique()
    .references(() => reviews.id, { onDelete: 'cascade' }),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  body: text('body').notNull(),
  status: varchar('status', { length: 20 }).notNull().default('PUBLISHED'),
  repliedByRef: varchar('replied_by_ref', { length: 100 }),
  repliedAt: timestamp('replied_at', { withTimezone: true }).notNull().defaultNow(),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const reviewReports = review.table('review_reports', {
  id: uuid('id').primaryKey().defaultRandom(),
  reviewId: uuid('review_id')
    .notNull()
    .references(() => reviews.id, { onDelete: 'cascade' }),
  replyId: uuid('reply_id').references(() => reviewReplies.id, { onDelete: 'set null' }),
  reporterType: varchar('reporter_type', { length: 20 }).notNull(),
  reporterRef: varchar('reporter_ref', { length: 100 }),
  reasonCode: varchar('reason_code', { length: 40 }).notNull(),
  notes: text('notes'),
  status: varchar('status', { length: 20 }).notNull().default('OPEN'),
  resolvedBy: uuid('resolved_by').references(() => superAdminUsers.id),
  resolvedAt: timestamp('resolved_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const reviewModerationActions = review.table('review_moderation_actions', {
  id: uuid('id').primaryKey().defaultRandom(),
  reviewId: uuid('review_id')
    .notNull()
    .references(() => reviews.id, { onDelete: 'cascade' }),
  replyId: uuid('reply_id').references(() => reviewReplies.id, { onDelete: 'set null' }),
  imageId: uuid('image_id').references(() => reviewImages.id, { onDelete: 'set null' }),
  action: varchar('action', { length: 30 }).notNull(),
  reason: text('reason'),
  metadata: jsonb('metadata'),
  performedBy: uuid('performed_by').references(() => superAdminUsers.id),
  performedAt: timestamp('performed_at', { withTimezone: true }).notNull().defaultNow(),
});

/** §4.11 Support & Ticketing — SaaS CTS + SLA (salon + customer) */
export const supportTicketCategories = tickets.table('support_ticket_categories', {
  id: uuid('id').primaryKey().defaultRandom(),
  code: varchar('code', { length: 50 }).notNull().unique(),
  label: varchar('label', { length: 255 }).notNull(),
  description: text('description'),
  audience: varchar('audience', { length: 20 }).notNull().default('BOTH'),
  isActive: boolean('is_active').notNull().default(true),
  sortOrder: integer('sort_order').notNull().default(0),
  createdBy: uuid('created_by').references(() => superAdminUsers.id),
  updatedBy: uuid('updated_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const supportTicketTypes = tickets.table('support_ticket_types', {
  id: uuid('id').primaryKey().defaultRandom(),
  categoryId: uuid('category_id')
    .notNull()
    .references(() => supportTicketCategories.id, { onDelete: 'cascade' }),
  code: varchar('code', { length: 50 }).notNull(),
  label: varchar('label', { length: 255 }).notNull(),
  description: text('description'),
  isActive: boolean('is_active').notNull().default(true),
  sortOrder: integer('sort_order').notNull().default(0),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const supportTicketSubtypes = tickets.table('support_ticket_subtypes', {
  id: uuid('id').primaryKey().defaultRandom(),
  typeId: uuid('type_id')
    .notNull()
    .references(() => supportTicketTypes.id, { onDelete: 'cascade' }),
  code: varchar('code', { length: 50 }).notNull(),
  label: varchar('label', { length: 255 }).notNull(),
  description: text('description'),
  defaultPriority: varchar('default_priority', { length: 20 }).notNull().default('MEDIUM'),
  isActive: boolean('is_active').notNull().default(true),
  sortOrder: integer('sort_order').notNull().default(0),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const supportSlaPolicies = tickets.table('support_sla_policies', {
  id: uuid('id').primaryKey().defaultRandom(),
  priority: varchar('priority', { length: 20 }).notNull().unique(),
  firstResponseMinutes: integer('first_response_minutes').notNull(),
  resolveMinutes: integer('resolve_minutes').notNull(),
  businessHoursOnly: boolean('business_hours_only').notNull().default(false),
  isActive: boolean('is_active').notNull().default(true),
  updatedBy: uuid('updated_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const supportTickets = tickets.table('support_tickets', {
  id: uuid('id').primaryKey().defaultRandom(),
  ticketNumber: varchar('ticket_number', { length: 30 }).notNull().unique(),
  source: varchar('source', { length: 20 }).notNull(),
  organizationId: uuid('organization_id').references(() => organizations.id, {
    onDelete: 'set null',
  }),
  branchId: uuid('branch_id').references(() => branches.id, { onDelete: 'set null' }),
  endUserRef: varchar('end_user_ref', { length: 50 }),
  bookingRef: varchar('booking_ref', { length: 50 }),
  requesterName: varchar('requester_name', { length: 255 }),
  requesterEmail: varchar('requester_email', { length: 255 }),
  requesterPhone: varchar('requester_phone', { length: 20 }),
  categoryId: uuid('category_id')
    .notNull()
    .references(() => supportTicketCategories.id),
  typeId: uuid('type_id')
    .notNull()
    .references(() => supportTicketTypes.id),
  subtypeId: uuid('subtype_id').references(() => supportTicketSubtypes.id),
  subject: varchar('subject', { length: 255 }).notNull(),
  description: text('description').notNull(),
  priority: varchar('priority', { length: 20 }).notNull().default('MEDIUM'),
  status: varchar('status', { length: 30 }).notNull().default('CREATED'),
  assignedTo: uuid('assigned_to').references(() => superAdminUsers.id),
  slaPolicyId: uuid('sla_policy_id').references(() => supportSlaPolicies.id),
  firstResponseDueAt: timestamp('first_response_due_at', { withTimezone: true }),
  resolveDueAt: timestamp('resolve_due_at', { withTimezone: true }),
  firstRespondedAt: timestamp('first_responded_at', { withTimezone: true }),
  resolvedAt: timestamp('resolved_at', { withTimezone: true }),
  closedAt: timestamp('closed_at', { withTimezone: true }),
  resolutionNotes: text('resolution_notes'),
  csatScore: integer('csat_score'),
  csatComment: text('csat_comment'),
  createdBySuperAdminId: uuid('created_by_super_admin_id').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const supportTicketMessages = tickets.table('support_ticket_messages', {
  id: uuid('id').primaryKey().defaultRandom(),
  ticketId: uuid('ticket_id')
    .notNull()
    .references(() => supportTickets.id, { onDelete: 'cascade' }),
  authorType: varchar('author_type', { length: 20 }).notNull(),
  authorRef: varchar('author_ref', { length: 100 }),
  authorSuperAdminId: uuid('author_super_admin_id').references(() => superAdminUsers.id),
  body: text('body').notNull(),
  isFirstResponse: boolean('is_first_response').notNull().default(false),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const supportTicketInternalNotes = tickets.table('support_ticket_internal_notes', {
  id: uuid('id').primaryKey().defaultRandom(),
  ticketId: uuid('ticket_id')
    .notNull()
    .references(() => supportTickets.id, { onDelete: 'cascade' }),
  body: text('body').notNull(),
  createdBy: uuid('created_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const supportTicketAttachments = tickets.table('support_ticket_attachments', {
  id: uuid('id').primaryKey().defaultRandom(),
  ticketId: uuid('ticket_id')
    .notNull()
    .references(() => supportTickets.id, { onDelete: 'cascade' }),
  messageId: uuid('message_id').references(() => supportTicketMessages.id, {
    onDelete: 'set null',
  }),
  fileName: varchar('file_name', { length: 255 }).notNull(),
  storageUrl: text('storage_url').notNull(),
  mimeType: varchar('mime_type', { length: 100 }),
  fileSizeBytes: bigint('file_size_bytes', { mode: 'number' }),
  uploadedByType: varchar('uploaded_by_type', { length: 20 }).notNull(),
  uploadedByRef: varchar('uploaded_by_ref', { length: 100 }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const supportTicketEvents = tickets.table('support_ticket_events', {
  id: uuid('id').primaryKey().defaultRandom(),
  ticketId: uuid('ticket_id')
    .notNull()
    .references(() => supportTickets.id, { onDelete: 'cascade' }),
  eventType: varchar('event_type', { length: 30 }).notNull(),
  fromValue: varchar('from_value', { length: 100 }),
  toValue: varchar('to_value', { length: 100 }),
  note: text('note'),
  performedBy: uuid('performed_by').references(() => superAdminUsers.id),
  performedAt: timestamp('performed_at', { withTimezone: true }).notNull().defaultNow(),
});

/** Super Admin platform service catalog — Category → Subcategory */
export const serviceCategories = services.table('service_categories', {
  id: uuid('id').primaryKey().defaultRandom(),
  code: varchar('code', { length: 50 }).notNull().unique(),
  name: varchar('name', { length: 255 }).notNull(),
  description: text('description'),
  iconUrl: text('icon_url'),
  isActive: boolean('is_active').notNull().default(true),
  sortOrder: integer('sort_order').notNull().default(0),
  isSingleLevel: boolean('is_single_level').notNull().default(false),
  createdBy: uuid('created_by').references(() => superAdminUsers.id),
  updatedBy: uuid('updated_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const serviceSubcategories = services.table('service_subcategories', {
  id: uuid('id').primaryKey().defaultRandom(),
  categoryId: uuid('category_id')
    .notNull()
    .references(() => serviceCategories.id, { onDelete: 'cascade' }),
  code: varchar('code', { length: 50 }).notNull(),
  name: varchar('name', { length: 255 }).notNull(),
  description: text('description'),
  iconUrl: text('icon_url'),
  isActive: boolean('is_active').notNull().default(true),
  sortOrder: integer('sort_order').notNull().default(0),
  mirrorsCategory: boolean('mirrors_category').notNull().default(false),
  createdBy: uuid('created_by').references(() => superAdminUsers.id),
  updatedBy: uuid('updated_by').references(() => superAdminUsers.id),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

/** §4.7–4.9 Employee management — staff, offs, leave, holidays, attendance */
export const employees = employee.table('employees', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  branchId: uuid('branch_id')
    .notNull()
    .references(() => branches.id, { onDelete: 'restrict' }),
  employeeNumber: varchar('employee_number', { length: 30 }).notNull(),
  fullName: varchar('full_name', { length: 255 }).notNull(),
  email: varchar('email', { length: 255 }),
  phone: varchar('phone', { length: 20 }),
  designation: varchar('designation', { length: 100 }),
  photoUrl: text('photo_url'),
  dateOfJoining: date('date_of_joining').notNull(),
  dateOfExit: date('date_of_exit'),
  status: varchar('status', { length: 20 }).notNull().default('ACTIVE'),
  notes: text('notes'),
  deactivatedAt: timestamp('deactivated_at', { withTimezone: true }),
  deactivatedReason: text('deactivated_reason'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const branchHolidays = employee.table('branch_holidays', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  branchId: uuid('branch_id')
    .notNull()
    .references(() => branches.id, { onDelete: 'cascade' }),
  holidayDate: date('holiday_date').notNull(),
  name: varchar('name', { length: 255 }).notNull(),
  isRecurringAnnual: boolean('is_recurring_annual').notNull().default(false),
  notes: text('notes'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const leaveTypes = employee.table('leave_types', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  code: varchar('code', { length: 30 }).notNull(),
  name: varchar('name', { length: 100 }).notNull(),
  description: text('description'),
  isPaid: boolean('is_paid').notNull().default(true),
  isActive: boolean('is_active').notNull().default(true),
  sortOrder: integer('sort_order').notNull().default(0),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

/** Per branch + leave type: accrual, CF allowed, CF % / max, year-end month */
export const branchLeavePolicies = employee.table('branch_leave_policies', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  branchId: uuid('branch_id')
    .notNull()
    .references(() => branches.id, { onDelete: 'cascade' }),
  leaveTypeId: uuid('leave_type_id')
    .notNull()
    .references(() => leaveTypes.id, { onDelete: 'cascade' }),
  daysPerMonth: numeric('days_per_month', { precision: 6, scale: 2 }).notNull().default('0'),
  carryForwardAllowed: boolean('carry_forward_allowed').notNull().default(false),
  carryForwardPct: numeric('carry_forward_pct', { precision: 5, scale: 2 }).notNull().default('0'),
  carryForwardMaxDays: numeric('carry_forward_max_days', { precision: 6, scale: 2 }),
  leaveYearEndMonth: integer('leave_year_end_month').notNull().default(3),
  leaveYearEndDay: integer('leave_year_end_day').notNull().default(31),
  isActive: boolean('is_active').notNull().default(true),
  notes: text('notes'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const leaveBalances = employee.table('leave_balances', {
  id: uuid('id').primaryKey().defaultRandom(),
  employeeId: uuid('employee_id')
    .notNull()
    .references(() => employees.id, { onDelete: 'cascade' }),
  leaveTypeId: uuid('leave_type_id')
    .notNull()
    .references(() => leaveTypes.id, { onDelete: 'cascade' }),
  year: integer('year').notNull(),
  entitledDays: numeric('entitled_days', { precision: 6, scale: 2 }).notNull().default('0'),
  usedDays: numeric('used_days', { precision: 6, scale: 2 }).notNull().default('0'),
  carriedForward: numeric('carried_forward', { precision: 6, scale: 2 }).notNull().default('0'),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const leaveRequests = employee.table('leave_requests', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  branchId: uuid('branch_id')
    .notNull()
    .references(() => branches.id, { onDelete: 'restrict' }),
  employeeId: uuid('employee_id')
    .notNull()
    .references(() => employees.id, { onDelete: 'cascade' }),
  leaveTypeId: uuid('leave_type_id')
    .notNull()
    .references(() => leaveTypes.id),
  startDate: date('start_date').notNull(),
  endDate: date('end_date').notNull(),
  totalDays: numeric('total_days', { precision: 6, scale: 2 }).notNull(),
  status: varchar('status', { length: 20 }).notNull().default('PENDING'),
  reason: text('reason'),
  adminNote: text('admin_note'),
  decidedByRef: varchar('decided_by_ref', { length: 100 }),
  decidedAt: timestamp('decided_at', { withTimezone: true }),
  cancelledAt: timestamp('cancelled_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const attendanceRecords = employee.table('attendance_records', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  branchId: uuid('branch_id')
    .notNull()
    .references(() => branches.id, { onDelete: 'restrict' }),
  employeeId: uuid('employee_id')
    .notNull()
    .references(() => employees.id, { onDelete: 'cascade' }),
  attendanceDate: date('attendance_date').notNull(),
  checkInAt: timestamp('check_in_at', { withTimezone: true }),
  checkOutAt: timestamp('check_out_at', { withTimezone: true }),
  status: varchar('status', { length: 20 }).notNull().default('PRESENT'),
  source: varchar('source', { length: 20 }).notNull().default('MANUAL'),
  notes: text('notes'),
  markedByRef: varchar('marked_by_ref', { length: 100 }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const attendanceAuditActions = employee.table('attendance_audit_actions', {
  id: uuid('id').primaryKey().defaultRandom(),
  attendanceId: uuid('attendance_id')
    .notNull()
    .references(() => attendanceRecords.id, { onDelete: 'cascade' }),
  action: varchar('action', { length: 30 }).notNull(),
  beforeData: jsonb('before_data'),
  afterData: jsonb('after_data'),
  reason: text('reason'),
  performedByRef: varchar('performed_by_ref', { length: 100 }),
  performedAt: timestamp('performed_at', { withTimezone: true }).notNull().defaultNow(),
});

export const employeeActions = employee.table('employee_actions', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  employeeId: uuid('employee_id')
    .notNull()
    .references(() => employees.id, { onDelete: 'cascade' }),
  action: varchar('action', { length: 30 }).notNull(),
  reason: text('reason'),
  metadata: jsonb('metadata'),
  performedByRef: varchar('performed_by_ref', { length: 100 }),
  performedAt: timestamp('performed_at', { withTimezone: true }).notNull().defaultNow(),
});

/** Branch-offered services — Admin selects category/subcategory from platform catalog */
export const branchServices = services.table('branch_services', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  branchId: uuid('branch_id')
    .notNull()
    .references(() => branches.id, { onDelete: 'cascade' }),
  categoryId: uuid('category_id')
    .notNull()
    .references(() => serviceCategories.id, { onDelete: 'restrict' }),
  subcategoryId: uuid('subcategory_id')
    .notNull()
    .references(() => serviceSubcategories.id, { onDelete: 'restrict' }),
  name: varchar('name', { length: 255 }).notNull(),
  description: text('description'),
  price: numeric('price', { precision: 12, scale: 2 }).notNull(),
  currency: varchar('currency', { length: 3 }).notNull().default('INR'),
  durationMinutes: integer('duration_minutes').notNull(),
  photoUrl: text('photo_url'),
  discountAmount: numeric('discount_amount', { precision: 12, scale: 2 }),
  discountPercent: numeric('discount_percent', { precision: 5, scale: 2 }),
  discountDescription: text('discount_description'),
  offlinePaymentAllowed: boolean('offline_payment_allowed').notNull().default(true),
  status: varchar('status', { length: 20 }).notNull().default('ACTIVE'),
  sortOrder: integer('sort_order').notNull().default(0),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const branchServiceSpecialists = services.table(
  'branch_service_specialists',
  {
    branchServiceId: uuid('branch_service_id')
      .notNull()
      .references(() => branchServices.id, { onDelete: 'cascade' }),
    employeeId: uuid('employee_id')
      .notNull()
      .references(() => employees.id, { onDelete: 'cascade' }),
    isPrimary: boolean('is_primary').notNull().default(false),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [primaryKey({ columns: [table.branchServiceId, table.employeeId] })]
);

/** §4.11–4.12 Appointments — bookings only (slots from service duration) */
export const appointmentHolds = appointments.table('appointment_holds', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  branchId: uuid('branch_id')
    .notNull()
    .references(() => branches.id, { onDelete: 'cascade' }),
  branchServiceId: uuid('branch_service_id')
    .notNull()
    .references(() => branchServices.id, { onDelete: 'cascade' }),
  specialistId: uuid('specialist_id').references(() => employees.id, { onDelete: 'set null' }),
  endUserRef: varchar('end_user_ref', { length: 50 }),
  startsAt: timestamp('starts_at', { withTimezone: true }).notNull(),
  endsAt: timestamp('ends_at', { withTimezone: true }).notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  status: varchar('status', { length: 20 }).notNull().default('ACTIVE'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export const appointmentsTable = appointments.table('appointments', {
  id: uuid('id').primaryKey().defaultRandom(),
  bookingNumber: varchar('booking_number', { length: 40 }).notNull().unique(),
  organizationId: uuid('organization_id')
    .notNull()
    .references(() => organizations.id, { onDelete: 'cascade' }),
  branchId: uuid('branch_id')
    .notNull()
    .references(() => branches.id, { onDelete: 'restrict' }),
  branchServiceId: uuid('branch_service_id')
    .notNull()
    .references(() => branchServices.id, { onDelete: 'restrict' }),
  specialistId: uuid('specialist_id').references(() => employees.id, { onDelete: 'set null' }),
  endUserRef: varchar('end_user_ref', { length: 50 }).notNull(),
  endUserName: varchar('end_user_name', { length: 255 }),
  endUserPhone: varchar('end_user_phone', { length: 20 }),
  endUserEmail: varchar('end_user_email', { length: 255 }),
  serviceName: varchar('service_name', { length: 255 }).notNull(),
  serviceDurationMin: integer('service_duration_min').notNull(),
  startsAt: timestamp('starts_at', { withTimezone: true }).notNull(),
  endsAt: timestamp('ends_at', { withTimezone: true }).notNull(),
  status: varchar('status', { length: 30 }).notNull().default('BOOKED'),
  source: varchar('source', { length: 30 }).notNull().default('CONSUMER_APP'),
  customerNote: text('customer_note'),
  currency: varchar('currency', { length: 3 }).notNull().default('INR'),
  listPrice: numeric('list_price', { precision: 12, scale: 2 }).notNull().default('0'),
  discountAmount: numeric('discount_amount', { precision: 12, scale: 2 }).notNull().default('0'),
  grossAmount: numeric('gross_amount', { precision: 12, scale: 2 }).notNull().default('0'),
  paymentMethod: varchar('payment_method', { length: 20 }).notNull().default('ONLINE'),
  paymentStatus: varchar('payment_status', { length: 20 }).notNull().default('PENDING'),
  eutTransactionId: uuid('eut_transaction_id').references(() => endUserTransactions.id, {
    onDelete: 'set null',
  }),
  holdId: uuid('hold_id').references(() => appointmentHolds.id, { onDelete: 'set null' }),
  cancelReason: text('cancel_reason'),
  cancelledAt: timestamp('cancelled_at', { withTimezone: true }),
  confirmedAt: timestamp('confirmed_at', { withTimezone: true }),
  completedAt: timestamp('completed_at', { withTimezone: true }),
  noShowAt: timestamp('no_show_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const appointmentStatusEvents = appointments.table('appointment_status_events', {
  id: uuid('id').primaryKey().defaultRandom(),
  appointmentId: uuid('appointment_id')
    .notNull()
    .references(() => appointmentsTable.id, { onDelete: 'cascade' }),
  fromStatus: varchar('from_status', { length: 30 }),
  toStatus: varchar('to_status', { length: 30 }).notNull(),
  reason: text('reason'),
  performedByType: varchar('performed_by_type', { length: 20 }).notNull().default('SYSTEM'),
  performedByRef: varchar('performed_by_ref', { length: 100 }),
  metadata: jsonb('metadata'),
  performedAt: timestamp('performed_at', { withTimezone: true }).notNull().defaultNow(),
});

export const appointmentReschedules = appointments.table('appointment_reschedules', {
  id: uuid('id').primaryKey().defaultRandom(),
  appointmentId: uuid('appointment_id')
    .notNull()
    .references(() => appointmentsTable.id, { onDelete: 'cascade' }),
  previousStartsAt: timestamp('previous_starts_at', { withTimezone: true }).notNull(),
  previousEndsAt: timestamp('previous_ends_at', { withTimezone: true }).notNull(),
  previousSpecialistId: uuid('previous_specialist_id').references(() => employees.id, {
    onDelete: 'set null',
  }),
  newStartsAt: timestamp('new_starts_at', { withTimezone: true }).notNull(),
  newEndsAt: timestamp('new_ends_at', { withTimezone: true }).notNull(),
  newSpecialistId: uuid('new_specialist_id').references(() => employees.id, {
    onDelete: 'set null',
  }),
  reason: text('reason'),
  performedByType: varchar('performed_by_type', { length: 20 }).notNull().default('END_USER'),
  performedByRef: varchar('performed_by_ref', { length: 100 }),
  performedAt: timestamp('performed_at', { withTimezone: true }).notNull().defaultNow(),
});
