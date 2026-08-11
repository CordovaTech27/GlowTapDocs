-- Salon Admin portal access (Sub Admins + branch/module grants + audit)
-- into schema `admin_org`. Super Admin core stays in `public`.
-- Salon Admin login profile remains organizations.owner_* on public.organizations.

CREATE SCHEMA IF NOT EXISTS admin_org;

COMMENT ON SCHEMA admin_org IS
  'Salon Admin org portal — sub-admins, branch/module access, access audit';

ALTER TABLE IF EXISTS public.sub_admins SET SCHEMA admin_org;
ALTER TABLE IF EXISTS public.sub_admin_branches SET SCHEMA admin_org;
ALTER TABLE IF EXISTS public.sub_admin_modules SET SCHEMA admin_org;
ALTER TABLE IF EXISTS public.user_access_actions SET SCHEMA admin_org;

-- Recreate same-org trigger with schema-qualified names
CREATE OR REPLACE FUNCTION admin_org.enforce_sub_admin_branch_same_org()
RETURNS TRIGGER AS $$
DECLARE
  admin_org_id UUID;
  branch_org_id UUID;
BEGIN
  SELECT organization_id INTO admin_org_id
  FROM admin_org.sub_admins WHERE id = NEW.sub_admin_id;
  SELECT organization_id INTO branch_org_id
  FROM public.branches WHERE id = NEW.branch_id;
  IF admin_org_id IS NULL OR branch_org_id IS NULL OR admin_org_id <> branch_org_id THEN
    RAISE EXCEPTION 'sub_admin_branches: branch must belong to the same organization as sub_admin';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sub_admin_branch_same_org ON admin_org.sub_admin_branches;
CREATE TRIGGER trg_sub_admin_branch_same_org
  BEFORE INSERT OR UPDATE ON admin_org.sub_admin_branches
  FOR EACH ROW EXECUTE FUNCTION admin_org.enforce_sub_admin_branch_same_org();

-- Drop old public function if it still exists after table move
DROP FUNCTION IF EXISTS public.enforce_sub_admin_branch_same_org() CASCADE;

GRANT USAGE ON SCHEMA admin_org TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA admin_org TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA admin_org
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA admin_org TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA admin_org
  GRANT USAGE, SELECT ON SEQUENCES TO authenticated;
