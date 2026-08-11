-- Performance round 2: missing FK indexes + hot-path filters
-- (covers gaps after marketplace, CMS, reviews, tickets, service taxonomy)

-- ===========================================================================
-- Marketplace / ledger
-- ===========================================================================
CREATE INDEX IF NOT EXISTS idx_eut_salon_payout
  ON end_user_transactions(salon_payout_id)
  WHERE salon_payout_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_eut_org_occurred
  ON end_user_transactions(organization_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_eut_branch_occurred
  ON end_user_transactions(branch_id, occurred_at DESC)
  WHERE branch_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_eut_status_channel
  ON end_user_transactions(status, payment_channel, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_salon_payout_items_txn
  ON salon_payout_items(end_user_transaction_id)
  WHERE end_user_transaction_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_merchant_ledger_payment
  ON merchant_ledger_entries(payment_id)
  WHERE payment_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_merchant_ledger_payout
  ON merchant_ledger_entries(salon_payout_id)
  WHERE salon_payout_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_merchant_ledger_created_by
  ON merchant_ledger_entries(created_by)
  WHERE created_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_salon_payouts_created_by
  ON salon_payouts(created_by)
  WHERE created_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_commission_rate_history_changed_by
  ON commission_rate_history(changed_by)
  WHERE changed_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_platform_commission_config_updated_by
  ON platform_commission_config(updated_by)
  WHERE updated_by IS NOT NULL;

-- ===========================================================================
-- Organizations / branches / billing
-- ===========================================================================
CREATE INDEX IF NOT EXISTS idx_organizations_approved_by
  ON organizations(approved_by) WHERE approved_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_organizations_kyc_verified_by
  ON organizations(kyc_verified_by) WHERE kyc_verified_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_organizations_status_changed_by
  ON organizations(status_changed_by) WHERE status_changed_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_organizations_owner_disabled_by
  ON organizations(owner_disabled_by) WHERE owner_disabled_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_organizations_owner_portal_status
  ON organizations(owner_portal_status, status);

CREATE INDEX IF NOT EXISTS idx_branches_approved_by
  ON branches(approved_by) WHERE approved_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_branches_kyc_verified_by
  ON branches(kyc_verified_by) WHERE kyc_verified_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_branches_org_status
  ON branches(organization_id, status);

CREATE INDEX IF NOT EXISTS idx_org_bill_structure_configured_by
  ON org_bill_structure(configured_by) WHERE configured_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_org_bill_structure_org_status
  ON org_bill_structure(organization_id, status);

CREATE INDEX IF NOT EXISTS idx_org_status_actions_performed_by
  ON org_status_actions(performed_by) WHERE performed_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_org_subscription_changes_performed_by
  ON org_subscription_changes(performed_by) WHERE performed_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_org_subscription_changes_from_cycle
  ON org_subscription_changes(from_billing_cycle_id)
  WHERE from_billing_cycle_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_org_subscription_changes_to_cycle
  ON org_subscription_changes(to_billing_cycle_id)
  WHERE to_billing_cycle_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_billing_discount_configs_created_by
  ON billing_discount_configs(created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_billing_discount_configs_updated_by
  ON billing_discount_configs(updated_by) WHERE updated_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_reason_codes_created_by
  ON reason_codes(created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_reason_codes_updated_by
  ON reason_codes(updated_by) WHERE updated_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_state_tax_configs_created_by
  ON state_tax_configs(created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_state_tax_configs_updated_by
  ON state_tax_configs(updated_by) WHERE updated_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_invoices_created_by
  ON invoices(created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_payments_created_by
  ON payments(created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_credit_notes_created_by
  ON credit_notes(created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_refunds_created_by
  ON refunds(created_by) WHERE created_by IS NOT NULL;

-- ===========================================================================
-- User access
-- ===========================================================================
CREATE INDEX IF NOT EXISTS idx_sub_admins_disabled_by
  ON sub_admins(disabled_by_super_admin_id)
  WHERE disabled_by_super_admin_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_user_access_actions_performed_by
  ON user_access_actions(performed_by)
  WHERE performed_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_user_access_actions_target
  ON user_access_actions(target_type, performed_at DESC);

-- ===========================================================================
-- CMS & banners
-- ===========================================================================
CREATE INDEX IF NOT EXISTS idx_cms_media_uploaded_by
  ON cms_media(uploaded_by) WHERE uploaded_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_cms_pages_og_image
  ON cms_pages(og_image_media_id) WHERE og_image_media_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_cms_pages_created_by
  ON cms_pages(created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_cms_pages_updated_by
  ON cms_pages(updated_by) WHERE updated_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_cms_pages_public
  ON cms_pages(status, publish_at)
  WHERE status IN ('PUBLISHED', 'SCHEDULED');

CREATE INDEX IF NOT EXISTS idx_cms_posts_cover
  ON cms_posts(cover_media_id) WHERE cover_media_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_cms_posts_author
  ON cms_posts(author_id) WHERE author_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_cms_posts_created_by
  ON cms_posts(created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_cms_posts_updated_by
  ON cms_posts(updated_by) WHERE updated_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_portal_banners_image
  ON portal_banners(image_media_id) WHERE image_media_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_portal_banners_created_by
  ON portal_banners(created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_portal_banners_updated_by
  ON portal_banners(updated_by) WHERE updated_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_portal_banners_window
  ON portal_banners(active_from, active_until)
  WHERE is_active = TRUE;

-- ===========================================================================
-- Reviews & moderation
-- ===========================================================================
CREATE INDEX IF NOT EXISTS idx_reviews_branch
  ON reviews(branch_id, status, submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_reviews_published
  ON reviews(branch_id, published_at DESC)
  WHERE status = 'PUBLISHED';

CREATE INDEX IF NOT EXISTS idx_review_replies_org
  ON review_replies(organization_id, replied_at DESC);

CREATE INDEX IF NOT EXISTS idx_review_reports_reply
  ON review_reports(reply_id) WHERE reply_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_review_reports_resolved_by
  ON review_reports(resolved_by) WHERE resolved_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_review_moderation_actions_reply
  ON review_moderation_actions(reply_id) WHERE reply_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_review_moderation_actions_image
  ON review_moderation_actions(image_id) WHERE image_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_review_moderation_actions_performed_by
  ON review_moderation_actions(performed_by) WHERE performed_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_review_moderation_actions_action
  ON review_moderation_actions(action, performed_at DESC);

CREATE INDEX IF NOT EXISTS idx_review_abuse_rules_created_by
  ON review_abuse_rules(created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_review_abuse_rules_updated_by
  ON review_abuse_rules(updated_by) WHERE updated_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_review_moderation_settings_updated_by
  ON review_moderation_settings(updated_by) WHERE updated_by IS NOT NULL;

-- ===========================================================================
-- Support & ticketing
-- ===========================================================================
CREATE INDEX IF NOT EXISTS idx_support_tickets_category
  ON support_tickets(category_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_type
  ON support_tickets(type_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_subtype
  ON support_tickets(subtype_id) WHERE subtype_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_support_tickets_sla_policy
  ON support_tickets(sla_policy_id) WHERE sla_policy_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_support_tickets_branch
  ON support_tickets(branch_id) WHERE branch_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_support_tickets_created_by_sa
  ON support_tickets(created_by_super_admin_id)
  WHERE created_by_super_admin_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_support_tickets_source_status
  ON support_tickets(source, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_support_tickets_booking
  ON support_tickets(booking_ref)
  WHERE booking_ref IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_support_ticket_attachments_message
  ON support_ticket_attachments(message_id)
  WHERE message_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_support_ticket_messages_author_sa
  ON support_ticket_messages(author_super_admin_id)
  WHERE author_super_admin_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_support_ticket_internal_notes_created_by
  ON support_ticket_internal_notes(created_by)
  WHERE created_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_support_ticket_events_performed_by
  ON support_ticket_events(performed_by)
  WHERE performed_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_support_ticket_categories_created_by
  ON support_ticket_categories(created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_support_ticket_categories_updated_by
  ON support_ticket_categories(updated_by) WHERE updated_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_support_ticket_categories_audience
  ON support_ticket_categories(audience, is_active, sort_order);

CREATE INDEX IF NOT EXISTS idx_support_sla_policies_updated_by
  ON support_sla_policies(updated_by) WHERE updated_by IS NOT NULL;

-- ===========================================================================
-- Service catalog taxonomy
-- ===========================================================================
CREATE INDEX IF NOT EXISTS idx_service_categories_created_by
  ON service_categories(created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_service_categories_updated_by
  ON service_categories(updated_by) WHERE updated_by IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_service_subcategories_created_by
  ON service_subcategories(created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_service_subcategories_updated_by
  ON service_subcategories(updated_by) WHERE updated_by IS NOT NULL;

-- Unique composite already on (category_id, code); ensure types unique too if missing
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'support_ticket_types_category_id_code_key'
  ) THEN
    ALTER TABLE support_ticket_types
      ADD CONSTRAINT support_ticket_types_category_id_code_key UNIQUE (category_id, code);
  END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'support_ticket_subtypes_type_id_code_key'
  ) THEN
    ALTER TABLE support_ticket_subtypes
      ADD CONSTRAINT support_ticket_subtypes_type_id_code_key UNIQUE (type_id, code);
  END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'service_subcategories_category_id_code_key'
  ) THEN
    ALTER TABLE service_subcategories
      ADD CONSTRAINT service_subcategories_category_id_code_key UNIQUE (category_id, code);
  END IF;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ===========================================================================
-- ANALYZE (planner stats)
-- ===========================================================================
ANALYZE organizations;
ANALYZE branches;
ANALYZE org_bill_structure;
ANALYZE org_status_actions;
ANALYZE org_subscription_changes;
ANALYZE billing_discount_configs;
ANALYZE reason_codes;
ANALYZE state_tax_configs;
ANALYZE invoices;
ANALYZE payments;
ANALYZE credit_notes;
ANALYZE refunds;
ANALYZE end_user_transactions;
ANALYZE salon_payouts;
ANALYZE salon_payout_items;
ANALYZE merchant_ledger_entries;
ANALYZE commission_rate_history;
ANALYZE platform_commission_config;
ANALYZE sub_admins;
ANALYZE sub_admin_branches;
ANALYZE sub_admin_modules;
ANALYZE user_access_actions;
ANALYZE cms_media;
ANALYZE cms_pages;
ANALYZE cms_posts;
ANALYZE portal_banners;
ANALYZE reviews;
ANALYZE review_images;
ANALYZE review_replies;
ANALYZE review_reports;
ANALYZE review_moderation_actions;
ANALYZE review_abuse_rules;
ANALYZE review_moderation_settings;
ANALYZE support_tickets;
ANALYZE support_ticket_messages;
ANALYZE support_ticket_internal_notes;
ANALYZE support_ticket_attachments;
ANALYZE support_ticket_events;
ANALYZE support_ticket_categories;
ANALYZE support_ticket_types;
ANALYZE support_ticket_subtypes;
ANALYZE support_sla_policies;
ANALYZE service_categories;
ANALYZE service_subcategories;
