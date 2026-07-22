-- Optional marketing / ad attribution (UTM etc.) captured at registration

ALTER TABLE organizations
  ADD COLUMN IF NOT EXISTS campaign_attribution JSONB;

COMMENT ON COLUMN organizations.campaign_attribution IS
  'Signup attribution, e.g. {"utm_source":"instagram","utm_medium":"cpc","utm_campaign":"salon_launch_july"}';
