import {
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

export const subscriptionPlans = pgTable('subscription_plans', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: varchar('name', { length: 100 }).notNull(),
  description: text('description'),
  maxBranches: integer('max_branches').notNull(),
  amount: numeric('amount', { precision: 12, scale: 2 }).notNull().default('0'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const billingCycles = pgTable('billing_cycles', {
  id: uuid('id').primaryKey().defaultRandom(),
  code: varchar('code', { length: 30 }).notNull().unique(),
  name: varchar('name', { length: 50 }).notNull(),
  description: text('description'),
  intervalMonths: integer('interval_months').notNull(),
  isActive: boolean('is_active').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
});

export const billingDiscountConfigs = pgTable('billing_discount_configs', {
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

export const stateTaxConfigs = pgTable(
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
export const subAdmins = pgTable('sub_admins', {
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

export const subAdminBranches = pgTable(
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

export const subAdminModules = pgTable(
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

export const orgBillStructure = pgTable('org_bill_structure', {
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

export const orgSubscriptionChanges = pgTable('org_subscription_changes', {
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
export const invoices = pgTable('invoices', {
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

export const invoiceLineItems = pgTable('invoice_line_items', {
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

export const invoiceTaxLines = pgTable('invoice_tax_lines', {
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

export const payments = pgTable('payments', {
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

export const invoicePayments = pgTable(
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

export const creditNotes = pgTable('credit_notes', {
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

export const creditNoteLineItems = pgTable('credit_note_line_items', {
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

export const refunds = pgTable('refunds', {
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

export const commissionRateHistory = pgTable('commission_rate_history', {
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

export const orgMerchantBalances = pgTable('org_merchant_balances', {
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

export const salonPayouts = pgTable('salon_payouts', {
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

export const endUserTransactions = pgTable('end_user_transactions', {
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

export const salonPayoutItems = pgTable('salon_payout_items', {
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

export const merchantLedgerEntries = pgTable('merchant_ledger_entries', {
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
export const cmsMedia = pgTable('cms_media', {
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

export const cmsPages = pgTable('cms_pages', {
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

export const cmsPosts = pgTable('cms_posts', {
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

export const portalBanners = pgTable('portal_banners', {
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
