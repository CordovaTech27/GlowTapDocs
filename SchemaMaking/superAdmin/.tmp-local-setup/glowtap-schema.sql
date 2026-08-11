--
-- PostgreSQL database dump
--



-- Dumped from database version 18.4 (df16b3c)
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: admin_org; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS admin_org;


--
-- Name: appointments; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS appointments;


--
-- Name: pg_session_jwt; Type: EXTENSION; Schema: -; Owner: -
--

-- skipped: pg_session_jwt (Neon-only)



--
-- Name: cms; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS cms;


--
-- Name: employee; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS employee;


--
-- Name: pgrst; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS pgrst;


--
-- Name: review; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS review;


--
-- Name: rms; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS rms;


--
-- Name: services; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS services;


--
-- Name: subscription; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS subscription;


--
-- Name: tickets; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA IF NOT EXISTS tickets;


--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: actor_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.actor_type AS ENUM (
    'SUPER_ADMIN',
    'SALON_ADMIN',
    'SUB_ADMIN',
    'END_USER',
    'SYSTEM'
);


--
-- Name: amount_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.amount_type AS ENUM (
    'FIXED',
    'PERCENT'
);


--
-- Name: branch_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.branch_status AS ENUM (
    'PENDING',
    'ACTIVE',
    'INACTIVE',
    'REJECTED'
);


--
-- Name: campaign_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.campaign_status AS ENUM (
    'DRAFT',
    'SCHEDULED',
    'LIVE',
    'EXPIRED',
    'CANCELLED',
    'REJECTED'
);


--
-- Name: cms_page_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.cms_page_status AS ENUM (
    'DRAFT',
    'PUBLISHED',
    'SCHEDULED',
    'ARCHIVED'
);


--
-- Name: discount_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.discount_type AS ENUM (
    'RC',
    'NRC'
);


--
-- Name: end_user_txn_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.end_user_txn_status AS ENUM (
    'PENDING',
    'SUCCESS',
    'FAILED',
    'REFUNDED',
    'DISPUTED'
);


--
-- Name: kyc_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.kyc_status AS ENUM (
    'NOT_REQUIRED',
    'PENDING',
    'VERIFIED',
    'REJECTED'
);


--
-- Name: lead_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.lead_status AS ENUM (
    'PENDING_REVIEW',
    'AWAITING_INFO',
    'APPROVED',
    'REJECTED'
);


--
-- Name: org_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.org_status AS ENUM (
    'PENDING',
    'ACTIVE',
    'SUSPENDED',
    'TERMINATED'
);


--
-- Name: payment_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.payment_status AS ENUM (
    'PENDING',
    'SUCCESS',
    'FAILED',
    'REFUNDED'
);


--
-- Name: plan_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.plan_status AS ENUM (
    'ACTIVE',
    'DEPRECATED',
    'RETIRED'
);


--
-- Name: reason_category; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.reason_category AS ENUM (
    'SUSPEND',
    'TERMINATE',
    'REJECT',
    'TICKET',
    'TICKET_SUB',
    'BRANCH_REJECT',
    'LEAD_REJECT'
);


--
-- Name: subscription_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.subscription_status AS ENUM (
    'ACTIVE',
    'PAST_DUE',
    'CANCELLED',
    'EXPIRED'
);


--
-- Name: subscription_txn_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.subscription_txn_type AS ENUM (
    'PURCHASE',
    'RENEWAL',
    'UPGRADE',
    'REFUND',
    'CREDIT'
);


--
-- Name: super_admin_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.super_admin_role AS ENUM (
    'SUPER_ADMIN',
    'SUPER_ADMIN_READ_ONLY',
    'OPS_AGENT'
);


--
-- Name: ticket_priority; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.ticket_priority AS ENUM (
    'LOW',
    'MEDIUM',
    'HIGH',
    'CRITICAL'
);


--
-- Name: ticket_source; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.ticket_source AS ENUM (
    'SUPER_ADMIN',
    'SALON_PORTAL',
    'SYSTEM'
);


--
-- Name: ticket_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.ticket_status AS ENUM (
    'CREATED',
    'IN_PROGRESS',
    'ON_HOLD',
    'AWAITING_USER_CONFIRMATION',
    'RESOLVED'
);


--
-- Name: user_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_status AS ENUM (
    'ACTIVE',
    'DISABLED',
    'PENDING'
);


--
-- Name: enforce_sub_admin_branch_same_org(); Type: FUNCTION; Schema: admin_org; Owner: -
--

CREATE FUNCTION admin_org.enforce_sub_admin_branch_same_org() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: enforce_appointment_scope(); Type: FUNCTION; Schema: appointments; Owner: -
--

CREATE FUNCTION appointments.enforce_appointment_scope() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  branch_org UUID;
  svc RECORD;
BEGIN
  SELECT organization_id INTO branch_org FROM public.branches WHERE id = NEW.branch_id;
  IF branch_org IS NULL OR branch_org <> NEW.organization_id THEN
    RAISE EXCEPTION 'appointments: branch must belong to the same organization';
  END IF;

  SELECT organization_id, branch_id INTO svc
  FROM services.branch_services WHERE id = NEW.branch_service_id;
  IF svc.organization_id IS NULL OR svc.organization_id <> NEW.organization_id
     OR svc.branch_id <> NEW.branch_id THEN
    RAISE EXCEPTION 'appointments: service must belong to the same org and branch';
  END IF;

  IF NEW.specialist_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM employee.employees e
      WHERE e.id = NEW.specialist_id
        AND e.organization_id = NEW.organization_id
        AND e.branch_id = NEW.branch_id
    ) THEN
      RAISE EXCEPTION 'appointments: specialist must belong to the same org and branch';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: enforce_branch_leave_policy_line_same_org(); Type: FUNCTION; Schema: employee; Owner: -
--

CREATE FUNCTION employee.enforce_branch_leave_policy_line_same_org() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  branch_org UUID;
  type_org UUID;
BEGIN
  SELECT organization_id INTO branch_org FROM public.branches WHERE id = NEW.branch_id;
  SELECT organization_id INTO type_org FROM employee.leave_types WHERE id = NEW.leave_type_id;
  IF branch_org IS NULL OR branch_org <> NEW.organization_id THEN
    RAISE EXCEPTION 'branch_leave_policies: branch must belong to the same organization';
  END IF;
  IF type_org IS NULL OR type_org <> NEW.organization_id THEN
    RAISE EXCEPTION 'branch_leave_policies: leave_type must belong to the same organization';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: enforce_employee_branch_same_org(); Type: FUNCTION; Schema: employee; Owner: -
--

CREATE FUNCTION employee.enforce_employee_branch_same_org() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  branch_org UUID;
BEGIN
  SELECT organization_id INTO branch_org FROM public.branches WHERE id = NEW.branch_id;
  IF branch_org IS NULL OR branch_org <> NEW.organization_id THEN
    RAISE EXCEPTION 'employees: branch must belong to the same organization';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: pre_config(); Type: FUNCTION; Schema: pgrst; Owner: -
--

CREATE FUNCTION pgrst.pre_config() RETURNS void
    LANGUAGE sql
    SET search_path TO ''
    AS $$
  SELECT
      set_config('pgrst.db_schemas', 'public', true)
    , set_config('pgrst.db_aggregates_enabled', 'true', true)
    , set_config('pgrst.db_anon_role', 'anonymous', true)
    , set_config('pgrst.jwt_role_claim_key', '.role', true)
$$;


--
-- Name: active_branch_count(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.active_branch_count(p_org_id uuid) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT COUNT(*)::INT
  FROM branches
  WHERE organization_id = p_org_id AND status = 'ACTIVE';
$$;


--
-- Name: booked_banner_slots(date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.booked_banner_slots(p_date date) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT COUNT(*)::INT
  FROM banner_slot_ledger
  WHERE slot_date = p_date AND status = 'BOOKED';
$$;


--
-- Name: effective_max_branches(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.effective_max_branches(p_org_id uuid) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT COALESCE(os.branch_limit_override, sp.max_branches)::INT
  FROM organization_subscriptions os
  JOIN subscription_plans sp ON sp.id = os.plan_id
  WHERE os.organization_id = p_org_id
    AND os.status IN ('ACTIVE', 'PAST_DUE')
  ORDER BY os.created_at DESC
  LIMIT 1;
$$;


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


--
-- Name: enforce_branch_service_refs(); Type: FUNCTION; Schema: services; Owner: -
--

CREATE FUNCTION services.enforce_branch_service_refs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  branch_org UUID;
  sub_cat UUID;
BEGIN
  SELECT organization_id INTO branch_org FROM public.branches WHERE id = NEW.branch_id;
  IF branch_org IS NULL OR branch_org <> NEW.organization_id THEN
    RAISE EXCEPTION 'branch_services: branch must belong to the same organization';
  END IF;

  SELECT category_id INTO sub_cat
  FROM services.service_subcategories WHERE id = NEW.subcategory_id;
  IF sub_cat IS NULL OR sub_cat <> NEW.category_id THEN
    RAISE EXCEPTION 'branch_services: subcategory must belong to the selected category';
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: enforce_service_specialist_same_scope(); Type: FUNCTION; Schema: services; Owner: -
--

CREATE FUNCTION services.enforce_service_specialist_same_scope() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  svc RECORD;
  emp RECORD;
BEGIN
  SELECT organization_id, branch_id INTO svc
  FROM services.branch_services WHERE id = NEW.branch_service_id;

  SELECT organization_id, branch_id, status INTO emp
  FROM employee.employees WHERE id = NEW.employee_id;

  IF svc.organization_id IS NULL OR emp.organization_id IS NULL THEN
    RAISE EXCEPTION 'branch_service_specialists: invalid service or employee';
  END IF;
  IF svc.organization_id <> emp.organization_id THEN
    RAISE EXCEPTION 'branch_service_specialists: employee must belong to the same organization as the service';
  END IF;
  IF svc.branch_id <> emp.branch_id THEN
    RAISE EXCEPTION 'branch_service_specialists: employee must belong to the same branch as the service';
  END IF;
  IF emp.status <> 'ACTIVE' THEN
    RAISE EXCEPTION 'branch_service_specialists: employee must be ACTIVE';
  END IF;

  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: sub_admin_branches; Type: TABLE; Schema: admin_org; Owner: -
--

CREATE TABLE admin_org.sub_admin_branches (
    sub_admin_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: sub_admin_modules; Type: TABLE; Schema: admin_org; Owner: -
--

CREATE TABLE admin_org.sub_admin_modules (
    sub_admin_id uuid NOT NULL,
    module character varying(30) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT sub_admin_modules_module_check CHECK (((module)::text = ANY ((ARRAY['BRANCH_PROFILE'::character varying, 'EMPLOYEES'::character varying, 'LEAVE_HOLIDAYS'::character varying, 'ATTENDANCE'::character varying, 'SERVICES'::character varying, 'APPOINTMENTS'::character varying, 'TRANSACTIONS'::character varying, 'REPORTS'::character varying])::text[])))
);


--
-- Name: sub_admins; Type: TABLE; Schema: admin_org; Owner: -
--

CREATE TABLE admin_org.sub_admins (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    full_name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    phone character varying(20),
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    disabled_by_role character varying(20),
    disabled_at timestamp with time zone,
    disabled_by_super_admin_id uuid,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT sub_admins_disabled_by_role_check CHECK (((disabled_by_role IS NULL) OR ((disabled_by_role)::text = ANY ((ARRAY['SALON_ADMIN'::character varying, 'SUPER_ADMIN'::character varying])::text[])))),
    CONSTRAINT sub_admins_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'DISABLED'::character varying])::text[])))
);


--
-- Name: appointment_holds; Type: TABLE; Schema: appointments; Owner: -
--

CREATE TABLE appointments.appointment_holds (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    branch_service_id uuid NOT NULL,
    specialist_id uuid,
    end_user_ref character varying(50),
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT appointment_holds_check CHECK ((ends_at > starts_at)),
    CONSTRAINT appointment_holds_check1 CHECK ((expires_at > created_at)),
    CONSTRAINT appointment_holds_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'CONSUMED'::character varying, 'EXPIRED'::character varying, 'RELEASED'::character varying])::text[])))
);


--
-- Name: appointment_reschedules; Type: TABLE; Schema: appointments; Owner: -
--

CREATE TABLE appointments.appointment_reschedules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    appointment_id uuid NOT NULL,
    previous_starts_at timestamp with time zone NOT NULL,
    previous_ends_at timestamp with time zone NOT NULL,
    previous_specialist_id uuid,
    new_starts_at timestamp with time zone NOT NULL,
    new_ends_at timestamp with time zone NOT NULL,
    new_specialist_id uuid,
    reason text,
    performed_by_type character varying(20) DEFAULT 'END_USER'::character varying NOT NULL,
    performed_by_ref character varying(100),
    performed_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT appointment_reschedules_check CHECK ((previous_ends_at > previous_starts_at)),
    CONSTRAINT appointment_reschedules_check1 CHECK ((new_ends_at > new_starts_at)),
    CONSTRAINT appointment_reschedules_performed_by_type_check CHECK (((performed_by_type)::text = ANY ((ARRAY['END_USER'::character varying, 'SALON_ADMIN'::character varying, 'SUB_ADMIN'::character varying, 'SUPER_ADMIN'::character varying, 'SYSTEM'::character varying])::text[])))
);


--
-- Name: appointment_status_events; Type: TABLE; Schema: appointments; Owner: -
--

CREATE TABLE appointments.appointment_status_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    appointment_id uuid NOT NULL,
    from_status character varying(30),
    to_status character varying(30) NOT NULL,
    reason text,
    performed_by_type character varying(20) DEFAULT 'SYSTEM'::character varying NOT NULL,
    performed_by_ref character varying(100),
    metadata jsonb,
    performed_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT appointment_status_events_performed_by_type_check CHECK (((performed_by_type)::text = ANY ((ARRAY['END_USER'::character varying, 'SALON_ADMIN'::character varying, 'SUB_ADMIN'::character varying, 'SUPER_ADMIN'::character varying, 'SYSTEM'::character varying])::text[])))
);


--
-- Name: appointments; Type: TABLE; Schema: appointments; Owner: -
--

CREATE TABLE appointments.appointments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    booking_number character varying(40) NOT NULL,
    organization_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    branch_service_id uuid NOT NULL,
    specialist_id uuid,
    end_user_ref character varying(50) NOT NULL,
    end_user_name character varying(255),
    end_user_phone character varying(20),
    end_user_email character varying(255),
    service_name character varying(255) NOT NULL,
    service_duration_min integer NOT NULL,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    status character varying(30) DEFAULT 'BOOKED'::character varying NOT NULL,
    source character varying(30) DEFAULT 'CONSUMER_APP'::character varying NOT NULL,
    customer_note text,
    currency character varying(3) DEFAULT 'INR'::character varying NOT NULL,
    list_price numeric(12,2) DEFAULT 0 NOT NULL,
    discount_amount numeric(12,2) DEFAULT 0 NOT NULL,
    gross_amount numeric(12,2) DEFAULT 0 NOT NULL,
    payment_method character varying(20) DEFAULT 'ONLINE'::character varying NOT NULL,
    payment_status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    eut_transaction_id uuid,
    hold_id uuid,
    cancel_reason text,
    cancelled_at timestamp with time zone,
    confirmed_at timestamp with time zone,
    completed_at timestamp with time zone,
    no_show_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT appointments_check CHECK ((ends_at > starts_at)),
    CONSTRAINT appointments_payment_method_check CHECK (((payment_method)::text = ANY ((ARRAY['ONLINE'::character varying, 'OFFLINE'::character varying])::text[]))),
    CONSTRAINT appointments_payment_status_check CHECK (((payment_status)::text = ANY ((ARRAY['PENDING'::character varying, 'PAID'::character varying, 'FAILED'::character varying, 'REFUNDED'::character varying, 'PARTIAL_REFUND'::character varying, 'NOT_REQUIRED'::character varying])::text[]))),
    CONSTRAINT appointments_service_duration_min_check CHECK ((service_duration_min > 0)),
    CONSTRAINT appointments_source_check CHECK (((source)::text = ANY ((ARRAY['CONSUMER_APP'::character varying, 'WALK_IN'::character varying, 'ADMIN'::character varying, 'SYSTEM'::character varying])::text[]))),
    CONSTRAINT appointments_status_check CHECK (((status)::text = ANY ((ARRAY['BOOKED'::character varying, 'CONFIRMED'::character varying, 'IN_PROGRESS'::character varying, 'COMPLETED'::character varying, 'CANCELLED'::character varying, 'NO_SHOW'::character varying])::text[])))
);


--
-- Name: cms_media; Type: TABLE; Schema: cms; Owner: -
--

CREATE TABLE cms.cms_media (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    file_name character varying(255) NOT NULL,
    storage_url text NOT NULL,
    mime_type character varying(100) NOT NULL,
    media_type character varying(20) DEFAULT 'IMAGE'::character varying NOT NULL,
    file_size_bytes bigint,
    alt_text character varying(255),
    width_px integer,
    height_px integer,
    duration_sec integer,
    uploaded_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT cms_media_media_type_check CHECK (((media_type)::text = ANY ((ARRAY['IMAGE'::character varying, 'VIDEO'::character varying, 'DOCUMENT'::character varying, 'OTHER'::character varying])::text[])))
);


--
-- Name: cms_pages; Type: TABLE; Schema: cms; Owner: -
--

CREATE TABLE cms.cms_pages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    slug character varying(100) NOT NULL,
    title character varying(255) NOT NULL,
    page_type character varying(30) DEFAULT 'CUSTOM'::character varying NOT NULL,
    body jsonb DEFAULT '{}'::jsonb NOT NULL,
    seo_title character varying(255),
    seo_description text,
    og_image_media_id uuid,
    status character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    publish_at timestamp with time zone,
    published_at timestamp with time zone,
    preview_token character varying(64),
    sort_order integer DEFAULT 0 NOT NULL,
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT cms_pages_page_type_check CHECK (((page_type)::text = ANY ((ARRAY['ABOUT'::character varying, 'PRICING'::character varying, 'FEATURES'::character varying, 'FAQ'::character varying, 'TERMS'::character varying, 'PRIVACY'::character varying, 'CUSTOM'::character varying])::text[]))),
    CONSTRAINT cms_pages_status_check CHECK (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'SCHEDULED'::character varying, 'PUBLISHED'::character varying, 'ARCHIVED'::character varying])::text[])))
);


--
-- Name: cms_posts; Type: TABLE; Schema: cms; Owner: -
--

CREATE TABLE cms.cms_posts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    slug character varying(150) NOT NULL,
    title character varying(255) NOT NULL,
    excerpt text,
    body jsonb DEFAULT '{}'::jsonb NOT NULL,
    cover_media_id uuid,
    seo_title character varying(255),
    seo_description text,
    tags text[] DEFAULT '{}'::text[] NOT NULL,
    status character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    publish_at timestamp with time zone,
    published_at timestamp with time zone,
    preview_token character varying(64),
    author_id uuid,
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT cms_posts_status_check CHECK (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'SCHEDULED'::character varying, 'PUBLISHED'::character varying, 'ARCHIVED'::character varying])::text[])))
);


--
-- Name: portal_banners; Type: TABLE; Schema: cms; Owner: -
--

CREATE TABLE cms.portal_banners (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying(255) NOT NULL,
    body_text text,
    image_media_id uuid,
    image_url text,
    cta_text character varying(100),
    cta_link text,
    targeting_rules jsonb DEFAULT '{}'::jsonb NOT NULL,
    display_priority integer DEFAULT 100 NOT NULL,
    active_from timestamp with time zone DEFAULT now() NOT NULL,
    active_until timestamp with time zone,
    is_active boolean DEFAULT true NOT NULL,
    ab_variant character varying(20),
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: attendance_audit_actions; Type: TABLE; Schema: employee; Owner: -
--

CREATE TABLE employee.attendance_audit_actions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    attendance_id uuid NOT NULL,
    action character varying(30) NOT NULL,
    before_data jsonb,
    after_data jsonb,
    reason text,
    performed_by_ref character varying(100),
    performed_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT attendance_audit_actions_action_check CHECK (((action)::text = ANY ((ARRAY['CREATE'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying])::text[])))
);


--
-- Name: attendance_records; Type: TABLE; Schema: employee; Owner: -
--

CREATE TABLE employee.attendance_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    attendance_date date NOT NULL,
    check_in_at timestamp with time zone,
    check_out_at timestamp with time zone,
    status character varying(20) DEFAULT 'PRESENT'::character varying NOT NULL,
    source character varying(20) DEFAULT 'MANUAL'::character varying NOT NULL,
    notes text,
    marked_by_ref character varying(100),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT attendance_records_check CHECK (((check_out_at IS NULL) OR (check_in_at IS NULL) OR (check_out_at >= check_in_at))),
    CONSTRAINT attendance_records_source_check CHECK (((source)::text = ANY ((ARRAY['MANUAL'::character varying, 'SYSTEM'::character varying, 'BIOMETRIC'::character varying, 'GEO'::character varying])::text[]))),
    CONSTRAINT attendance_records_status_check CHECK (((status)::text = ANY ((ARRAY['PRESENT'::character varying, 'ABSENT'::character varying, 'HALF_DAY'::character varying, 'ON_LEAVE'::character varying, 'WEEKLY_OFF'::character varying, 'HOLIDAY'::character varying])::text[])))
);


--
-- Name: branch_holidays; Type: TABLE; Schema: employee; Owner: -
--

CREATE TABLE employee.branch_holidays (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    holiday_date date NOT NULL,
    name character varying(255) NOT NULL,
    is_recurring_annual boolean DEFAULT false NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: branch_leave_policies; Type: TABLE; Schema: employee; Owner: -
--

CREATE TABLE employee.branch_leave_policies (
    id uuid DEFAULT gen_random_uuid() CONSTRAINT branch_leave_accrual_rules_id_not_null NOT NULL,
    organization_id uuid CONSTRAINT branch_leave_accrual_rules_organization_id_not_null NOT NULL,
    branch_id uuid CONSTRAINT branch_leave_accrual_rules_branch_id_not_null NOT NULL,
    leave_type_id uuid CONSTRAINT branch_leave_accrual_rules_leave_type_id_not_null NOT NULL,
    days_per_month numeric(6,2) DEFAULT 0 CONSTRAINT branch_leave_accrual_rules_days_per_month_not_null NOT NULL,
    is_active boolean DEFAULT true CONSTRAINT branch_leave_accrual_rules_is_active_not_null NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() CONSTRAINT branch_leave_accrual_rules_created_at_not_null NOT NULL,
    updated_at timestamp with time zone DEFAULT now() CONSTRAINT branch_leave_accrual_rules_updated_at_not_null NOT NULL,
    carry_forward_allowed boolean DEFAULT false CONSTRAINT branch_leave_accrual_rules_carry_forward_allowed_not_null NOT NULL,
    leave_year_end_month smallint DEFAULT 3 NOT NULL,
    leave_year_end_day smallint DEFAULT 31 NOT NULL,
    carry_forward_pct numeric(5,2) DEFAULT 0 NOT NULL,
    carry_forward_max_days numeric(6,2),
    CONSTRAINT branch_leave_accrual_rules_days_per_month_check CHECK ((days_per_month >= (0)::numeric)),
    CONSTRAINT branch_leave_policies_carry_forward_pct_check CHECK (((carry_forward_pct >= (0)::numeric) AND (carry_forward_pct <= (100)::numeric))),
    CONSTRAINT branch_leave_policies_leave_year_end_day_check CHECK (((leave_year_end_day >= 1) AND (leave_year_end_day <= 31))),
    CONSTRAINT branch_leave_policies_leave_year_end_month_check CHECK (((leave_year_end_month >= 1) AND (leave_year_end_month <= 12)))
);


--
-- Name: employee_actions; Type: TABLE; Schema: employee; Owner: -
--

CREATE TABLE employee.employee_actions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    action character varying(30) NOT NULL,
    reason text,
    metadata jsonb,
    performed_by_ref character varying(100),
    performed_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT employee_actions_action_check CHECK (((action)::text = ANY ((ARRAY['CREATE'::character varying, 'UPDATE'::character varying, 'DEACTIVATE'::character varying, 'REACTIVATE'::character varying, 'TRANSFER_BRANCH'::character varying, 'WEEKLY_OFF_CHANGE'::character varying])::text[])))
);


--
-- Name: employees; Type: TABLE; Schema: employee; Owner: -
--

CREATE TABLE employee.employees (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    employee_number character varying(30) NOT NULL,
    full_name character varying(255) NOT NULL,
    email character varying(255),
    phone character varying(20),
    designation character varying(100),
    photo_url text,
    date_of_joining date DEFAULT CURRENT_DATE NOT NULL,
    date_of_exit date,
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    notes text,
    deactivated_at timestamp with time zone,
    deactivated_reason text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT employees_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying])::text[])))
);


--
-- Name: leave_balances; Type: TABLE; Schema: employee; Owner: -
--

CREATE TABLE employee.leave_balances (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid NOT NULL,
    leave_type_id uuid NOT NULL,
    year integer NOT NULL,
    entitled_days numeric(6,2) DEFAULT 0 NOT NULL,
    used_days numeric(6,2) DEFAULT 0 NOT NULL,
    carried_forward numeric(6,2) DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT leave_balances_year_check CHECK (((year >= 2000) AND (year <= 2100)))
);


--
-- Name: leave_requests; Type: TABLE; Schema: employee; Owner: -
--

CREATE TABLE employee.leave_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    leave_type_id uuid NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    total_days numeric(6,2) NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    reason text,
    admin_note text,
    decided_by_ref character varying(100),
    decided_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT leave_requests_check CHECK ((end_date >= start_date)),
    CONSTRAINT leave_requests_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'APPROVED'::character varying, 'REJECTED'::character varying, 'CANCELLED'::character varying])::text[])))
);


--
-- Name: leave_types; Type: TABLE; Schema: employee; Owner: -
--

CREATE TABLE employee.leave_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    code character varying(30) NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    is_paid boolean DEFAULT true NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: branches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.branches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    slug character varying(100) NOT NULL,
    address jsonb NOT NULL,
    contact_phone character varying(20),
    contact_email character varying(255),
    operating_hours jsonb,
    latitude numeric(10,7),
    longitude numeric(10,7),
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    approved_at timestamp with time zone,
    approved_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    kyc_document_url text,
    gst_certificate_url text,
    photo_url text,
    signed_agreement_url text,
    is_agreement_signed boolean DEFAULT false NOT NULL,
    shop_establishment_license_url text,
    trade_license_url text,
    branch_gst_number character varying(50),
    kyc_status character varying(20) DEFAULT 'NOT_SUBMITTED'::character varying NOT NULL,
    kyc_verified_at timestamp with time zone,
    kyc_verified_by uuid,
    state_id uuid,
    shop_establishment_license_number character varying(50),
    trade_license_number character varying(50),
    weekly_off_days smallint[] DEFAULT '{}'::smallint[] NOT NULL,
    CONSTRAINT branches_kyc_status_check CHECK (((kyc_status)::text = ANY ((ARRAY['NOT_SUBMITTED'::character varying, 'PENDING'::character varying, 'VERIFIED'::character varying, 'REJECTED'::character varying])::text[]))),
    CONSTRAINT branches_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'ACTIVE'::character varying, 'INACTIVE'::character varying, 'REJECTED'::character varying])::text[]))),
    CONSTRAINT branches_weekly_off_days_valid CHECK ((weekly_off_days <@ ARRAY[(0)::smallint, (1)::smallint, (2)::smallint, (3)::smallint, (4)::smallint, (5)::smallint, (6)::smallint]))
);


--
-- Name: org_status_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_status_actions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    action character varying(20) NOT NULL,
    from_status character varying(20) NOT NULL,
    to_status character varying(20) NOT NULL,
    reason_code_id uuid,
    notes text,
    performed_by uuid,
    performed_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT org_status_actions_action_check CHECK (((action)::text = ANY ((ARRAY['SUSPEND'::character varying, 'RESUME'::character varying, 'TERMINATE'::character varying])::text[])))
);


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    slug character varying(100) NOT NULL,
    legal_name character varying(255),
    owner_name character varying(255) NOT NULL,
    owner_email character varying(255) NOT NULL,
    owner_phone character varying(20),
    gst_number character varying(50),
    pan_number character varying(20),
    logo_url text,
    registered_address jsonb NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    onboarded_at timestamp with time zone,
    approved_at timestamp with time zone,
    approved_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    kyc_document_url text,
    gst_certificate_url text,
    photo_url text,
    signed_agreement_url text,
    is_agreement_signed boolean DEFAULT false NOT NULL,
    business_type character varying(30),
    cin character varying(21),
    udyam_msme_number character varying(20),
    gst_registration_type character varying(20),
    kyc_status character varying(20) DEFAULT 'NOT_SUBMITTED'::character varying NOT NULL,
    kyc_verified_at timestamp with time zone,
    kyc_verified_by uuid,
    state_id uuid NOT NULL,
    campaign_attribution jsonb,
    status_reason_id uuid,
    status_notes text,
    status_changed_at timestamp with time zone,
    status_changed_by uuid,
    suspended_at timestamp with time zone,
    resumed_at timestamp with time zone,
    terminated_at timestamp with time zone,
    owner_portal_status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    owner_last_login_at timestamp with time zone,
    owner_disabled_at timestamp with time zone,
    owner_disabled_by uuid,
    CONSTRAINT organizations_business_type_check CHECK (((business_type)::text = ANY ((ARRAY['SOLE_PROPRIETOR'::character varying, 'PARTNERSHIP'::character varying, 'LLP'::character varying, 'PRIVATE_LIMITED'::character varying, 'PUBLIC_LIMITED'::character varying, 'OTHER'::character varying])::text[]))),
    CONSTRAINT organizations_gst_registration_type_check CHECK (((gst_registration_type)::text = ANY ((ARRAY['REGULAR'::character varying, 'COMPOSITION'::character varying, 'UNREGISTERED'::character varying])::text[]))),
    CONSTRAINT organizations_kyc_status_check CHECK (((kyc_status)::text = ANY ((ARRAY['NOT_SUBMITTED'::character varying, 'PENDING'::character varying, 'VERIFIED'::character varying, 'REJECTED'::character varying])::text[]))),
    CONSTRAINT organizations_owner_portal_status_check CHECK (((owner_portal_status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'DISABLED'::character varying])::text[]))),
    CONSTRAINT organizations_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'ACTIVE'::character varying, 'SUSPENDED'::character varying, 'TERMINATED'::character varying])::text[])))
);


--
-- Name: platform_commission_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.platform_commission_config (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    default_pct numeric(5,2) DEFAULT 5.00 NOT NULL,
    min_pct numeric(5,2) DEFAULT 1.00 NOT NULL,
    max_pct numeric(5,2) DEFAULT 25.00 NOT NULL,
    apply_on_refunds boolean DEFAULT true NOT NULL,
    monthly_invoice_day integer DEFAULT 1 NOT NULL,
    invoice_due_days integer DEFAULT 7 NOT NULL,
    outstanding_invoice_threshold numeric(12,2) DEFAULT 5000.00 CONSTRAINT platform_commission_config_outstanding_invoice_thresho_not_null NOT NULL,
    auto_recover_from_payouts boolean DEFAULT true NOT NULL,
    currency character varying(3) DEFAULT 'INR'::character varying NOT NULL,
    notes text,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT platform_commission_config_check CHECK (((min_pct <= default_pct) AND (default_pct <= max_pct))),
    CONSTRAINT platform_commission_config_default_pct_check CHECK (((default_pct >= (0)::numeric) AND (default_pct <= (100)::numeric))),
    CONSTRAINT platform_commission_config_invoice_due_days_check CHECK ((invoice_due_days >= 0)),
    CONSTRAINT platform_commission_config_max_pct_check CHECK ((max_pct <= (100)::numeric)),
    CONSTRAINT platform_commission_config_min_pct_check CHECK ((min_pct >= (0)::numeric)),
    CONSTRAINT platform_commission_config_monthly_invoice_day_check CHECK (((monthly_invoice_day >= 1) AND (monthly_invoice_day <= 28))),
    CONSTRAINT platform_commission_config_outstanding_invoice_threshold_check CHECK ((outstanding_invoice_threshold >= (0)::numeric))
);


--
-- Name: reason_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reason_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    category character varying(20) NOT NULL,
    code character varying(50) NOT NULL,
    label character varying(255) NOT NULL,
    description text,
    pricing_impact jsonb,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT reason_codes_category_check CHECK (((category)::text = ANY ((ARRAY['SUSPEND'::character varying, 'RESUME'::character varying, 'TERMINATE'::character varying])::text[])))
);


--
-- Name: states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.states (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(2) NOT NULL,
    name character varying(100) NOT NULL,
    iso_code character varying(3),
    is_union_territory boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: super_admin_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.super_admin_users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    full_name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    phone character varying(20),
    role character varying(30) DEFAULT 'SUPER_ADMIN'::character varying NOT NULL,
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    mfa_enabled boolean DEFAULT false NOT NULL,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT super_admin_users_role_check CHECK (((role)::text = ANY ((ARRAY['SUPER_ADMIN'::character varying, 'READ_ONLY'::character varying, 'OPS_AGENT'::character varying])::text[]))),
    CONSTRAINT super_admin_users_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying])::text[])))
);


--
-- Name: user_access_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_access_actions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    target_type character varying(20) NOT NULL,
    sub_admin_id uuid,
    action character varying(30) NOT NULL,
    reason text,
    metadata jsonb,
    performed_by uuid,
    performed_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT user_access_actions_action_check CHECK (((action)::text = ANY ((ARRAY['DISABLE'::character varying, 'ENABLE'::character varying, 'RESET_PASSWORD'::character varying, 'UPDATE_CONTACT'::character varying, 'UPDATE_EMAIL'::character varying])::text[]))),
    CONSTRAINT user_access_actions_target_type_check CHECK (((target_type)::text = ANY ((ARRAY['SALON_ADMIN'::character varying, 'SUB_ADMIN'::character varying])::text[])))
);


--
-- Name: review_abuse_rules; Type: TABLE; Schema: review; Owner: -
--

CREATE TABLE review.review_abuse_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(50) NOT NULL,
    label character varying(255) NOT NULL,
    description text,
    condition jsonb DEFAULT '{}'::jsonb NOT NULL,
    action character varying(20) DEFAULT 'QUEUE'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT review_abuse_rules_action_check CHECK (((action)::text = ANY ((ARRAY['QUEUE'::character varying, 'AUTO_HIDE'::character varying, 'REJECT_UPLOAD'::character varying])::text[])))
);


--
-- Name: review_images; Type: TABLE; Schema: review; Owner: -
--

CREATE TABLE review.review_images (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    review_id uuid NOT NULL,
    storage_url text NOT NULL,
    file_name character varying(255),
    mime_type character varying(100) NOT NULL,
    file_size_bytes bigint NOT NULL,
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT review_images_file_size_bytes_check CHECK ((file_size_bytes > 0)),
    CONSTRAINT review_images_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'REMOVED'::character varying])::text[])))
);


--
-- Name: review_moderation_actions; Type: TABLE; Schema: review; Owner: -
--

CREATE TABLE review.review_moderation_actions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    review_id uuid NOT NULL,
    reply_id uuid,
    image_id uuid,
    action character varying(30) NOT NULL,
    reason text,
    metadata jsonb,
    performed_by uuid,
    performed_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT review_moderation_actions_action_check CHECK (((action)::text = ANY ((ARRAY['AUTO_APPROVE'::character varying, 'APPROVE'::character varying, 'REJECT'::character varying, 'HIDE'::character varying, 'RESTORE'::character varying, 'HIDE_IMAGE'::character varying, 'RESTORE_IMAGE'::character varying, 'HIDE_REPLY'::character varying, 'RESTORE_REPLY'::character varying])::text[])))
);


--
-- Name: review_moderation_settings; Type: TABLE; Schema: review; Owner: -
--

CREATE TABLE review.review_moderation_settings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    max_image_size_mb numeric(6,2) DEFAULT 5.00 NOT NULL,
    max_images_per_review integer DEFAULT 3 NOT NULL,
    allowed_mime_types text[] DEFAULT ARRAY['image/jpeg'::text, 'image/png'::text, 'image/webp'::text] NOT NULL,
    edit_window_days integer DEFAULT 7 NOT NULL,
    auto_publish_high_rating boolean DEFAULT true NOT NULL,
    auto_publish_min_rating integer DEFAULT 4 NOT NULL,
    auto_publish_requires_no_text boolean DEFAULT true CONSTRAINT review_moderation_settings_auto_publish_requires_no_te_not_null NOT NULL,
    auto_publish_requires_no_image boolean DEFAULT true CONSTRAINT review_moderation_settings_auto_publish_requires_no_im_not_null NOT NULL,
    queue_if_has_image boolean DEFAULT true NOT NULL,
    queue_if_has_url_or_phone boolean DEFAULT true NOT NULL,
    max_reviews_per_user_per_day integer DEFAULT 10 CONSTRAINT review_moderation_settings_max_reviews_per_user_per_da_not_null NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT review_moderation_settings_auto_publish_min_rating_check CHECK (((auto_publish_min_rating >= 1) AND (auto_publish_min_rating <= 5))),
    CONSTRAINT review_moderation_settings_edit_window_days_check CHECK ((edit_window_days >= 0)),
    CONSTRAINT review_moderation_settings_max_image_size_mb_check CHECK ((max_image_size_mb > (0)::numeric)),
    CONSTRAINT review_moderation_settings_max_images_per_review_check CHECK (((max_images_per_review >= 0) AND (max_images_per_review <= 10))),
    CONSTRAINT review_moderation_settings_max_reviews_per_user_per_day_check CHECK ((max_reviews_per_user_per_day > 0))
);


--
-- Name: review_replies; Type: TABLE; Schema: review; Owner: -
--

CREATE TABLE review.review_replies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    review_id uuid NOT NULL,
    organization_id uuid NOT NULL,
    body text NOT NULL,
    status character varying(20) DEFAULT 'PUBLISHED'::character varying NOT NULL,
    replied_by_ref character varying(100),
    replied_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT review_replies_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'PUBLISHED'::character varying, 'HIDDEN'::character varying])::text[])))
);


--
-- Name: review_reports; Type: TABLE; Schema: review; Owner: -
--

CREATE TABLE review.review_reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    review_id uuid NOT NULL,
    reply_id uuid,
    reporter_type character varying(20) NOT NULL,
    reporter_ref character varying(100),
    reason_code character varying(40) NOT NULL,
    notes text,
    status character varying(20) DEFAULT 'OPEN'::character varying NOT NULL,
    resolved_by uuid,
    resolved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT review_reports_reason_code_check CHECK (((reason_code)::text = ANY ((ARRAY['SPAM'::character varying, 'ABUSE'::character varying, 'FAKE'::character varying, 'INAPPROPRIATE_IMAGE'::character varying, 'INAPPROPRIATE_TEXT'::character varying, 'OTHER'::character varying])::text[]))),
    CONSTRAINT review_reports_reporter_type_check CHECK (((reporter_type)::text = ANY ((ARRAY['END_USER'::character varying, 'SALON'::character varying, 'SYSTEM'::character varying])::text[]))),
    CONSTRAINT review_reports_status_check CHECK (((status)::text = ANY ((ARRAY['OPEN'::character varying, 'REVIEWED'::character varying, 'DISMISSED'::character varying])::text[])))
);


--
-- Name: reviews; Type: TABLE; Schema: review; Owner: -
--

CREATE TABLE review.reviews (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    booking_ref character varying(50) NOT NULL,
    end_user_ref character varying(50) NOT NULL,
    specialist_ref character varying(50),
    overall_rating integer NOT NULL,
    rating_service integer,
    rating_specialist integer,
    rating_cleanliness integer,
    rating_value integer,
    body text,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    matched_rule_codes text[] DEFAULT '{}'::text[] NOT NULL,
    submitted_at timestamp with time zone DEFAULT now() NOT NULL,
    edited_at timestamp with time zone,
    edit_deadline_at timestamp with time zone,
    published_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT reviews_overall_rating_check CHECK (((overall_rating >= 1) AND (overall_rating <= 5))),
    CONSTRAINT reviews_rating_cleanliness_check CHECK (((rating_cleanliness IS NULL) OR ((rating_cleanliness >= 1) AND (rating_cleanliness <= 5)))),
    CONSTRAINT reviews_rating_service_check CHECK (((rating_service IS NULL) OR ((rating_service >= 1) AND (rating_service <= 5)))),
    CONSTRAINT reviews_rating_specialist_check CHECK (((rating_specialist IS NULL) OR ((rating_specialist >= 1) AND (rating_specialist <= 5)))),
    CONSTRAINT reviews_rating_value_check CHECK (((rating_value IS NULL) OR ((rating_value >= 1) AND (rating_value <= 5)))),
    CONSTRAINT reviews_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'PUBLISHED'::character varying, 'HIDDEN'::character varying, 'REJECTED'::character varying])::text[])))
);


--
-- Name: billing_cycles; Type: TABLE; Schema: rms; Owner: -
--

CREATE TABLE rms.billing_cycles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(30) NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    interval_months integer NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT billing_cycles_interval_months_check CHECK ((interval_months > 0))
);


--
-- Name: billing_discount_configs; Type: TABLE; Schema: rms; Owner: -
--

CREATE TABLE rms.billing_discount_configs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    subscription_plan_id uuid,
    billing_cycle_id uuid,
    discount_type character varying(20) NOT NULL,
    discount_value numeric(12,2) NOT NULL,
    priority integer DEFAULT 100 NOT NULL,
    is_stackable boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    effective_from date DEFAULT CURRENT_DATE NOT NULL,
    effective_to date,
    notes text,
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT billing_discount_configs_check CHECK (((effective_to IS NULL) OR (effective_to >= effective_from))),
    CONSTRAINT billing_discount_configs_check1 CHECK (((((discount_type)::text = 'PERCENTAGE'::text) AND (discount_value <= (100)::numeric)) OR ((discount_type)::text = 'FIXED_AMOUNT'::text))),
    CONSTRAINT billing_discount_configs_check2 CHECK (((subscription_plan_id IS NOT NULL) OR (billing_cycle_id IS NOT NULL))),
    CONSTRAINT billing_discount_configs_discount_type_check CHECK (((discount_type)::text = ANY ((ARRAY['PERCENTAGE'::character varying, 'FIXED_AMOUNT'::character varying])::text[]))),
    CONSTRAINT billing_discount_configs_discount_value_check CHECK ((discount_value > (0)::numeric))
);


--
-- Name: commission_rate_history; Type: TABLE; Schema: rms; Owner: -
--

CREATE TABLE rms.commission_rate_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    previous_pct numeric(5,2),
    new_pct numeric(5,2) NOT NULL,
    effective_from timestamp with time zone DEFAULT now() NOT NULL,
    reason text,
    changed_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT commission_rate_history_new_pct_check CHECK (((new_pct >= (0)::numeric) AND (new_pct <= (100)::numeric)))
);


--
-- Name: credit_note_line_items; Type: TABLE; Schema: rms; Owner: -
--

CREATE TABLE rms.credit_note_line_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    credit_note_id uuid NOT NULL,
    invoice_line_item_id uuid,
    description character varying(255) NOT NULL,
    amount numeric(12,2) DEFAULT 0 NOT NULL,
    tax_amount numeric(12,2) DEFAULT 0 NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT credit_note_line_items_tax_amount_check CHECK ((tax_amount >= (0)::numeric))
);


--
-- Name: credit_notes; Type: TABLE; Schema: rms; Owner: -
--

CREATE TABLE rms.credit_notes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_id uuid NOT NULL,
    credit_note_number character varying(50) NOT NULL,
    status character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    reason text,
    subtotal_amount numeric(12,2) DEFAULT 0 NOT NULL,
    tax_amount numeric(12,2) DEFAULT 0 NOT NULL,
    total_amount numeric(12,2) DEFAULT 0 NOT NULL,
    pdf_url text,
    issued_at timestamp with time zone,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    settlement_method character varying(30) NOT NULL,
    applied_to_invoice_id uuid,
    settled_at timestamp with time zone,
    CONSTRAINT credit_notes_settlement_method_check CHECK (((settlement_method)::text = ANY ((ARRAY['REFUND'::character varying, 'APPLY_NEXT_INVOICE'::character varying, 'MANUAL'::character varying])::text[]))),
    CONSTRAINT credit_notes_status_check CHECK (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'ISSUED'::character varying, 'VOID'::character varying])::text[]))),
    CONSTRAINT credit_notes_subtotal_amount_check CHECK ((subtotal_amount >= (0)::numeric)),
    CONSTRAINT credit_notes_tax_amount_check CHECK ((tax_amount >= (0)::numeric)),
    CONSTRAINT credit_notes_total_amount_check CHECK ((total_amount >= (0)::numeric))
);


--
-- Name: end_user_transactions; Type: TABLE; Schema: rms; Owner: -
--

CREATE TABLE rms.end_user_transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    transaction_ref character varying(50) NOT NULL,
    organization_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    booking_ref character varying(50),
    end_user_ref character varying(50),
    payment_channel character varying(20) NOT NULL,
    collection_model character varying(20) NOT NULL,
    gross_amount numeric(12,2) NOT NULL,
    commission_pct numeric(5,2) NOT NULL,
    commission_amount numeric(12,2) NOT NULL,
    gateway_fee_amount numeric(12,2) DEFAULT 0 NOT NULL,
    net_to_salon numeric(12,2) NOT NULL,
    currency character varying(3) DEFAULT 'INR'::character varying NOT NULL,
    payment_method character varying(30) NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    gateway character varying(30),
    gateway_order_id character varying(100),
    gateway_payment_id character varying(100),
    gateway_ref character varying(255),
    failure_code character varying(50),
    failure_message text,
    service_details jsonb,
    outstanding_recovered numeric(12,2) DEFAULT 0 NOT NULL,
    salon_payout_id uuid,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT end_user_transactions_check CHECK (((((collection_model)::text = 'MARKETPLACE'::text) AND ((payment_channel)::text = 'ONLINE'::text)) OR (((collection_model)::text = 'MERCHANT'::text) AND ((payment_channel)::text <> 'ONLINE'::text)) OR ((payment_channel)::text = 'OTHER'::text))),
    CONSTRAINT end_user_transactions_collection_model_check CHECK (((collection_model)::text = ANY ((ARRAY['MARKETPLACE'::character varying, 'MERCHANT'::character varying])::text[]))),
    CONSTRAINT end_user_transactions_commission_amount_check CHECK ((commission_amount >= (0)::numeric)),
    CONSTRAINT end_user_transactions_commission_pct_check CHECK (((commission_pct >= (0)::numeric) AND (commission_pct <= (100)::numeric))),
    CONSTRAINT end_user_transactions_gateway_check CHECK (((gateway IS NULL) OR ((gateway)::text = ANY ((ARRAY['RAZORPAY'::character varying, 'STRIPE'::character varying, 'CASHFREE'::character varying, 'MANUAL'::character varying, 'OTHER'::character varying])::text[])))),
    CONSTRAINT end_user_transactions_gateway_fee_amount_check CHECK ((gateway_fee_amount >= (0)::numeric)),
    CONSTRAINT end_user_transactions_gross_amount_check CHECK ((gross_amount > (0)::numeric)),
    CONSTRAINT end_user_transactions_outstanding_recovered_check CHECK ((outstanding_recovered >= (0)::numeric)),
    CONSTRAINT end_user_transactions_payment_channel_check CHECK (((payment_channel)::text = ANY ((ARRAY['ONLINE'::character varying, 'CASH'::character varying, 'UPI_AT_SALON'::character varying, 'CARD_AT_SALON'::character varying, 'OTHER'::character varying])::text[]))),
    CONSTRAINT end_user_transactions_payment_method_check CHECK (((payment_method)::text = ANY ((ARRAY['UPI'::character varying, 'CARD'::character varying, 'NET_BANKING'::character varying, 'WALLET'::character varying, 'NACH'::character varying, 'CASH'::character varying, 'UPI_AT_SALON'::character varying, 'CARD_AT_SALON'::character varying, 'OTHER'::character varying])::text[]))),
    CONSTRAINT end_user_transactions_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'SUCCESS'::character varying, 'FAILED'::character varying, 'REFUNDED'::character varying, 'PARTIALLY_REFUNDED'::character varying, 'DISPUTED'::character varying, 'CANCELLED'::character varying])::text[])))
);


--
-- Name: invoice_line_items; Type: TABLE; Schema: rms; Owner: -
--

CREATE TABLE rms.invoice_line_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_id uuid NOT NULL,
    line_type character varying(20) NOT NULL,
    description character varying(255) NOT NULL,
    subscription_plan_id uuid,
    billing_cycle_id uuid,
    quantity numeric(12,2) DEFAULT 1 NOT NULL,
    unit_amount numeric(12,2) DEFAULT 0 NOT NULL,
    amount numeric(12,2) DEFAULT 0 NOT NULL,
    discount_amount numeric(12,2) DEFAULT 0 NOT NULL,
    taxable_amount numeric(12,2) DEFAULT 0 NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT invoice_line_items_discount_amount_check CHECK ((discount_amount >= (0)::numeric)),
    CONSTRAINT invoice_line_items_line_type_check CHECK (((line_type)::text = ANY ((ARRAY['PLAN'::character varying, 'DISCOUNT'::character varying, 'PRORATION'::character varying, 'FEE'::character varying, 'CREDIT'::character varying, 'TAX'::character varying, 'ADJUSTMENT'::character varying])::text[]))),
    CONSTRAINT invoice_line_items_quantity_check CHECK ((quantity > (0)::numeric))
);


--
-- Name: invoice_payments; Type: TABLE; Schema: rms; Owner: -
--

CREATE TABLE rms.invoice_payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_id uuid NOT NULL,
    payment_id uuid NOT NULL,
    amount_applied numeric(12,2) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT invoice_payments_amount_applied_check CHECK ((amount_applied > (0)::numeric))
);


--
-- Name: invoice_tax_lines; Type: TABLE; Schema: rms; Owner: -
--

CREATE TABLE rms.invoice_tax_lines (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_line_item_id uuid NOT NULL,
    state_tax_config_id uuid NOT NULL,
    taxable_amount numeric(12,2) NOT NULL,
    tax_amount numeric(12,2) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT invoice_tax_lines_tax_amount_check CHECK ((tax_amount >= (0)::numeric)),
    CONSTRAINT invoice_tax_lines_taxable_amount_check CHECK ((taxable_amount >= (0)::numeric))
);


--
-- Name: invoices; Type: TABLE; Schema: rms; Owner: -
--

CREATE TABLE rms.invoices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    org_bill_structure_id uuid,
    invoice_number character varying(50) NOT NULL,
    invoice_type character varying(20) NOT NULL,
    status character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    currency character varying(3) DEFAULT 'INR'::character varying NOT NULL,
    subtotal_amount numeric(12,2) DEFAULT 0 NOT NULL,
    discount_amount numeric(12,2) DEFAULT 0 NOT NULL,
    taxable_amount numeric(12,2) DEFAULT 0 NOT NULL,
    tax_amount numeric(12,2) DEFAULT 0 NOT NULL,
    total_amount numeric(12,2) DEFAULT 0 NOT NULL,
    amount_paid numeric(12,2) DEFAULT 0 NOT NULL,
    amount_due numeric(12,2) DEFAULT 0 NOT NULL,
    billing_period_start date,
    billing_period_end date,
    issue_date date DEFAULT CURRENT_DATE NOT NULL,
    due_date date,
    paid_at timestamp with time zone,
    pdf_url text,
    notes text,
    org_subscription_change_id uuid,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT invoices_amount_due_check CHECK ((amount_due >= (0)::numeric)),
    CONSTRAINT invoices_amount_paid_check CHECK ((amount_paid >= (0)::numeric)),
    CONSTRAINT invoices_check CHECK ((((amount_paid + amount_due) = total_amount) OR ((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'VOID'::character varying])::text[])))),
    CONSTRAINT invoices_discount_amount_check CHECK ((discount_amount >= (0)::numeric)),
    CONSTRAINT invoices_invoice_type_check CHECK (((invoice_type)::text = ANY ((ARRAY['PURCHASE'::character varying, 'RENEWAL'::character varying, 'UPGRADE'::character varying, 'DOWNGRADE'::character varying, 'CREDIT'::character varying, 'MANUAL'::character varying, 'ADJUSTMENT'::character varying, 'COMMISSION'::character varying])::text[]))),
    CONSTRAINT invoices_status_check CHECK (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'OPEN'::character varying, 'PAID'::character varying, 'PARTIALLY_PAID'::character varying, 'VOID'::character varying, 'UNCOLLECTIBLE'::character varying])::text[]))),
    CONSTRAINT invoices_subtotal_amount_check CHECK ((subtotal_amount >= (0)::numeric)),
    CONSTRAINT invoices_tax_amount_check CHECK ((tax_amount >= (0)::numeric)),
    CONSTRAINT invoices_taxable_amount_check CHECK ((taxable_amount >= (0)::numeric)),
    CONSTRAINT invoices_total_amount_check CHECK ((total_amount >= (0)::numeric))
);


--
-- Name: merchant_ledger_entries; Type: TABLE; Schema: rms; Owner: -
--

CREATE TABLE rms.merchant_ledger_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    balance_bucket character varying(20) NOT NULL,
    direction character varying(10) NOT NULL,
    entry_type character varying(30) NOT NULL,
    amount numeric(12,2) NOT NULL,
    balance_after numeric(12,2) NOT NULL,
    currency character varying(3) DEFAULT 'INR'::character varying NOT NULL,
    end_user_transaction_id uuid,
    salon_payout_id uuid,
    invoice_id uuid,
    payment_id uuid,
    description text,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT merchant_ledger_entries_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT merchant_ledger_entries_balance_after_check CHECK ((balance_after >= (0)::numeric)),
    CONSTRAINT merchant_ledger_entries_balance_bucket_check CHECK (((balance_bucket)::text = ANY ((ARRAY['OUTSTANDING'::character varying, 'PAYABLE'::character varying])::text[]))),
    CONSTRAINT merchant_ledger_entries_direction_check CHECK (((direction)::text = ANY ((ARRAY['INCREASE'::character varying, 'DECREASE'::character varying])::text[]))),
    CONSTRAINT merchant_ledger_entries_entry_type_check CHECK (((entry_type)::text = ANY ((ARRAY['COMMISSION_ACCRUAL'::character varying, 'OUTSTANDING_RECOVERY'::character varying, 'COMMISSION_INVOICE'::character varying, 'COMMISSION_PAYMENT'::character varying, 'PAYABLE_ACCRUAL'::character varying, 'PAYOUT'::character varying, 'REFUND_REVERSAL'::character varying, 'DISPUTE_HOLD'::character varying, 'ADJUSTMENT'::character varying])::text[])))
);


--
-- Name: org_bill_structure; Type: TABLE; Schema: rms; Owner: -
--

CREATE TABLE rms.org_bill_structure (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    subscription_plan_id uuid NOT NULL,
    billing_cycle_id uuid NOT NULL,
    start_date date NOT NULL,
    renewal_date date NOT NULL,
    payment_method character varying(30) NOT NULL,
    commission_pct numeric(5,2) DEFAULT 5.00 NOT NULL,
    platform_fee_amount numeric(12,2),
    currency character varying(3) DEFAULT 'INR'::character varying NOT NULL,
    auto_renew boolean DEFAULT true NOT NULL,
    grace_period_days integer DEFAULT 7 NOT NULL,
    last_payment_at timestamp with time zone,
    payment_reference character varying(100),
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    notes text,
    configured_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    state_id uuid,
    free_usage_days integer DEFAULT 0 NOT NULL,
    CONSTRAINT org_bill_structure_check CHECK ((renewal_date >= start_date)),
    CONSTRAINT org_bill_structure_free_usage_days_check CHECK ((free_usage_days >= 0)),
    CONSTRAINT org_bill_structure_grace_period_days_check CHECK ((grace_period_days >= 0)),
    CONSTRAINT org_bill_structure_payment_method_check CHECK (((payment_method)::text = ANY ((ARRAY['BANK_TRANSFER'::character varying, 'UPI'::character varying, 'CARD'::character varying, 'NET_BANKING'::character varying, 'NACH'::character varying, 'CHEQUE'::character varying, 'OTHER'::character varying])::text[]))),
    CONSTRAINT org_bill_structure_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'ACTIVE'::character varying, 'SUSPENDED'::character varying, 'CANCELLED'::character varying, 'EXPIRED'::character varying])::text[])))
);


--
-- Name: org_merchant_balances; Type: TABLE; Schema: rms; Owner: -
--

CREATE TABLE rms.org_merchant_balances (
    organization_id uuid NOT NULL,
    outstanding_amount numeric(12,2) DEFAULT 0 NOT NULL,
    pending_payout_amount numeric(12,2) DEFAULT 0 NOT NULL,
    currency character varying(3) DEFAULT 'INR'::character varying NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT org_merchant_balances_outstanding_amount_check CHECK ((outstanding_amount >= (0)::numeric)),
    CONSTRAINT org_merchant_balances_pending_payout_amount_check CHECK ((pending_payout_amount >= (0)::numeric))
);


--
-- Name: payments; Type: TABLE; Schema: rms; Owner: -
--

CREATE TABLE rms.payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    payment_number character varying(50) NOT NULL,
    amount numeric(12,2) NOT NULL,
    currency character varying(3) DEFAULT 'INR'::character varying NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    payment_method character varying(30) NOT NULL,
    gateway character varying(30) DEFAULT 'MANUAL'::character varying NOT NULL,
    gateway_order_id character varying(100),
    gateway_payment_id character varying(100),
    gateway_ref character varying(255),
    failure_code character varying(50),
    failure_message text,
    initiated_at timestamp with time zone DEFAULT now() NOT NULL,
    paid_at timestamp with time zone,
    notes text,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT payments_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT payments_gateway_check CHECK (((gateway)::text = ANY ((ARRAY['RAZORPAY'::character varying, 'STRIPE'::character varying, 'CASHFREE'::character varying, 'MANUAL'::character varying, 'OTHER'::character varying])::text[]))),
    CONSTRAINT payments_payment_method_check CHECK (((payment_method)::text = ANY ((ARRAY['NACH'::character varying, 'UPI'::character varying, 'CARD'::character varying, 'NET_BANKING'::character varying, 'BANK_TRANSFER'::character varying, 'CHEQUE'::character varying, 'OTHER'::character varying])::text[]))),
    CONSTRAINT payments_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'PROCESSING'::character varying, 'SUCCEEDED'::character varying, 'FAILED'::character varying, 'CANCELLED'::character varying, 'REFUNDED'::character varying, 'PARTIALLY_REFUNDED'::character varying])::text[])))
);


--
-- Name: refunds; Type: TABLE; Schema: rms; Owner: -
--

CREATE TABLE rms.refunds (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    payment_id uuid NOT NULL,
    credit_note_id uuid,
    amount numeric(12,2) NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    gateway_refund_id character varying(100),
    reason text,
    refunded_at timestamp with time zone,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT refunds_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT refunds_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'SUCCEEDED'::character varying, 'FAILED'::character varying, 'CANCELLED'::character varying])::text[])))
);


--
-- Name: salon_payout_items; Type: TABLE; Schema: rms; Owner: -
--

CREATE TABLE rms.salon_payout_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    payout_id uuid NOT NULL,
    end_user_transaction_id uuid,
    item_type character varying(30) NOT NULL,
    amount numeric(12,2) NOT NULL,
    description character varying(255),
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT salon_payout_items_item_type_check CHECK (((item_type)::text = ANY ((ARRAY['BOOKING_GROSS'::character varying, 'COMMISSION'::character varying, 'GATEWAY_FEE'::character varying, 'OUTSTANDING_RECOVERY'::character varying, 'ADJUSTMENT'::character varying, 'NET_TRANSFER'::character varying])::text[])))
);


--
-- Name: salon_payouts; Type: TABLE; Schema: rms; Owner: -
--

CREATE TABLE rms.salon_payouts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    payout_number character varying(50) NOT NULL,
    organization_id uuid NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    currency character varying(3) DEFAULT 'INR'::character varying NOT NULL,
    gross_collected numeric(12,2) DEFAULT 0 NOT NULL,
    commission_deducted numeric(12,2) DEFAULT 0 NOT NULL,
    gateway_fees_deducted numeric(12,2) DEFAULT 0 NOT NULL,
    outstanding_recovered numeric(12,2) DEFAULT 0 NOT NULL,
    net_payout_amount numeric(12,2) DEFAULT 0 NOT NULL,
    gateway character varying(30),
    gateway_payout_id character varying(100),
    gateway_ref character varying(255),
    period_start timestamp with time zone,
    period_end timestamp with time zone,
    paid_at timestamp with time zone,
    failure_message text,
    notes text,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT salon_payouts_commission_deducted_check CHECK ((commission_deducted >= (0)::numeric)),
    CONSTRAINT salon_payouts_gateway_check CHECK (((gateway IS NULL) OR ((gateway)::text = ANY ((ARRAY['RAZORPAY'::character varying, 'STRIPE'::character varying, 'CASHFREE'::character varying, 'MANUAL'::character varying, 'OTHER'::character varying])::text[])))),
    CONSTRAINT salon_payouts_gateway_fees_deducted_check CHECK ((gateway_fees_deducted >= (0)::numeric)),
    CONSTRAINT salon_payouts_gross_collected_check CHECK ((gross_collected >= (0)::numeric)),
    CONSTRAINT salon_payouts_net_payout_amount_check CHECK ((net_payout_amount >= (0)::numeric)),
    CONSTRAINT salon_payouts_outstanding_recovered_check CHECK ((outstanding_recovered >= (0)::numeric)),
    CONSTRAINT salon_payouts_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'PROCESSING'::character varying, 'PAID'::character varying, 'FAILED'::character varying, 'CANCELLED'::character varying])::text[])))
);


--
-- Name: state_tax_configs; Type: TABLE; Schema: rms; Owner: -
--

CREATE TABLE rms.state_tax_configs (
    id uuid DEFAULT gen_random_uuid() CONSTRAINT state_tax_configs_id_not_null1 NOT NULL,
    state_id uuid CONSTRAINT state_tax_configs_state_id_not_null1 NOT NULL,
    tax_code character varying(30) CONSTRAINT state_tax_configs_tax_code_not_null1 NOT NULL,
    tax_name character varying(100) CONSTRAINT state_tax_configs_tax_name_not_null1 NOT NULL,
    rate_pct numeric(5,2) CONSTRAINT state_tax_configs_rate_pct_not_null1 NOT NULL,
    hsn_sac_code character varying(10),
    component_type character varying(20) CONSTRAINT state_tax_configs_component_type_not_null1 NOT NULL,
    applies_to character varying(20) DEFAULT 'SERVICE'::character varying CONSTRAINT state_tax_configs_applies_to_not_null1 NOT NULL,
    effective_from date DEFAULT CURRENT_DATE CONSTRAINT state_tax_configs_effective_from_not_null1 NOT NULL,
    effective_to date,
    is_active boolean DEFAULT true CONSTRAINT state_tax_configs_is_active_not_null1 NOT NULL,
    notes text,
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() CONSTRAINT state_tax_configs_created_at_not_null1 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() CONSTRAINT state_tax_configs_updated_at_not_null1 NOT NULL,
    CONSTRAINT state_tax_configs_applies_to_check CHECK (((applies_to)::text = ANY ((ARRAY['SERVICE'::character varying, 'PRODUCT'::character varying, 'BOTH'::character varying])::text[]))),
    CONSTRAINT state_tax_configs_check CHECK (((effective_to IS NULL) OR (effective_to >= effective_from))),
    CONSTRAINT state_tax_configs_component_type_check CHECK (((component_type)::text = ANY ((ARRAY['CGST'::character varying, 'SGST'::character varying, 'IGST'::character varying, 'CESS'::character varying, 'COMPOSITE'::character varying])::text[]))),
    CONSTRAINT state_tax_configs_rate_pct_check CHECK (((rate_pct >= (0)::numeric) AND (rate_pct <= (100)::numeric)))
);


--
-- Name: branch_service_specialists; Type: TABLE; Schema: services; Owner: -
--

CREATE TABLE services.branch_service_specialists (
    branch_service_id uuid NOT NULL,
    employee_id uuid NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: branch_services; Type: TABLE; Schema: services; Owner: -
--

CREATE TABLE services.branch_services (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    category_id uuid NOT NULL,
    subcategory_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    price numeric(12,2) NOT NULL,
    currency character varying(3) DEFAULT 'INR'::character varying NOT NULL,
    duration_minutes integer NOT NULL,
    photo_url text,
    offline_payment_allowed boolean DEFAULT true NOT NULL,
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    discount_amount numeric(12,2),
    discount_percent numeric(5,2),
    discount_description text,
    CONSTRAINT branch_services_discount_amount_check CHECK (((discount_amount IS NULL) OR (discount_amount >= (0)::numeric))),
    CONSTRAINT branch_services_discount_one_mode CHECK (((discount_amount IS NULL) OR (discount_percent IS NULL))),
    CONSTRAINT branch_services_discount_percent_check CHECK (((discount_percent IS NULL) OR ((discount_percent >= (0)::numeric) AND (discount_percent <= (100)::numeric)))),
    CONSTRAINT branch_services_duration_minutes_check CHECK ((duration_minutes > 0)),
    CONSTRAINT branch_services_price_check CHECK ((price >= (0)::numeric)),
    CONSTRAINT branch_services_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying])::text[])))
);


--
-- Name: service_categories; Type: TABLE; Schema: services; Owner: -
--

CREATE TABLE services.service_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    icon_url text,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_single_level boolean DEFAULT false NOT NULL,
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: service_subcategories; Type: TABLE; Schema: services; Owner: -
--

CREATE TABLE services.service_subcategories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    category_id uuid NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    icon_url text,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    mirrors_category boolean DEFAULT false NOT NULL,
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: org_subscription_changes; Type: TABLE; Schema: subscription; Owner: -
--

CREATE TABLE subscription.org_subscription_changes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    org_bill_structure_id uuid NOT NULL,
    change_type character varying(20) NOT NULL,
    from_subscription_plan_id uuid NOT NULL,
    to_subscription_plan_id uuid NOT NULL,
    from_billing_cycle_id uuid,
    to_billing_cycle_id uuid,
    effective_date date DEFAULT CURRENT_DATE NOT NULL,
    notes text,
    performed_by uuid,
    performed_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT org_subscription_changes_change_type_check CHECK (((change_type)::text = ANY ((ARRAY['UPGRADE'::character varying, 'DOWNGRADE'::character varying])::text[]))),
    CONSTRAINT org_subscription_changes_check CHECK ((from_subscription_plan_id <> to_subscription_plan_id))
);


--
-- Name: subscription_plans; Type: TABLE; Schema: subscription; Owner: -
--

CREATE TABLE subscription.subscription_plans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    max_branches integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    amount numeric(12,2) DEFAULT 0 NOT NULL,
    CONSTRAINT subscription_plans_amount_check CHECK ((amount >= (0)::numeric))
);


--
-- Name: support_sla_policies; Type: TABLE; Schema: tickets; Owner: -
--

CREATE TABLE tickets.support_sla_policies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    priority character varying(20) NOT NULL,
    first_response_minutes integer NOT NULL,
    resolve_minutes integer NOT NULL,
    business_hours_only boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT support_sla_policies_first_response_minutes_check CHECK ((first_response_minutes > 0)),
    CONSTRAINT support_sla_policies_priority_check CHECK (((priority)::text = ANY ((ARRAY['LOW'::character varying, 'MEDIUM'::character varying, 'HIGH'::character varying, 'CRITICAL'::character varying])::text[]))),
    CONSTRAINT support_sla_policies_resolve_minutes_check CHECK ((resolve_minutes > 0))
);


--
-- Name: support_ticket_attachments; Type: TABLE; Schema: tickets; Owner: -
--

CREATE TABLE tickets.support_ticket_attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_id uuid NOT NULL,
    message_id uuid,
    file_name character varying(255) NOT NULL,
    storage_url text NOT NULL,
    mime_type character varying(100),
    file_size_bytes bigint,
    uploaded_by_type character varying(20) NOT NULL,
    uploaded_by_ref character varying(100),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT support_ticket_attachments_uploaded_by_type_check CHECK (((uploaded_by_type)::text = ANY ((ARRAY['SALON'::character varying, 'END_USER'::character varying, 'AGENT'::character varying])::text[])))
);


--
-- Name: support_ticket_categories; Type: TABLE; Schema: tickets; Owner: -
--

CREATE TABLE tickets.support_ticket_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(50) NOT NULL,
    label character varying(255) NOT NULL,
    description text,
    audience character varying(20) DEFAULT 'BOTH'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_by uuid,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT support_ticket_categories_audience_check CHECK (((audience)::text = ANY ((ARRAY['SALON'::character varying, 'END_USER'::character varying, 'BOTH'::character varying])::text[])))
);


--
-- Name: support_ticket_events; Type: TABLE; Schema: tickets; Owner: -
--

CREATE TABLE tickets.support_ticket_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_id uuid NOT NULL,
    event_type character varying(30) NOT NULL,
    from_value character varying(100),
    to_value character varying(100),
    note text,
    performed_by uuid,
    performed_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT support_ticket_events_event_type_check CHECK (((event_type)::text = ANY ((ARRAY['CREATED'::character varying, 'STATUS_CHANGE'::character varying, 'ASSIGNED'::character varying, 'PRIORITY_CHANGE'::character varying, 'REOPENED'::character varying, 'SLA_BREACH'::character varying, 'CSAT_SUBMITTED'::character varying, 'NOTE_ADDED'::character varying])::text[])))
);


--
-- Name: support_ticket_internal_notes; Type: TABLE; Schema: tickets; Owner: -
--

CREATE TABLE tickets.support_ticket_internal_notes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_id uuid NOT NULL,
    body text NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: support_ticket_messages; Type: TABLE; Schema: tickets; Owner: -
--

CREATE TABLE tickets.support_ticket_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_id uuid NOT NULL,
    author_type character varying(20) NOT NULL,
    author_ref character varying(100),
    author_super_admin_id uuid,
    body text NOT NULL,
    is_first_response boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT support_ticket_messages_author_type_check CHECK (((author_type)::text = ANY ((ARRAY['SALON'::character varying, 'END_USER'::character varying, 'AGENT'::character varying, 'SYSTEM'::character varying])::text[])))
);


--
-- Name: support_ticket_subtypes; Type: TABLE; Schema: tickets; Owner: -
--

CREATE TABLE tickets.support_ticket_subtypes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type_id uuid NOT NULL,
    code character varying(50) NOT NULL,
    label character varying(255) NOT NULL,
    description text,
    default_priority character varying(20) DEFAULT 'MEDIUM'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT support_ticket_subtypes_default_priority_check CHECK (((default_priority)::text = ANY ((ARRAY['LOW'::character varying, 'MEDIUM'::character varying, 'HIGH'::character varying, 'CRITICAL'::character varying])::text[])))
);


--
-- Name: support_ticket_types; Type: TABLE; Schema: tickets; Owner: -
--

CREATE TABLE tickets.support_ticket_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    category_id uuid NOT NULL,
    code character varying(50) NOT NULL,
    label character varying(255) NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: support_tickets; Type: TABLE; Schema: tickets; Owner: -
--

CREATE TABLE tickets.support_tickets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_number character varying(30) NOT NULL,
    source character varying(20) NOT NULL,
    organization_id uuid,
    branch_id uuid,
    end_user_ref character varying(50),
    booking_ref character varying(50),
    requester_name character varying(255),
    requester_email character varying(255),
    requester_phone character varying(20),
    category_id uuid NOT NULL,
    type_id uuid NOT NULL,
    subtype_id uuid,
    subject character varying(255) NOT NULL,
    description text NOT NULL,
    priority character varying(20) DEFAULT 'MEDIUM'::character varying NOT NULL,
    status character varying(30) DEFAULT 'CREATED'::character varying NOT NULL,
    assigned_to uuid,
    sla_policy_id uuid,
    first_response_due_at timestamp with time zone,
    resolve_due_at timestamp with time zone,
    first_responded_at timestamp with time zone,
    resolved_at timestamp with time zone,
    closed_at timestamp with time zone,
    resolution_notes text,
    csat_score integer,
    csat_comment text,
    created_by_super_admin_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT support_tickets_csat_score_check CHECK (((csat_score IS NULL) OR ((csat_score >= 1) AND (csat_score <= 5)))),
    CONSTRAINT support_tickets_priority_check CHECK (((priority)::text = ANY ((ARRAY['LOW'::character varying, 'MEDIUM'::character varying, 'HIGH'::character varying, 'CRITICAL'::character varying])::text[]))),
    CONSTRAINT support_tickets_source_check CHECK (((source)::text = ANY ((ARRAY['SALON'::character varying, 'END_USER'::character varying, 'SUPER_ADMIN'::character varying, 'SYSTEM'::character varying])::text[]))),
    CONSTRAINT support_tickets_status_check CHECK (((status)::text = ANY ((ARRAY['CREATED'::character varying, 'IN_PROGRESS'::character varying, 'ON_HOLD'::character varying, 'AWAITING_USER'::character varying, 'RESOLVED'::character varying, 'CLOSED'::character varying, 'REOPENED'::character varying])::text[])))
);


--
-- Name: sub_admin_branches sub_admin_branches_pkey; Type: CONSTRAINT; Schema: admin_org; Owner: -
--

ALTER TABLE ONLY admin_org.sub_admin_branches
    ADD CONSTRAINT sub_admin_branches_pkey PRIMARY KEY (sub_admin_id, branch_id);


--
-- Name: sub_admin_modules sub_admin_modules_pkey; Type: CONSTRAINT; Schema: admin_org; Owner: -
--

ALTER TABLE ONLY admin_org.sub_admin_modules
    ADD CONSTRAINT sub_admin_modules_pkey PRIMARY KEY (sub_admin_id, module);


--
-- Name: sub_admins sub_admins_organization_id_email_key; Type: CONSTRAINT; Schema: admin_org; Owner: -
--

ALTER TABLE ONLY admin_org.sub_admins
    ADD CONSTRAINT sub_admins_organization_id_email_key UNIQUE (organization_id, email);


--
-- Name: sub_admins sub_admins_pkey; Type: CONSTRAINT; Schema: admin_org; Owner: -
--

ALTER TABLE ONLY admin_org.sub_admins
    ADD CONSTRAINT sub_admins_pkey PRIMARY KEY (id);


--
-- Name: appointment_holds appointment_holds_pkey; Type: CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointment_holds
    ADD CONSTRAINT appointment_holds_pkey PRIMARY KEY (id);


--
-- Name: appointment_reschedules appointment_reschedules_pkey; Type: CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointment_reschedules
    ADD CONSTRAINT appointment_reschedules_pkey PRIMARY KEY (id);


--
-- Name: appointment_status_events appointment_status_events_pkey; Type: CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointment_status_events
    ADD CONSTRAINT appointment_status_events_pkey PRIMARY KEY (id);


--
-- Name: appointments appointments_booking_number_key; Type: CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointments
    ADD CONSTRAINT appointments_booking_number_key UNIQUE (booking_number);


--
-- Name: appointments appointments_pkey; Type: CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);


--
-- Name: cms_media cms_media_pkey; Type: CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.cms_media
    ADD CONSTRAINT cms_media_pkey PRIMARY KEY (id);


--
-- Name: cms_pages cms_pages_pkey; Type: CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.cms_pages
    ADD CONSTRAINT cms_pages_pkey PRIMARY KEY (id);


--
-- Name: cms_pages cms_pages_slug_key; Type: CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.cms_pages
    ADD CONSTRAINT cms_pages_slug_key UNIQUE (slug);


--
-- Name: cms_posts cms_posts_pkey; Type: CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.cms_posts
    ADD CONSTRAINT cms_posts_pkey PRIMARY KEY (id);


--
-- Name: cms_posts cms_posts_slug_key; Type: CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.cms_posts
    ADD CONSTRAINT cms_posts_slug_key UNIQUE (slug);


--
-- Name: portal_banners portal_banners_pkey; Type: CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.portal_banners
    ADD CONSTRAINT portal_banners_pkey PRIMARY KEY (id);


--
-- Name: attendance_audit_actions attendance_audit_actions_pkey; Type: CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.attendance_audit_actions
    ADD CONSTRAINT attendance_audit_actions_pkey PRIMARY KEY (id);


--
-- Name: attendance_records attendance_records_employee_id_attendance_date_key; Type: CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.attendance_records
    ADD CONSTRAINT attendance_records_employee_id_attendance_date_key UNIQUE (employee_id, attendance_date);


--
-- Name: attendance_records attendance_records_pkey; Type: CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.attendance_records
    ADD CONSTRAINT attendance_records_pkey PRIMARY KEY (id);


--
-- Name: branch_holidays branch_holidays_branch_id_holiday_date_key; Type: CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.branch_holidays
    ADD CONSTRAINT branch_holidays_branch_id_holiday_date_key UNIQUE (branch_id, holiday_date);


--
-- Name: branch_holidays branch_holidays_pkey; Type: CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.branch_holidays
    ADD CONSTRAINT branch_holidays_pkey PRIMARY KEY (id);


--
-- Name: branch_leave_policies branch_leave_accrual_rules_branch_id_leave_type_id_key; Type: CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.branch_leave_policies
    ADD CONSTRAINT branch_leave_accrual_rules_branch_id_leave_type_id_key UNIQUE (branch_id, leave_type_id);


--
-- Name: branch_leave_policies branch_leave_accrual_rules_pkey; Type: CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.branch_leave_policies
    ADD CONSTRAINT branch_leave_accrual_rules_pkey PRIMARY KEY (id);


--
-- Name: employee_actions employee_actions_pkey; Type: CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.employee_actions
    ADD CONSTRAINT employee_actions_pkey PRIMARY KEY (id);


--
-- Name: employees employees_organization_id_email_key; Type: CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.employees
    ADD CONSTRAINT employees_organization_id_email_key UNIQUE (organization_id, email);


--
-- Name: employees employees_organization_id_employee_number_key; Type: CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.employees
    ADD CONSTRAINT employees_organization_id_employee_number_key UNIQUE (organization_id, employee_number);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);


--
-- Name: leave_balances leave_balances_employee_id_leave_type_id_year_key; Type: CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.leave_balances
    ADD CONSTRAINT leave_balances_employee_id_leave_type_id_year_key UNIQUE (employee_id, leave_type_id, year);


--
-- Name: leave_balances leave_balances_pkey; Type: CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.leave_balances
    ADD CONSTRAINT leave_balances_pkey PRIMARY KEY (id);


--
-- Name: leave_requests leave_requests_pkey; Type: CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.leave_requests
    ADD CONSTRAINT leave_requests_pkey PRIMARY KEY (id);


--
-- Name: leave_types leave_types_organization_id_code_key; Type: CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.leave_types
    ADD CONSTRAINT leave_types_organization_id_code_key UNIQUE (organization_id, code);


--
-- Name: leave_types leave_types_pkey; Type: CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.leave_types
    ADD CONSTRAINT leave_types_pkey PRIMARY KEY (id);


--
-- Name: branches branches_organization_id_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_organization_id_slug_key UNIQUE (organization_id, slug);


--
-- Name: branches branches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_pkey PRIMARY KEY (id);


--
-- Name: org_status_actions org_status_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_status_actions
    ADD CONSTRAINT org_status_actions_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_slug_key UNIQUE (slug);


--
-- Name: platform_commission_config platform_commission_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_commission_config
    ADD CONSTRAINT platform_commission_config_pkey PRIMARY KEY (id);


--
-- Name: reason_codes reason_codes_category_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reason_codes
    ADD CONSTRAINT reason_codes_category_code_key UNIQUE (category, code);


--
-- Name: reason_codes reason_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reason_codes
    ADD CONSTRAINT reason_codes_pkey PRIMARY KEY (id);


--
-- Name: states states_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_code_key UNIQUE (code);


--
-- Name: states states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_pkey PRIMARY KEY (id);


--
-- Name: super_admin_users super_admin_users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.super_admin_users
    ADD CONSTRAINT super_admin_users_email_key UNIQUE (email);


--
-- Name: super_admin_users super_admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.super_admin_users
    ADD CONSTRAINT super_admin_users_pkey PRIMARY KEY (id);


--
-- Name: user_access_actions user_access_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_access_actions
    ADD CONSTRAINT user_access_actions_pkey PRIMARY KEY (id);


--
-- Name: review_abuse_rules review_abuse_rules_code_key; Type: CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_abuse_rules
    ADD CONSTRAINT review_abuse_rules_code_key UNIQUE (code);


--
-- Name: review_abuse_rules review_abuse_rules_pkey; Type: CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_abuse_rules
    ADD CONSTRAINT review_abuse_rules_pkey PRIMARY KEY (id);


--
-- Name: review_images review_images_pkey; Type: CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_images
    ADD CONSTRAINT review_images_pkey PRIMARY KEY (id);


--
-- Name: review_moderation_actions review_moderation_actions_pkey; Type: CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_moderation_actions
    ADD CONSTRAINT review_moderation_actions_pkey PRIMARY KEY (id);


--
-- Name: review_moderation_settings review_moderation_settings_pkey; Type: CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_moderation_settings
    ADD CONSTRAINT review_moderation_settings_pkey PRIMARY KEY (id);


--
-- Name: review_replies review_replies_pkey; Type: CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_replies
    ADD CONSTRAINT review_replies_pkey PRIMARY KEY (id);


--
-- Name: review_replies review_replies_review_id_key; Type: CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_replies
    ADD CONSTRAINT review_replies_review_id_key UNIQUE (review_id);


--
-- Name: review_reports review_reports_pkey; Type: CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_reports
    ADD CONSTRAINT review_reports_pkey PRIMARY KEY (id);


--
-- Name: reviews reviews_booking_ref_key; Type: CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.reviews
    ADD CONSTRAINT reviews_booking_ref_key UNIQUE (booking_ref);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: billing_cycles billing_cycles_code_key; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.billing_cycles
    ADD CONSTRAINT billing_cycles_code_key UNIQUE (code);


--
-- Name: billing_cycles billing_cycles_pkey; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.billing_cycles
    ADD CONSTRAINT billing_cycles_pkey PRIMARY KEY (id);


--
-- Name: billing_discount_configs billing_discount_configs_pkey; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.billing_discount_configs
    ADD CONSTRAINT billing_discount_configs_pkey PRIMARY KEY (id);


--
-- Name: commission_rate_history commission_rate_history_pkey; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.commission_rate_history
    ADD CONSTRAINT commission_rate_history_pkey PRIMARY KEY (id);


--
-- Name: credit_note_line_items credit_note_line_items_pkey; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.credit_note_line_items
    ADD CONSTRAINT credit_note_line_items_pkey PRIMARY KEY (id);


--
-- Name: credit_notes credit_notes_credit_note_number_key; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.credit_notes
    ADD CONSTRAINT credit_notes_credit_note_number_key UNIQUE (credit_note_number);


--
-- Name: credit_notes credit_notes_pkey; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.credit_notes
    ADD CONSTRAINT credit_notes_pkey PRIMARY KEY (id);


--
-- Name: end_user_transactions end_user_transactions_pkey; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.end_user_transactions
    ADD CONSTRAINT end_user_transactions_pkey PRIMARY KEY (id);


--
-- Name: end_user_transactions end_user_transactions_transaction_ref_key; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.end_user_transactions
    ADD CONSTRAINT end_user_transactions_transaction_ref_key UNIQUE (transaction_ref);


--
-- Name: invoice_line_items invoice_line_items_pkey; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.invoice_line_items
    ADD CONSTRAINT invoice_line_items_pkey PRIMARY KEY (id);


--
-- Name: invoice_payments invoice_payments_invoice_id_payment_id_key; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.invoice_payments
    ADD CONSTRAINT invoice_payments_invoice_id_payment_id_key UNIQUE (invoice_id, payment_id);


--
-- Name: invoice_payments invoice_payments_pkey; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.invoice_payments
    ADD CONSTRAINT invoice_payments_pkey PRIMARY KEY (id);


--
-- Name: invoice_tax_lines invoice_tax_lines_pkey; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.invoice_tax_lines
    ADD CONSTRAINT invoice_tax_lines_pkey PRIMARY KEY (id);


--
-- Name: invoices invoices_invoice_number_key; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.invoices
    ADD CONSTRAINT invoices_invoice_number_key UNIQUE (invoice_number);


--
-- Name: invoices invoices_pkey; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);


--
-- Name: merchant_ledger_entries merchant_ledger_entries_pkey; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.merchant_ledger_entries
    ADD CONSTRAINT merchant_ledger_entries_pkey PRIMARY KEY (id);


--
-- Name: org_bill_structure org_bill_structure_pkey; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.org_bill_structure
    ADD CONSTRAINT org_bill_structure_pkey PRIMARY KEY (id);


--
-- Name: org_merchant_balances org_merchant_balances_pkey; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.org_merchant_balances
    ADD CONSTRAINT org_merchant_balances_pkey PRIMARY KEY (organization_id);


--
-- Name: payments payments_payment_number_key; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.payments
    ADD CONSTRAINT payments_payment_number_key UNIQUE (payment_number);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: refunds refunds_pkey; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.refunds
    ADD CONSTRAINT refunds_pkey PRIMARY KEY (id);


--
-- Name: salon_payout_items salon_payout_items_pkey; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.salon_payout_items
    ADD CONSTRAINT salon_payout_items_pkey PRIMARY KEY (id);


--
-- Name: salon_payouts salon_payouts_payout_number_key; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.salon_payouts
    ADD CONSTRAINT salon_payouts_payout_number_key UNIQUE (payout_number);


--
-- Name: salon_payouts salon_payouts_pkey; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.salon_payouts
    ADD CONSTRAINT salon_payouts_pkey PRIMARY KEY (id);


--
-- Name: state_tax_configs state_tax_configs_pkey; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.state_tax_configs
    ADD CONSTRAINT state_tax_configs_pkey PRIMARY KEY (id);


--
-- Name: state_tax_configs state_tax_configs_state_id_tax_code_effective_from_key; Type: CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.state_tax_configs
    ADD CONSTRAINT state_tax_configs_state_id_tax_code_effective_from_key UNIQUE (state_id, tax_code, effective_from);


--
-- Name: branch_service_specialists branch_service_specialists_pkey; Type: CONSTRAINT; Schema: services; Owner: -
--

ALTER TABLE ONLY services.branch_service_specialists
    ADD CONSTRAINT branch_service_specialists_pkey PRIMARY KEY (branch_service_id, employee_id);


--
-- Name: branch_services branch_services_pkey; Type: CONSTRAINT; Schema: services; Owner: -
--

ALTER TABLE ONLY services.branch_services
    ADD CONSTRAINT branch_services_pkey PRIMARY KEY (id);


--
-- Name: service_categories service_categories_code_key; Type: CONSTRAINT; Schema: services; Owner: -
--

ALTER TABLE ONLY services.service_categories
    ADD CONSTRAINT service_categories_code_key UNIQUE (code);


--
-- Name: service_categories service_categories_pkey; Type: CONSTRAINT; Schema: services; Owner: -
--

ALTER TABLE ONLY services.service_categories
    ADD CONSTRAINT service_categories_pkey PRIMARY KEY (id);


--
-- Name: service_subcategories service_subcategories_category_id_code_key; Type: CONSTRAINT; Schema: services; Owner: -
--

ALTER TABLE ONLY services.service_subcategories
    ADD CONSTRAINT service_subcategories_category_id_code_key UNIQUE (category_id, code);


--
-- Name: service_subcategories service_subcategories_pkey; Type: CONSTRAINT; Schema: services; Owner: -
--

ALTER TABLE ONLY services.service_subcategories
    ADD CONSTRAINT service_subcategories_pkey PRIMARY KEY (id);


--
-- Name: org_subscription_changes org_subscription_changes_pkey; Type: CONSTRAINT; Schema: subscription; Owner: -
--

ALTER TABLE ONLY subscription.org_subscription_changes
    ADD CONSTRAINT org_subscription_changes_pkey PRIMARY KEY (id);


--
-- Name: subscription_plans subscription_plans_pkey; Type: CONSTRAINT; Schema: subscription; Owner: -
--

ALTER TABLE ONLY subscription.subscription_plans
    ADD CONSTRAINT subscription_plans_pkey PRIMARY KEY (id);


--
-- Name: support_sla_policies support_sla_policies_pkey; Type: CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_sla_policies
    ADD CONSTRAINT support_sla_policies_pkey PRIMARY KEY (id);


--
-- Name: support_sla_policies support_sla_policies_priority_key; Type: CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_sla_policies
    ADD CONSTRAINT support_sla_policies_priority_key UNIQUE (priority);


--
-- Name: support_ticket_attachments support_ticket_attachments_pkey; Type: CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_attachments
    ADD CONSTRAINT support_ticket_attachments_pkey PRIMARY KEY (id);


--
-- Name: support_ticket_categories support_ticket_categories_code_key; Type: CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_categories
    ADD CONSTRAINT support_ticket_categories_code_key UNIQUE (code);


--
-- Name: support_ticket_categories support_ticket_categories_pkey; Type: CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_categories
    ADD CONSTRAINT support_ticket_categories_pkey PRIMARY KEY (id);


--
-- Name: support_ticket_events support_ticket_events_pkey; Type: CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_events
    ADD CONSTRAINT support_ticket_events_pkey PRIMARY KEY (id);


--
-- Name: support_ticket_internal_notes support_ticket_internal_notes_pkey; Type: CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_internal_notes
    ADD CONSTRAINT support_ticket_internal_notes_pkey PRIMARY KEY (id);


--
-- Name: support_ticket_messages support_ticket_messages_pkey; Type: CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_messages
    ADD CONSTRAINT support_ticket_messages_pkey PRIMARY KEY (id);


--
-- Name: support_ticket_subtypes support_ticket_subtypes_pkey; Type: CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_subtypes
    ADD CONSTRAINT support_ticket_subtypes_pkey PRIMARY KEY (id);


--
-- Name: support_ticket_subtypes support_ticket_subtypes_type_id_code_key; Type: CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_subtypes
    ADD CONSTRAINT support_ticket_subtypes_type_id_code_key UNIQUE (type_id, code);


--
-- Name: support_ticket_types support_ticket_types_category_id_code_key; Type: CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_types
    ADD CONSTRAINT support_ticket_types_category_id_code_key UNIQUE (category_id, code);


--
-- Name: support_ticket_types support_ticket_types_pkey; Type: CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_types
    ADD CONSTRAINT support_ticket_types_pkey PRIMARY KEY (id);


--
-- Name: support_tickets support_tickets_pkey; Type: CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_tickets
    ADD CONSTRAINT support_tickets_pkey PRIMARY KEY (id);


--
-- Name: support_tickets support_tickets_ticket_number_key; Type: CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_tickets
    ADD CONSTRAINT support_tickets_ticket_number_key UNIQUE (ticket_number);


--
-- Name: idx_sub_admin_branches_branch; Type: INDEX; Schema: admin_org; Owner: -
--

CREATE INDEX idx_sub_admin_branches_branch ON admin_org.sub_admin_branches USING btree (branch_id);


--
-- Name: idx_sub_admins_disabled_by; Type: INDEX; Schema: admin_org; Owner: -
--

CREATE INDEX idx_sub_admins_disabled_by ON admin_org.sub_admins USING btree (disabled_by_super_admin_id) WHERE (disabled_by_super_admin_id IS NOT NULL);


--
-- Name: idx_sub_admins_email; Type: INDEX; Schema: admin_org; Owner: -
--

CREATE INDEX idx_sub_admins_email ON admin_org.sub_admins USING btree (email);


--
-- Name: idx_sub_admins_org_status; Type: INDEX; Schema: admin_org; Owner: -
--

CREATE INDEX idx_sub_admins_org_status ON admin_org.sub_admins USING btree (organization_id, status);


--
-- Name: idx_appointment_holds_branch_time; Type: INDEX; Schema: appointments; Owner: -
--

CREATE INDEX idx_appointment_holds_branch_time ON appointments.appointment_holds USING btree (branch_id, starts_at, ends_at) WHERE ((status)::text = 'ACTIVE'::text);


--
-- Name: idx_appointment_reschedules_appt; Type: INDEX; Schema: appointments; Owner: -
--

CREATE INDEX idx_appointment_reschedules_appt ON appointments.appointment_reschedules USING btree (appointment_id, performed_at DESC);


--
-- Name: idx_appointment_status_events_appt; Type: INDEX; Schema: appointments; Owner: -
--

CREATE INDEX idx_appointment_status_events_appt ON appointments.appointment_status_events USING btree (appointment_id, performed_at DESC);


--
-- Name: idx_appointments_branch_starts; Type: INDEX; Schema: appointments; Owner: -
--

CREATE INDEX idx_appointments_branch_starts ON appointments.appointments USING btree (branch_id, starts_at);


--
-- Name: idx_appointments_end_user; Type: INDEX; Schema: appointments; Owner: -
--

CREATE INDEX idx_appointments_end_user ON appointments.appointments USING btree (end_user_ref);


--
-- Name: idx_appointments_org_status; Type: INDEX; Schema: appointments; Owner: -
--

CREATE INDEX idx_appointments_org_status ON appointments.appointments USING btree (organization_id, status);


--
-- Name: idx_appointments_service; Type: INDEX; Schema: appointments; Owner: -
--

CREATE INDEX idx_appointments_service ON appointments.appointments USING btree (branch_service_id);


--
-- Name: idx_appointments_specialist_starts; Type: INDEX; Schema: appointments; Owner: -
--

CREATE INDEX idx_appointments_specialist_starts ON appointments.appointments USING btree (specialist_id, starts_at) WHERE (specialist_id IS NOT NULL);


--
-- Name: idx_cms_media_type; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_media_type ON cms.cms_media USING btree (media_type, created_at DESC);


--
-- Name: idx_cms_media_uploaded_by; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_media_uploaded_by ON cms.cms_media USING btree (uploaded_by) WHERE (uploaded_by IS NOT NULL);


--
-- Name: idx_cms_pages_created_by; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_pages_created_by ON cms.cms_pages USING btree (created_by) WHERE (created_by IS NOT NULL);


--
-- Name: idx_cms_pages_og_image; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_pages_og_image ON cms.cms_pages USING btree (og_image_media_id) WHERE (og_image_media_id IS NOT NULL);


--
-- Name: idx_cms_pages_public; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_pages_public ON cms.cms_pages USING btree (status, publish_at) WHERE ((status)::text = ANY ((ARRAY['PUBLISHED'::character varying, 'SCHEDULED'::character varying])::text[]));


--
-- Name: idx_cms_pages_status; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_pages_status ON cms.cms_pages USING btree (status, publish_at);


--
-- Name: idx_cms_pages_type; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_pages_type ON cms.cms_pages USING btree (page_type);


--
-- Name: idx_cms_pages_updated_by; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_pages_updated_by ON cms.cms_pages USING btree (updated_by) WHERE (updated_by IS NOT NULL);


--
-- Name: idx_cms_posts_author; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_posts_author ON cms.cms_posts USING btree (author_id) WHERE (author_id IS NOT NULL);


--
-- Name: idx_cms_posts_cover; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_posts_cover ON cms.cms_posts USING btree (cover_media_id) WHERE (cover_media_id IS NOT NULL);


--
-- Name: idx_cms_posts_created_by; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_posts_created_by ON cms.cms_posts USING btree (created_by) WHERE (created_by IS NOT NULL);


--
-- Name: idx_cms_posts_published; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_posts_published ON cms.cms_posts USING btree (published_at DESC) WHERE ((status)::text = 'PUBLISHED'::text);


--
-- Name: idx_cms_posts_status; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_posts_status ON cms.cms_posts USING btree (status, publish_at);


--
-- Name: idx_cms_posts_updated_by; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_cms_posts_updated_by ON cms.cms_posts USING btree (updated_by) WHERE (updated_by IS NOT NULL);


--
-- Name: idx_portal_banners_active; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_portal_banners_active ON cms.portal_banners USING btree (is_active, display_priority, active_from) WHERE (is_active = true);


--
-- Name: idx_portal_banners_created_by; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_portal_banners_created_by ON cms.portal_banners USING btree (created_by) WHERE (created_by IS NOT NULL);


--
-- Name: idx_portal_banners_image; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_portal_banners_image ON cms.portal_banners USING btree (image_media_id) WHERE (image_media_id IS NOT NULL);


--
-- Name: idx_portal_banners_rules; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_portal_banners_rules ON cms.portal_banners USING gin (targeting_rules);


--
-- Name: idx_portal_banners_updated_by; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_portal_banners_updated_by ON cms.portal_banners USING btree (updated_by) WHERE (updated_by IS NOT NULL);


--
-- Name: idx_portal_banners_window; Type: INDEX; Schema: cms; Owner: -
--

CREATE INDEX idx_portal_banners_window ON cms.portal_banners USING btree (active_from, active_until) WHERE (is_active = true);


--
-- Name: idx_attendance_audit_att; Type: INDEX; Schema: employee; Owner: -
--

CREATE INDEX idx_attendance_audit_att ON employee.attendance_audit_actions USING btree (attendance_id, performed_at DESC);


--
-- Name: idx_attendance_branch_date; Type: INDEX; Schema: employee; Owner: -
--

CREATE INDEX idx_attendance_branch_date ON employee.attendance_records USING btree (branch_id, attendance_date);


--
-- Name: idx_attendance_org_date; Type: INDEX; Schema: employee; Owner: -
--

CREATE INDEX idx_attendance_org_date ON employee.attendance_records USING btree (organization_id, attendance_date);


--
-- Name: idx_branch_holidays_branch_date; Type: INDEX; Schema: employee; Owner: -
--

CREATE INDEX idx_branch_holidays_branch_date ON employee.branch_holidays USING btree (branch_id, holiday_date);


--
-- Name: idx_branch_leave_policies_branch; Type: INDEX; Schema: employee; Owner: -
--

CREATE INDEX idx_branch_leave_policies_branch ON employee.branch_leave_policies USING btree (branch_id);


--
-- Name: idx_employee_actions_emp; Type: INDEX; Schema: employee; Owner: -
--

CREATE INDEX idx_employee_actions_emp ON employee.employee_actions USING btree (employee_id, performed_at DESC);


--
-- Name: idx_employees_branch; Type: INDEX; Schema: employee; Owner: -
--

CREATE INDEX idx_employees_branch ON employee.employees USING btree (branch_id);


--
-- Name: idx_employees_org_branch_status; Type: INDEX; Schema: employee; Owner: -
--

CREATE INDEX idx_employees_org_branch_status ON employee.employees USING btree (organization_id, branch_id, status);


--
-- Name: idx_leave_requests_branch; Type: INDEX; Schema: employee; Owner: -
--

CREATE INDEX idx_leave_requests_branch ON employee.leave_requests USING btree (branch_id, start_date);


--
-- Name: idx_leave_requests_emp_dates; Type: INDEX; Schema: employee; Owner: -
--

CREATE INDEX idx_leave_requests_emp_dates ON employee.leave_requests USING btree (employee_id, start_date, end_date);


--
-- Name: idx_leave_requests_org_status; Type: INDEX; Schema: employee; Owner: -
--

CREATE INDEX idx_leave_requests_org_status ON employee.leave_requests USING btree (organization_id, status);


--
-- Name: idx_branches_approved_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_branches_approved_by ON public.branches USING btree (approved_by) WHERE (approved_by IS NOT NULL);


--
-- Name: idx_branches_city; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_branches_city ON public.branches USING btree (((address ->> 'city'::text)));


--
-- Name: idx_branches_kyc_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_branches_kyc_status ON public.branches USING btree (kyc_status);


--
-- Name: idx_branches_kyc_verified_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_branches_kyc_verified_by ON public.branches USING btree (kyc_verified_by) WHERE (kyc_verified_by IS NOT NULL);


--
-- Name: idx_branches_org; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_branches_org ON public.branches USING btree (organization_id);


--
-- Name: idx_branches_org_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_branches_org_status ON public.branches USING btree (organization_id, status);


--
-- Name: idx_branches_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_branches_state_id ON public.branches USING btree (state_id);


--
-- Name: idx_branches_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_branches_status ON public.branches USING btree (status);


--
-- Name: idx_one_primary_branch_per_org; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_one_primary_branch_per_org ON public.branches USING btree (organization_id) WHERE (is_primary = true);


--
-- Name: idx_org_status_actions_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_org_status_actions_action ON public.org_status_actions USING btree (action, performed_at DESC);


--
-- Name: idx_org_status_actions_org; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_org_status_actions_org ON public.org_status_actions USING btree (organization_id, performed_at DESC);


--
-- Name: idx_org_status_actions_performed_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_org_status_actions_performed_by ON public.org_status_actions USING btree (performed_by) WHERE (performed_by IS NOT NULL);


--
-- Name: idx_org_status_actions_reason; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_org_status_actions_reason ON public.org_status_actions USING btree (reason_code_id) WHERE (reason_code_id IS NOT NULL);


--
-- Name: idx_organizations_approved_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organizations_approved_by ON public.organizations USING btree (approved_by) WHERE (approved_by IS NOT NULL);


--
-- Name: idx_organizations_kyc_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organizations_kyc_status ON public.organizations USING btree (kyc_status);


--
-- Name: idx_organizations_kyc_verified_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organizations_kyc_verified_by ON public.organizations USING btree (kyc_verified_by) WHERE (kyc_verified_by IS NOT NULL);


--
-- Name: idx_organizations_owner_disabled_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organizations_owner_disabled_by ON public.organizations USING btree (owner_disabled_by) WHERE (owner_disabled_by IS NOT NULL);


--
-- Name: idx_organizations_owner_portal_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organizations_owner_portal_status ON public.organizations USING btree (owner_portal_status, status);


--
-- Name: idx_organizations_state_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organizations_state_id ON public.organizations USING btree (state_id);


--
-- Name: idx_organizations_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organizations_status ON public.organizations USING btree (status);


--
-- Name: idx_organizations_status_changed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organizations_status_changed_at ON public.organizations USING btree (status_changed_at DESC NULLS LAST) WHERE (status_changed_at IS NOT NULL);


--
-- Name: idx_organizations_status_changed_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organizations_status_changed_by ON public.organizations USING btree (status_changed_by) WHERE (status_changed_by IS NOT NULL);


--
-- Name: idx_organizations_status_reason; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_organizations_status_reason ON public.organizations USING btree (status_reason_id) WHERE (status_reason_id IS NOT NULL);


--
-- Name: idx_platform_commission_config_updated_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_platform_commission_config_updated_by ON public.platform_commission_config USING btree (updated_by) WHERE (updated_by IS NOT NULL);


--
-- Name: idx_reason_codes_category_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reason_codes_category_active ON public.reason_codes USING btree (category, is_active, sort_order) WHERE (is_active = true);


--
-- Name: idx_reason_codes_created_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reason_codes_created_by ON public.reason_codes USING btree (created_by) WHERE (created_by IS NOT NULL);


--
-- Name: idx_reason_codes_updated_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reason_codes_updated_by ON public.reason_codes USING btree (updated_by) WHERE (updated_by IS NOT NULL);


--
-- Name: idx_user_access_actions_org; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_access_actions_org ON public.user_access_actions USING btree (organization_id, performed_at DESC);


--
-- Name: idx_user_access_actions_performed_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_access_actions_performed_by ON public.user_access_actions USING btree (performed_by) WHERE (performed_by IS NOT NULL);


--
-- Name: idx_user_access_actions_sub; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_access_actions_sub ON public.user_access_actions USING btree (sub_admin_id, performed_at DESC) WHERE (sub_admin_id IS NOT NULL);


--
-- Name: idx_user_access_actions_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_access_actions_target ON public.user_access_actions USING btree (target_type, performed_at DESC);


--
-- Name: idx_review_abuse_rules_active; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_review_abuse_rules_active ON review.review_abuse_rules USING btree (is_active, sort_order);


--
-- Name: idx_review_abuse_rules_created_by; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_review_abuse_rules_created_by ON review.review_abuse_rules USING btree (created_by) WHERE (created_by IS NOT NULL);


--
-- Name: idx_review_abuse_rules_updated_by; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_review_abuse_rules_updated_by ON review.review_abuse_rules USING btree (updated_by) WHERE (updated_by IS NOT NULL);


--
-- Name: idx_review_images_review; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_review_images_review ON review.review_images USING btree (review_id, sort_order);


--
-- Name: idx_review_moderation_actions_action; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_review_moderation_actions_action ON review.review_moderation_actions USING btree (action, performed_at DESC);


--
-- Name: idx_review_moderation_actions_image; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_review_moderation_actions_image ON review.review_moderation_actions USING btree (image_id) WHERE (image_id IS NOT NULL);


--
-- Name: idx_review_moderation_actions_performed_by; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_review_moderation_actions_performed_by ON review.review_moderation_actions USING btree (performed_by) WHERE (performed_by IS NOT NULL);


--
-- Name: idx_review_moderation_actions_reply; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_review_moderation_actions_reply ON review.review_moderation_actions USING btree (reply_id) WHERE (reply_id IS NOT NULL);


--
-- Name: idx_review_moderation_actions_review; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_review_moderation_actions_review ON review.review_moderation_actions USING btree (review_id, performed_at DESC);


--
-- Name: idx_review_moderation_settings_updated_by; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_review_moderation_settings_updated_by ON review.review_moderation_settings USING btree (updated_by) WHERE (updated_by IS NOT NULL);


--
-- Name: idx_review_replies_org; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_review_replies_org ON review.review_replies USING btree (organization_id, replied_at DESC);


--
-- Name: idx_review_replies_status; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_review_replies_status ON review.review_replies USING btree (status, replied_at DESC);


--
-- Name: idx_review_reports_open; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_review_reports_open ON review.review_reports USING btree (status, created_at DESC) WHERE ((status)::text = 'OPEN'::text);


--
-- Name: idx_review_reports_reply; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_review_reports_reply ON review.review_reports USING btree (reply_id) WHERE (reply_id IS NOT NULL);


--
-- Name: idx_review_reports_resolved_by; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_review_reports_resolved_by ON review.review_reports USING btree (resolved_by) WHERE (resolved_by IS NOT NULL);


--
-- Name: idx_review_reports_review; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_review_reports_review ON review.review_reports USING btree (review_id, created_at DESC);


--
-- Name: idx_reviews_branch; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_reviews_branch ON review.reviews USING btree (branch_id, status, submitted_at DESC);


--
-- Name: idx_reviews_end_user; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_reviews_end_user ON review.reviews USING btree (end_user_ref, submitted_at DESC);


--
-- Name: idx_reviews_moderation_queue; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_reviews_moderation_queue ON review.reviews USING btree (status, submitted_at DESC);


--
-- Name: idx_reviews_org_branch; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_reviews_org_branch ON review.reviews USING btree (organization_id, branch_id, status);


--
-- Name: idx_reviews_published; Type: INDEX; Schema: review; Owner: -
--

CREATE INDEX idx_reviews_published ON review.reviews USING btree (branch_id, published_at DESC) WHERE ((status)::text = 'PUBLISHED'::text);


--
-- Name: idx_billing_discount_configs_active; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_billing_discount_configs_active ON rms.billing_discount_configs USING btree (is_active, priority) WHERE (is_active = true);


--
-- Name: idx_billing_discount_configs_created_by; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_billing_discount_configs_created_by ON rms.billing_discount_configs USING btree (created_by) WHERE (created_by IS NOT NULL);


--
-- Name: idx_billing_discount_configs_cycle; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_billing_discount_configs_cycle ON rms.billing_discount_configs USING btree (billing_cycle_id);


--
-- Name: idx_billing_discount_configs_plan; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_billing_discount_configs_plan ON rms.billing_discount_configs USING btree (subscription_plan_id);


--
-- Name: idx_billing_discount_configs_updated_by; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_billing_discount_configs_updated_by ON rms.billing_discount_configs USING btree (updated_by) WHERE (updated_by IS NOT NULL);


--
-- Name: idx_commission_rate_history_changed_by; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_commission_rate_history_changed_by ON rms.commission_rate_history USING btree (changed_by) WHERE (changed_by IS NOT NULL);


--
-- Name: idx_commission_rate_history_org; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_commission_rate_history_org ON rms.commission_rate_history USING btree (organization_id, effective_from DESC);


--
-- Name: idx_credit_note_line_items_cn; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_credit_note_line_items_cn ON rms.credit_note_line_items USING btree (credit_note_id, sort_order);


--
-- Name: idx_credit_note_line_items_invoice_line; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_credit_note_line_items_invoice_line ON rms.credit_note_line_items USING btree (invoice_line_item_id) WHERE (invoice_line_item_id IS NOT NULL);


--
-- Name: idx_credit_notes_applied_invoice; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_credit_notes_applied_invoice ON rms.credit_notes USING btree (applied_to_invoice_id) WHERE (applied_to_invoice_id IS NOT NULL);


--
-- Name: idx_credit_notes_created_by; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_credit_notes_created_by ON rms.credit_notes USING btree (created_by) WHERE (created_by IS NOT NULL);


--
-- Name: idx_credit_notes_invoice; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_credit_notes_invoice ON rms.credit_notes USING btree (invoice_id);


--
-- Name: idx_credit_notes_settlement; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_credit_notes_settlement ON rms.credit_notes USING btree (settlement_method, status);


--
-- Name: idx_eut_branch_occurred; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_eut_branch_occurred ON rms.end_user_transactions USING btree (branch_id, occurred_at DESC);


--
-- Name: idx_eut_channel; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_eut_channel ON rms.end_user_transactions USING btree (payment_channel, occurred_at DESC);


--
-- Name: idx_eut_gateway_payment; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_eut_gateway_payment ON rms.end_user_transactions USING btree (gateway_payment_id) WHERE (gateway_payment_id IS NOT NULL);


--
-- Name: idx_eut_org_occurred; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_eut_org_occurred ON rms.end_user_transactions USING btree (organization_id, occurred_at DESC);


--
-- Name: idx_eut_salon_payout; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_eut_salon_payout ON rms.end_user_transactions USING btree (salon_payout_id) WHERE (salon_payout_id IS NOT NULL);


--
-- Name: idx_eut_status; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_eut_status ON rms.end_user_transactions USING btree (status);


--
-- Name: idx_eut_status_channel; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_eut_status_channel ON rms.end_user_transactions USING btree (status, payment_channel, occurred_at DESC);


--
-- Name: idx_invoice_line_items_cycle; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_invoice_line_items_cycle ON rms.invoice_line_items USING btree (billing_cycle_id) WHERE (billing_cycle_id IS NOT NULL);


--
-- Name: idx_invoice_line_items_invoice; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_invoice_line_items_invoice ON rms.invoice_line_items USING btree (invoice_id, sort_order);


--
-- Name: idx_invoice_line_items_plan; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_invoice_line_items_plan ON rms.invoice_line_items USING btree (subscription_plan_id) WHERE (subscription_plan_id IS NOT NULL);


--
-- Name: idx_invoice_payments_payment; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_invoice_payments_payment ON rms.invoice_payments USING btree (payment_id);


--
-- Name: idx_invoice_tax_lines_line; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_invoice_tax_lines_line ON rms.invoice_tax_lines USING btree (invoice_line_item_id);


--
-- Name: idx_invoice_tax_lines_tax_config; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_invoice_tax_lines_tax_config ON rms.invoice_tax_lines USING btree (state_tax_config_id);


--
-- Name: idx_invoices_bill; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_invoices_bill ON rms.invoices USING btree (org_bill_structure_id);


--
-- Name: idx_invoices_created_by; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_invoices_created_by ON rms.invoices USING btree (created_by) WHERE (created_by IS NOT NULL);


--
-- Name: idx_invoices_issue_date; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_invoices_issue_date ON rms.invoices USING btree (issue_date DESC);


--
-- Name: idx_invoices_org; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_invoices_org ON rms.invoices USING btree (organization_id, issue_date DESC);


--
-- Name: idx_invoices_status; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_invoices_status ON rms.invoices USING btree (status, due_date);


--
-- Name: idx_invoices_subscription_change; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_invoices_subscription_change ON rms.invoices USING btree (org_subscription_change_id) WHERE (org_subscription_change_id IS NOT NULL);


--
-- Name: idx_merchant_ledger_bucket; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_merchant_ledger_bucket ON rms.merchant_ledger_entries USING btree (organization_id, balance_bucket, occurred_at DESC);


--
-- Name: idx_merchant_ledger_created_by; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_merchant_ledger_created_by ON rms.merchant_ledger_entries USING btree (created_by) WHERE (created_by IS NOT NULL);


--
-- Name: idx_merchant_ledger_invoice; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_merchant_ledger_invoice ON rms.merchant_ledger_entries USING btree (invoice_id) WHERE (invoice_id IS NOT NULL);


--
-- Name: idx_merchant_ledger_org_occurred; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_merchant_ledger_org_occurred ON rms.merchant_ledger_entries USING btree (organization_id, occurred_at DESC);


--
-- Name: idx_merchant_ledger_payment; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_merchant_ledger_payment ON rms.merchant_ledger_entries USING btree (payment_id) WHERE (payment_id IS NOT NULL);


--
-- Name: idx_merchant_ledger_payout; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_merchant_ledger_payout ON rms.merchant_ledger_entries USING btree (salon_payout_id) WHERE (salon_payout_id IS NOT NULL);


--
-- Name: idx_merchant_ledger_txn; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_merchant_ledger_txn ON rms.merchant_ledger_entries USING btree (end_user_transaction_id) WHERE (end_user_transaction_id IS NOT NULL);


--
-- Name: idx_one_active_bill_structure_per_org; Type: INDEX; Schema: rms; Owner: -
--

CREATE UNIQUE INDEX idx_one_active_bill_structure_per_org ON rms.org_bill_structure USING btree (organization_id) WHERE ((status)::text = 'ACTIVE'::text);


--
-- Name: idx_org_bill_structure_configured_by; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_org_bill_structure_configured_by ON rms.org_bill_structure USING btree (configured_by) WHERE (configured_by IS NOT NULL);


--
-- Name: idx_org_bill_structure_cycle; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_org_bill_structure_cycle ON rms.org_bill_structure USING btree (billing_cycle_id);


--
-- Name: idx_org_bill_structure_org_id; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_org_bill_structure_org_id ON rms.org_bill_structure USING btree (organization_id);


--
-- Name: idx_org_bill_structure_org_status; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_org_bill_structure_org_status ON rms.org_bill_structure USING btree (organization_id, status);


--
-- Name: idx_org_bill_structure_plan; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_org_bill_structure_plan ON rms.org_bill_structure USING btree (subscription_plan_id);


--
-- Name: idx_org_bill_structure_renewal_date; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_org_bill_structure_renewal_date ON rms.org_bill_structure USING btree (renewal_date);


--
-- Name: idx_org_bill_structure_state_id; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_org_bill_structure_state_id ON rms.org_bill_structure USING btree (state_id);


--
-- Name: idx_org_bill_structure_status; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_org_bill_structure_status ON rms.org_bill_structure USING btree (status);


--
-- Name: idx_payments_created_by; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_payments_created_by ON rms.payments USING btree (created_by) WHERE (created_by IS NOT NULL);


--
-- Name: idx_payments_gateway_payment; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_payments_gateway_payment ON rms.payments USING btree (gateway_payment_id) WHERE (gateway_payment_id IS NOT NULL);


--
-- Name: idx_payments_org; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_payments_org ON rms.payments USING btree (organization_id, initiated_at DESC);


--
-- Name: idx_payments_status; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_payments_status ON rms.payments USING btree (status);


--
-- Name: idx_refunds_created_by; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_refunds_created_by ON rms.refunds USING btree (created_by) WHERE (created_by IS NOT NULL);


--
-- Name: idx_refunds_credit_note; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_refunds_credit_note ON rms.refunds USING btree (credit_note_id) WHERE (credit_note_id IS NOT NULL);


--
-- Name: idx_refunds_payment; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_refunds_payment ON rms.refunds USING btree (payment_id);


--
-- Name: idx_salon_payout_items_payout; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_salon_payout_items_payout ON rms.salon_payout_items USING btree (payout_id, sort_order);


--
-- Name: idx_salon_payout_items_txn; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_salon_payout_items_txn ON rms.salon_payout_items USING btree (end_user_transaction_id) WHERE (end_user_transaction_id IS NOT NULL);


--
-- Name: idx_salon_payouts_created_by; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_salon_payouts_created_by ON rms.salon_payouts USING btree (created_by) WHERE (created_by IS NOT NULL);


--
-- Name: idx_salon_payouts_org; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_salon_payouts_org ON rms.salon_payouts USING btree (organization_id, created_at DESC);


--
-- Name: idx_salon_payouts_status; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_salon_payouts_status ON rms.salon_payouts USING btree (status);


--
-- Name: idx_state_tax_configs_active; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_state_tax_configs_active ON rms.state_tax_configs USING btree (state_id, is_active) WHERE (is_active = true);


--
-- Name: idx_state_tax_configs_created_by; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_state_tax_configs_created_by ON rms.state_tax_configs USING btree (created_by) WHERE (created_by IS NOT NULL);


--
-- Name: idx_state_tax_configs_state_id; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_state_tax_configs_state_id ON rms.state_tax_configs USING btree (state_id);


--
-- Name: idx_state_tax_configs_updated_by; Type: INDEX; Schema: rms; Owner: -
--

CREATE INDEX idx_state_tax_configs_updated_by ON rms.state_tax_configs USING btree (updated_by) WHERE (updated_by IS NOT NULL);


--
-- Name: uq_billing_discount_plan_cycle; Type: INDEX; Schema: rms; Owner: -
--

CREATE UNIQUE INDEX uq_billing_discount_plan_cycle ON rms.billing_discount_configs USING btree (subscription_plan_id, billing_cycle_id) NULLS NOT DISTINCT;


--
-- Name: idx_branch_service_specialists_emp; Type: INDEX; Schema: services; Owner: -
--

CREATE INDEX idx_branch_service_specialists_emp ON services.branch_service_specialists USING btree (employee_id);


--
-- Name: idx_branch_services_branch_status; Type: INDEX; Schema: services; Owner: -
--

CREATE INDEX idx_branch_services_branch_status ON services.branch_services USING btree (branch_id, status);


--
-- Name: idx_branch_services_category; Type: INDEX; Schema: services; Owner: -
--

CREATE INDEX idx_branch_services_category ON services.branch_services USING btree (category_id, subcategory_id);


--
-- Name: idx_branch_services_name; Type: INDEX; Schema: services; Owner: -
--

CREATE INDEX idx_branch_services_name ON services.branch_services USING btree (branch_id, name);


--
-- Name: idx_branch_services_org; Type: INDEX; Schema: services; Owner: -
--

CREATE INDEX idx_branch_services_org ON services.branch_services USING btree (organization_id);


--
-- Name: idx_service_categories_active; Type: INDEX; Schema: services; Owner: -
--

CREATE INDEX idx_service_categories_active ON services.service_categories USING btree (is_active, sort_order);


--
-- Name: idx_service_categories_created_by; Type: INDEX; Schema: services; Owner: -
--

CREATE INDEX idx_service_categories_created_by ON services.service_categories USING btree (created_by) WHERE (created_by IS NOT NULL);


--
-- Name: idx_service_categories_updated_by; Type: INDEX; Schema: services; Owner: -
--

CREATE INDEX idx_service_categories_updated_by ON services.service_categories USING btree (updated_by) WHERE (updated_by IS NOT NULL);


--
-- Name: idx_service_subcategories_category; Type: INDEX; Schema: services; Owner: -
--

CREATE INDEX idx_service_subcategories_category ON services.service_subcategories USING btree (category_id, is_active, sort_order);


--
-- Name: idx_service_subcategories_created_by; Type: INDEX; Schema: services; Owner: -
--

CREATE INDEX idx_service_subcategories_created_by ON services.service_subcategories USING btree (created_by) WHERE (created_by IS NOT NULL);


--
-- Name: idx_service_subcategories_updated_by; Type: INDEX; Schema: services; Owner: -
--

CREATE INDEX idx_service_subcategories_updated_by ON services.service_subcategories USING btree (updated_by) WHERE (updated_by IS NOT NULL);


--
-- Name: idx_org_subscription_changes_bill; Type: INDEX; Schema: subscription; Owner: -
--

CREATE INDEX idx_org_subscription_changes_bill ON subscription.org_subscription_changes USING btree (org_bill_structure_id, performed_at DESC);


--
-- Name: idx_org_subscription_changes_from_cycle; Type: INDEX; Schema: subscription; Owner: -
--

CREATE INDEX idx_org_subscription_changes_from_cycle ON subscription.org_subscription_changes USING btree (from_billing_cycle_id) WHERE (from_billing_cycle_id IS NOT NULL);


--
-- Name: idx_org_subscription_changes_from_plan; Type: INDEX; Schema: subscription; Owner: -
--

CREATE INDEX idx_org_subscription_changes_from_plan ON subscription.org_subscription_changes USING btree (from_subscription_plan_id);


--
-- Name: idx_org_subscription_changes_org; Type: INDEX; Schema: subscription; Owner: -
--

CREATE INDEX idx_org_subscription_changes_org ON subscription.org_subscription_changes USING btree (organization_id, performed_at DESC);


--
-- Name: idx_org_subscription_changes_performed_by; Type: INDEX; Schema: subscription; Owner: -
--

CREATE INDEX idx_org_subscription_changes_performed_by ON subscription.org_subscription_changes USING btree (performed_by) WHERE (performed_by IS NOT NULL);


--
-- Name: idx_org_subscription_changes_to_cycle; Type: INDEX; Schema: subscription; Owner: -
--

CREATE INDEX idx_org_subscription_changes_to_cycle ON subscription.org_subscription_changes USING btree (to_billing_cycle_id) WHERE (to_billing_cycle_id IS NOT NULL);


--
-- Name: idx_org_subscription_changes_to_plan; Type: INDEX; Schema: subscription; Owner: -
--

CREATE INDEX idx_org_subscription_changes_to_plan ON subscription.org_subscription_changes USING btree (to_subscription_plan_id);


--
-- Name: idx_org_subscription_changes_type; Type: INDEX; Schema: subscription; Owner: -
--

CREATE INDEX idx_org_subscription_changes_type ON subscription.org_subscription_changes USING btree (change_type, performed_at DESC);


--
-- Name: idx_support_sla_policies_updated_by; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_sla_policies_updated_by ON tickets.support_sla_policies USING btree (updated_by) WHERE (updated_by IS NOT NULL);


--
-- Name: idx_support_ticket_attachments_message; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_ticket_attachments_message ON tickets.support_ticket_attachments USING btree (message_id) WHERE (message_id IS NOT NULL);


--
-- Name: idx_support_ticket_attachments_ticket; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_ticket_attachments_ticket ON tickets.support_ticket_attachments USING btree (ticket_id);


--
-- Name: idx_support_ticket_categories_audience; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_ticket_categories_audience ON tickets.support_ticket_categories USING btree (audience, is_active, sort_order);


--
-- Name: idx_support_ticket_categories_created_by; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_ticket_categories_created_by ON tickets.support_ticket_categories USING btree (created_by) WHERE (created_by IS NOT NULL);


--
-- Name: idx_support_ticket_categories_updated_by; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_ticket_categories_updated_by ON tickets.support_ticket_categories USING btree (updated_by) WHERE (updated_by IS NOT NULL);


--
-- Name: idx_support_ticket_events_performed_by; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_ticket_events_performed_by ON tickets.support_ticket_events USING btree (performed_by) WHERE (performed_by IS NOT NULL);


--
-- Name: idx_support_ticket_events_ticket; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_ticket_events_ticket ON tickets.support_ticket_events USING btree (ticket_id, performed_at DESC);


--
-- Name: idx_support_ticket_internal_notes_created_by; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_ticket_internal_notes_created_by ON tickets.support_ticket_internal_notes USING btree (created_by) WHERE (created_by IS NOT NULL);


--
-- Name: idx_support_ticket_messages_author_sa; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_ticket_messages_author_sa ON tickets.support_ticket_messages USING btree (author_super_admin_id) WHERE (author_super_admin_id IS NOT NULL);


--
-- Name: idx_support_ticket_messages_ticket; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_ticket_messages_ticket ON tickets.support_ticket_messages USING btree (ticket_id, created_at);


--
-- Name: idx_support_ticket_notes_ticket; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_ticket_notes_ticket ON tickets.support_ticket_internal_notes USING btree (ticket_id, created_at);


--
-- Name: idx_support_ticket_subtypes_type; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_ticket_subtypes_type ON tickets.support_ticket_subtypes USING btree (type_id, is_active, sort_order);


--
-- Name: idx_support_ticket_types_category; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_ticket_types_category ON tickets.support_ticket_types USING btree (category_id, is_active, sort_order);


--
-- Name: idx_support_tickets_assignee; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_tickets_assignee ON tickets.support_tickets USING btree (assigned_to, status) WHERE (assigned_to IS NOT NULL);


--
-- Name: idx_support_tickets_booking; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_tickets_booking ON tickets.support_tickets USING btree (booking_ref) WHERE (booking_ref IS NOT NULL);


--
-- Name: idx_support_tickets_branch; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_tickets_branch ON tickets.support_tickets USING btree (branch_id) WHERE (branch_id IS NOT NULL);


--
-- Name: idx_support_tickets_category; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_tickets_category ON tickets.support_tickets USING btree (category_id);


--
-- Name: idx_support_tickets_created_by_sa; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_tickets_created_by_sa ON tickets.support_tickets USING btree (created_by_super_admin_id) WHERE (created_by_super_admin_id IS NOT NULL);


--
-- Name: idx_support_tickets_end_user; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_tickets_end_user ON tickets.support_tickets USING btree (end_user_ref, created_at DESC) WHERE (end_user_ref IS NOT NULL);


--
-- Name: idx_support_tickets_org; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_tickets_org ON tickets.support_tickets USING btree (organization_id, created_at DESC) WHERE (organization_id IS NOT NULL);


--
-- Name: idx_support_tickets_sla_overdue; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_tickets_sla_overdue ON tickets.support_tickets USING btree (resolve_due_at) WHERE (((status)::text <> ALL ((ARRAY['RESOLVED'::character varying, 'CLOSED'::character varying])::text[])) AND (resolve_due_at IS NOT NULL));


--
-- Name: idx_support_tickets_sla_policy; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_tickets_sla_policy ON tickets.support_tickets USING btree (sla_policy_id) WHERE (sla_policy_id IS NOT NULL);


--
-- Name: idx_support_tickets_source_status; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_tickets_source_status ON tickets.support_tickets USING btree (source, status, created_at DESC);


--
-- Name: idx_support_tickets_status; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_tickets_status ON tickets.support_tickets USING btree (status, priority, created_at DESC);


--
-- Name: idx_support_tickets_subtype; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_tickets_subtype ON tickets.support_tickets USING btree (subtype_id) WHERE (subtype_id IS NOT NULL);


--
-- Name: idx_support_tickets_type; Type: INDEX; Schema: tickets; Owner: -
--

CREATE INDEX idx_support_tickets_type ON tickets.support_tickets USING btree (type_id);


--
-- Name: sub_admin_branches trg_sub_admin_branch_same_org; Type: TRIGGER; Schema: admin_org; Owner: -
--

CREATE TRIGGER trg_sub_admin_branch_same_org BEFORE INSERT OR UPDATE ON admin_org.sub_admin_branches FOR EACH ROW EXECUTE FUNCTION admin_org.enforce_sub_admin_branch_same_org();


--
-- Name: appointments trg_appointment_scope; Type: TRIGGER; Schema: appointments; Owner: -
--

CREATE TRIGGER trg_appointment_scope BEFORE INSERT OR UPDATE OF organization_id, branch_id, branch_service_id, specialist_id ON appointments.appointments FOR EACH ROW EXECUTE FUNCTION appointments.enforce_appointment_scope();


--
-- Name: branch_leave_policies trg_branch_leave_policy_line_same_org; Type: TRIGGER; Schema: employee; Owner: -
--

CREATE TRIGGER trg_branch_leave_policy_line_same_org BEFORE INSERT OR UPDATE OF organization_id, branch_id, leave_type_id ON employee.branch_leave_policies FOR EACH ROW EXECUTE FUNCTION employee.enforce_branch_leave_policy_line_same_org();


--
-- Name: employees trg_employee_branch_same_org; Type: TRIGGER; Schema: employee; Owner: -
--

CREATE TRIGGER trg_employee_branch_same_org BEFORE INSERT OR UPDATE OF organization_id, branch_id ON employee.employees FOR EACH ROW EXECUTE FUNCTION employee.enforce_employee_branch_same_org();


--
-- Name: branch_services trg_branch_service_refs; Type: TRIGGER; Schema: services; Owner: -
--

CREATE TRIGGER trg_branch_service_refs BEFORE INSERT OR UPDATE OF organization_id, branch_id, category_id, subcategory_id ON services.branch_services FOR EACH ROW EXECUTE FUNCTION services.enforce_branch_service_refs();


--
-- Name: branch_service_specialists trg_service_specialist_same_scope; Type: TRIGGER; Schema: services; Owner: -
--

CREATE TRIGGER trg_service_specialist_same_scope BEFORE INSERT OR UPDATE ON services.branch_service_specialists FOR EACH ROW EXECUTE FUNCTION services.enforce_service_specialist_same_scope();


--
-- Name: sub_admin_branches sub_admin_branches_branch_id_fkey; Type: FK CONSTRAINT; Schema: admin_org; Owner: -
--

ALTER TABLE ONLY admin_org.sub_admin_branches
    ADD CONSTRAINT sub_admin_branches_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;


--
-- Name: sub_admin_branches sub_admin_branches_sub_admin_id_fkey; Type: FK CONSTRAINT; Schema: admin_org; Owner: -
--

ALTER TABLE ONLY admin_org.sub_admin_branches
    ADD CONSTRAINT sub_admin_branches_sub_admin_id_fkey FOREIGN KEY (sub_admin_id) REFERENCES admin_org.sub_admins(id) ON DELETE CASCADE;


--
-- Name: sub_admin_modules sub_admin_modules_sub_admin_id_fkey; Type: FK CONSTRAINT; Schema: admin_org; Owner: -
--

ALTER TABLE ONLY admin_org.sub_admin_modules
    ADD CONSTRAINT sub_admin_modules_sub_admin_id_fkey FOREIGN KEY (sub_admin_id) REFERENCES admin_org.sub_admins(id) ON DELETE CASCADE;


--
-- Name: sub_admins sub_admins_disabled_by_super_admin_id_fkey; Type: FK CONSTRAINT; Schema: admin_org; Owner: -
--

ALTER TABLE ONLY admin_org.sub_admins
    ADD CONSTRAINT sub_admins_disabled_by_super_admin_id_fkey FOREIGN KEY (disabled_by_super_admin_id) REFERENCES public.super_admin_users(id);


--
-- Name: sub_admins sub_admins_organization_id_fkey; Type: FK CONSTRAINT; Schema: admin_org; Owner: -
--

ALTER TABLE ONLY admin_org.sub_admins
    ADD CONSTRAINT sub_admins_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: appointment_holds appointment_holds_branch_id_fkey; Type: FK CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointment_holds
    ADD CONSTRAINT appointment_holds_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;


--
-- Name: appointment_holds appointment_holds_branch_service_id_fkey; Type: FK CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointment_holds
    ADD CONSTRAINT appointment_holds_branch_service_id_fkey FOREIGN KEY (branch_service_id) REFERENCES services.branch_services(id) ON DELETE CASCADE;


--
-- Name: appointment_holds appointment_holds_organization_id_fkey; Type: FK CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointment_holds
    ADD CONSTRAINT appointment_holds_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: appointment_holds appointment_holds_specialist_id_fkey; Type: FK CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointment_holds
    ADD CONSTRAINT appointment_holds_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES employee.employees(id) ON DELETE SET NULL;


--
-- Name: appointment_reschedules appointment_reschedules_appointment_id_fkey; Type: FK CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointment_reschedules
    ADD CONSTRAINT appointment_reschedules_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES appointments.appointments(id) ON DELETE CASCADE;


--
-- Name: appointment_reschedules appointment_reschedules_new_specialist_id_fkey; Type: FK CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointment_reschedules
    ADD CONSTRAINT appointment_reschedules_new_specialist_id_fkey FOREIGN KEY (new_specialist_id) REFERENCES employee.employees(id) ON DELETE SET NULL;


--
-- Name: appointment_reschedules appointment_reschedules_previous_specialist_id_fkey; Type: FK CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointment_reschedules
    ADD CONSTRAINT appointment_reschedules_previous_specialist_id_fkey FOREIGN KEY (previous_specialist_id) REFERENCES employee.employees(id) ON DELETE SET NULL;


--
-- Name: appointment_status_events appointment_status_events_appointment_id_fkey; Type: FK CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointment_status_events
    ADD CONSTRAINT appointment_status_events_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES appointments.appointments(id) ON DELETE CASCADE;


--
-- Name: appointments appointments_branch_id_fkey; Type: FK CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointments
    ADD CONSTRAINT appointments_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE RESTRICT;


--
-- Name: appointments appointments_branch_service_id_fkey; Type: FK CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointments
    ADD CONSTRAINT appointments_branch_service_id_fkey FOREIGN KEY (branch_service_id) REFERENCES services.branch_services(id) ON DELETE RESTRICT;


--
-- Name: appointments appointments_eut_transaction_id_fkey; Type: FK CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointments
    ADD CONSTRAINT appointments_eut_transaction_id_fkey FOREIGN KEY (eut_transaction_id) REFERENCES rms.end_user_transactions(id) ON DELETE SET NULL;


--
-- Name: appointments appointments_hold_id_fkey; Type: FK CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointments
    ADD CONSTRAINT appointments_hold_id_fkey FOREIGN KEY (hold_id) REFERENCES appointments.appointment_holds(id) ON DELETE SET NULL;


--
-- Name: appointments appointments_organization_id_fkey; Type: FK CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointments
    ADD CONSTRAINT appointments_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: appointments appointments_specialist_id_fkey; Type: FK CONSTRAINT; Schema: appointments; Owner: -
--

ALTER TABLE ONLY appointments.appointments
    ADD CONSTRAINT appointments_specialist_id_fkey FOREIGN KEY (specialist_id) REFERENCES employee.employees(id) ON DELETE SET NULL;


--
-- Name: cms_media cms_media_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.cms_media
    ADD CONSTRAINT cms_media_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.super_admin_users(id);


--
-- Name: cms_pages cms_pages_created_by_fkey; Type: FK CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.cms_pages
    ADD CONSTRAINT cms_pages_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.super_admin_users(id);


--
-- Name: cms_pages cms_pages_og_image_media_id_fkey; Type: FK CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.cms_pages
    ADD CONSTRAINT cms_pages_og_image_media_id_fkey FOREIGN KEY (og_image_media_id) REFERENCES cms.cms_media(id) ON DELETE SET NULL;


--
-- Name: cms_pages cms_pages_updated_by_fkey; Type: FK CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.cms_pages
    ADD CONSTRAINT cms_pages_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.super_admin_users(id);


--
-- Name: cms_posts cms_posts_author_id_fkey; Type: FK CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.cms_posts
    ADD CONSTRAINT cms_posts_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.super_admin_users(id);


--
-- Name: cms_posts cms_posts_cover_media_id_fkey; Type: FK CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.cms_posts
    ADD CONSTRAINT cms_posts_cover_media_id_fkey FOREIGN KEY (cover_media_id) REFERENCES cms.cms_media(id) ON DELETE SET NULL;


--
-- Name: cms_posts cms_posts_created_by_fkey; Type: FK CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.cms_posts
    ADD CONSTRAINT cms_posts_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.super_admin_users(id);


--
-- Name: cms_posts cms_posts_updated_by_fkey; Type: FK CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.cms_posts
    ADD CONSTRAINT cms_posts_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.super_admin_users(id);


--
-- Name: portal_banners portal_banners_created_by_fkey; Type: FK CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.portal_banners
    ADD CONSTRAINT portal_banners_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.super_admin_users(id);


--
-- Name: portal_banners portal_banners_image_media_id_fkey; Type: FK CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.portal_banners
    ADD CONSTRAINT portal_banners_image_media_id_fkey FOREIGN KEY (image_media_id) REFERENCES cms.cms_media(id) ON DELETE SET NULL;


--
-- Name: portal_banners portal_banners_updated_by_fkey; Type: FK CONSTRAINT; Schema: cms; Owner: -
--

ALTER TABLE ONLY cms.portal_banners
    ADD CONSTRAINT portal_banners_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.super_admin_users(id);


--
-- Name: attendance_audit_actions attendance_audit_actions_attendance_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.attendance_audit_actions
    ADD CONSTRAINT attendance_audit_actions_attendance_id_fkey FOREIGN KEY (attendance_id) REFERENCES employee.attendance_records(id) ON DELETE CASCADE;


--
-- Name: attendance_records attendance_records_branch_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.attendance_records
    ADD CONSTRAINT attendance_records_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE RESTRICT;


--
-- Name: attendance_records attendance_records_employee_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.attendance_records
    ADD CONSTRAINT attendance_records_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES employee.employees(id) ON DELETE CASCADE;


--
-- Name: attendance_records attendance_records_organization_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.attendance_records
    ADD CONSTRAINT attendance_records_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: branch_holidays branch_holidays_branch_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.branch_holidays
    ADD CONSTRAINT branch_holidays_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;


--
-- Name: branch_holidays branch_holidays_organization_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.branch_holidays
    ADD CONSTRAINT branch_holidays_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: branch_leave_policies branch_leave_accrual_rules_branch_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.branch_leave_policies
    ADD CONSTRAINT branch_leave_accrual_rules_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;


--
-- Name: branch_leave_policies branch_leave_accrual_rules_leave_type_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.branch_leave_policies
    ADD CONSTRAINT branch_leave_accrual_rules_leave_type_id_fkey FOREIGN KEY (leave_type_id) REFERENCES employee.leave_types(id) ON DELETE CASCADE;


--
-- Name: branch_leave_policies branch_leave_accrual_rules_organization_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.branch_leave_policies
    ADD CONSTRAINT branch_leave_accrual_rules_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: employee_actions employee_actions_employee_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.employee_actions
    ADD CONSTRAINT employee_actions_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES employee.employees(id) ON DELETE CASCADE;


--
-- Name: employee_actions employee_actions_organization_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.employee_actions
    ADD CONSTRAINT employee_actions_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: employees employees_branch_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.employees
    ADD CONSTRAINT employees_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE RESTRICT;


--
-- Name: employees employees_organization_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.employees
    ADD CONSTRAINT employees_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: leave_balances leave_balances_employee_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.leave_balances
    ADD CONSTRAINT leave_balances_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES employee.employees(id) ON DELETE CASCADE;


--
-- Name: leave_balances leave_balances_leave_type_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.leave_balances
    ADD CONSTRAINT leave_balances_leave_type_id_fkey FOREIGN KEY (leave_type_id) REFERENCES employee.leave_types(id) ON DELETE CASCADE;


--
-- Name: leave_requests leave_requests_branch_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.leave_requests
    ADD CONSTRAINT leave_requests_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE RESTRICT;


--
-- Name: leave_requests leave_requests_employee_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.leave_requests
    ADD CONSTRAINT leave_requests_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES employee.employees(id) ON DELETE CASCADE;


--
-- Name: leave_requests leave_requests_leave_type_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.leave_requests
    ADD CONSTRAINT leave_requests_leave_type_id_fkey FOREIGN KEY (leave_type_id) REFERENCES employee.leave_types(id);


--
-- Name: leave_requests leave_requests_organization_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.leave_requests
    ADD CONSTRAINT leave_requests_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: leave_types leave_types_organization_id_fkey; Type: FK CONSTRAINT; Schema: employee; Owner: -
--

ALTER TABLE ONLY employee.leave_types
    ADD CONSTRAINT leave_types_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: branches branches_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.super_admin_users(id);


--
-- Name: branches branches_kyc_verified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_kyc_verified_by_fkey FOREIGN KEY (kyc_verified_by) REFERENCES public.super_admin_users(id);


--
-- Name: branches branches_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: branches branches_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.states(id);


--
-- Name: org_status_actions org_status_actions_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_status_actions
    ADD CONSTRAINT org_status_actions_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: org_status_actions org_status_actions_performed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_status_actions
    ADD CONSTRAINT org_status_actions_performed_by_fkey FOREIGN KEY (performed_by) REFERENCES public.super_admin_users(id);


--
-- Name: org_status_actions org_status_actions_reason_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_status_actions
    ADD CONSTRAINT org_status_actions_reason_code_id_fkey FOREIGN KEY (reason_code_id) REFERENCES public.reason_codes(id);


--
-- Name: organizations organizations_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.super_admin_users(id);


--
-- Name: organizations organizations_kyc_verified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_kyc_verified_by_fkey FOREIGN KEY (kyc_verified_by) REFERENCES public.super_admin_users(id);


--
-- Name: organizations organizations_owner_disabled_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_owner_disabled_by_fkey FOREIGN KEY (owner_disabled_by) REFERENCES public.super_admin_users(id);


--
-- Name: organizations organizations_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.states(id);


--
-- Name: organizations organizations_status_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_status_changed_by_fkey FOREIGN KEY (status_changed_by) REFERENCES public.super_admin_users(id);


--
-- Name: organizations organizations_status_reason_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_status_reason_id_fkey FOREIGN KEY (status_reason_id) REFERENCES public.reason_codes(id);


--
-- Name: platform_commission_config platform_commission_config_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.platform_commission_config
    ADD CONSTRAINT platform_commission_config_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.super_admin_users(id);


--
-- Name: reason_codes reason_codes_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reason_codes
    ADD CONSTRAINT reason_codes_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.super_admin_users(id);


--
-- Name: reason_codes reason_codes_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reason_codes
    ADD CONSTRAINT reason_codes_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.super_admin_users(id);


--
-- Name: user_access_actions user_access_actions_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_access_actions
    ADD CONSTRAINT user_access_actions_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: user_access_actions user_access_actions_performed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_access_actions
    ADD CONSTRAINT user_access_actions_performed_by_fkey FOREIGN KEY (performed_by) REFERENCES public.super_admin_users(id);


--
-- Name: user_access_actions user_access_actions_sub_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_access_actions
    ADD CONSTRAINT user_access_actions_sub_admin_id_fkey FOREIGN KEY (sub_admin_id) REFERENCES admin_org.sub_admins(id) ON DELETE SET NULL;


--
-- Name: review_abuse_rules review_abuse_rules_created_by_fkey; Type: FK CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_abuse_rules
    ADD CONSTRAINT review_abuse_rules_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.super_admin_users(id);


--
-- Name: review_abuse_rules review_abuse_rules_updated_by_fkey; Type: FK CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_abuse_rules
    ADD CONSTRAINT review_abuse_rules_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.super_admin_users(id);


--
-- Name: review_images review_images_review_id_fkey; Type: FK CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_images
    ADD CONSTRAINT review_images_review_id_fkey FOREIGN KEY (review_id) REFERENCES review.reviews(id) ON DELETE CASCADE;


--
-- Name: review_moderation_actions review_moderation_actions_image_id_fkey; Type: FK CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_moderation_actions
    ADD CONSTRAINT review_moderation_actions_image_id_fkey FOREIGN KEY (image_id) REFERENCES review.review_images(id) ON DELETE SET NULL;


--
-- Name: review_moderation_actions review_moderation_actions_performed_by_fkey; Type: FK CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_moderation_actions
    ADD CONSTRAINT review_moderation_actions_performed_by_fkey FOREIGN KEY (performed_by) REFERENCES public.super_admin_users(id);


--
-- Name: review_moderation_actions review_moderation_actions_reply_id_fkey; Type: FK CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_moderation_actions
    ADD CONSTRAINT review_moderation_actions_reply_id_fkey FOREIGN KEY (reply_id) REFERENCES review.review_replies(id) ON DELETE SET NULL;


--
-- Name: review_moderation_actions review_moderation_actions_review_id_fkey; Type: FK CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_moderation_actions
    ADD CONSTRAINT review_moderation_actions_review_id_fkey FOREIGN KEY (review_id) REFERENCES review.reviews(id) ON DELETE CASCADE;


--
-- Name: review_moderation_settings review_moderation_settings_updated_by_fkey; Type: FK CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_moderation_settings
    ADD CONSTRAINT review_moderation_settings_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.super_admin_users(id);


--
-- Name: review_replies review_replies_organization_id_fkey; Type: FK CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_replies
    ADD CONSTRAINT review_replies_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: review_replies review_replies_review_id_fkey; Type: FK CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_replies
    ADD CONSTRAINT review_replies_review_id_fkey FOREIGN KEY (review_id) REFERENCES review.reviews(id) ON DELETE CASCADE;


--
-- Name: review_reports review_reports_reply_id_fkey; Type: FK CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_reports
    ADD CONSTRAINT review_reports_reply_id_fkey FOREIGN KEY (reply_id) REFERENCES review.review_replies(id) ON DELETE SET NULL;


--
-- Name: review_reports review_reports_resolved_by_fkey; Type: FK CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_reports
    ADD CONSTRAINT review_reports_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.super_admin_users(id);


--
-- Name: review_reports review_reports_review_id_fkey; Type: FK CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.review_reports
    ADD CONSTRAINT review_reports_review_id_fkey FOREIGN KEY (review_id) REFERENCES review.reviews(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_branch_id_fkey; Type: FK CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.reviews
    ADD CONSTRAINT reviews_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_organization_id_fkey; Type: FK CONSTRAINT; Schema: review; Owner: -
--

ALTER TABLE ONLY review.reviews
    ADD CONSTRAINT reviews_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: billing_discount_configs billing_discount_configs_billing_cycle_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.billing_discount_configs
    ADD CONSTRAINT billing_discount_configs_billing_cycle_id_fkey FOREIGN KEY (billing_cycle_id) REFERENCES rms.billing_cycles(id) ON DELETE CASCADE;


--
-- Name: billing_discount_configs billing_discount_configs_created_by_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.billing_discount_configs
    ADD CONSTRAINT billing_discount_configs_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.super_admin_users(id);


--
-- Name: billing_discount_configs billing_discount_configs_subscription_plan_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.billing_discount_configs
    ADD CONSTRAINT billing_discount_configs_subscription_plan_id_fkey FOREIGN KEY (subscription_plan_id) REFERENCES subscription.subscription_plans(id) ON DELETE CASCADE;


--
-- Name: billing_discount_configs billing_discount_configs_updated_by_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.billing_discount_configs
    ADD CONSTRAINT billing_discount_configs_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.super_admin_users(id);


--
-- Name: commission_rate_history commission_rate_history_changed_by_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.commission_rate_history
    ADD CONSTRAINT commission_rate_history_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.super_admin_users(id);


--
-- Name: commission_rate_history commission_rate_history_organization_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.commission_rate_history
    ADD CONSTRAINT commission_rate_history_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: credit_note_line_items credit_note_line_items_credit_note_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.credit_note_line_items
    ADD CONSTRAINT credit_note_line_items_credit_note_id_fkey FOREIGN KEY (credit_note_id) REFERENCES rms.credit_notes(id) ON DELETE CASCADE;


--
-- Name: credit_note_line_items credit_note_line_items_invoice_line_item_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.credit_note_line_items
    ADD CONSTRAINT credit_note_line_items_invoice_line_item_id_fkey FOREIGN KEY (invoice_line_item_id) REFERENCES rms.invoice_line_items(id) ON DELETE SET NULL;


--
-- Name: credit_notes credit_notes_applied_to_invoice_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.credit_notes
    ADD CONSTRAINT credit_notes_applied_to_invoice_id_fkey FOREIGN KEY (applied_to_invoice_id) REFERENCES rms.invoices(id) ON DELETE SET NULL;


--
-- Name: credit_notes credit_notes_created_by_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.credit_notes
    ADD CONSTRAINT credit_notes_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.super_admin_users(id);


--
-- Name: credit_notes credit_notes_invoice_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.credit_notes
    ADD CONSTRAINT credit_notes_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES rms.invoices(id) ON DELETE RESTRICT;


--
-- Name: end_user_transactions end_user_transactions_branch_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.end_user_transactions
    ADD CONSTRAINT end_user_transactions_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: end_user_transactions end_user_transactions_organization_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.end_user_transactions
    ADD CONSTRAINT end_user_transactions_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: end_user_transactions end_user_transactions_salon_payout_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.end_user_transactions
    ADD CONSTRAINT end_user_transactions_salon_payout_id_fkey FOREIGN KEY (salon_payout_id) REFERENCES rms.salon_payouts(id) ON DELETE SET NULL;


--
-- Name: invoice_line_items invoice_line_items_billing_cycle_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.invoice_line_items
    ADD CONSTRAINT invoice_line_items_billing_cycle_id_fkey FOREIGN KEY (billing_cycle_id) REFERENCES rms.billing_cycles(id);


--
-- Name: invoice_line_items invoice_line_items_invoice_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.invoice_line_items
    ADD CONSTRAINT invoice_line_items_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES rms.invoices(id) ON DELETE CASCADE;


--
-- Name: invoice_line_items invoice_line_items_subscription_plan_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.invoice_line_items
    ADD CONSTRAINT invoice_line_items_subscription_plan_id_fkey FOREIGN KEY (subscription_plan_id) REFERENCES subscription.subscription_plans(id);


--
-- Name: invoice_payments invoice_payments_invoice_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.invoice_payments
    ADD CONSTRAINT invoice_payments_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES rms.invoices(id) ON DELETE CASCADE;


--
-- Name: invoice_payments invoice_payments_payment_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.invoice_payments
    ADD CONSTRAINT invoice_payments_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES rms.payments(id) ON DELETE CASCADE;


--
-- Name: invoice_tax_lines invoice_tax_lines_invoice_line_item_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.invoice_tax_lines
    ADD CONSTRAINT invoice_tax_lines_invoice_line_item_id_fkey FOREIGN KEY (invoice_line_item_id) REFERENCES rms.invoice_line_items(id) ON DELETE CASCADE;


--
-- Name: invoice_tax_lines invoice_tax_lines_state_tax_config_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.invoice_tax_lines
    ADD CONSTRAINT invoice_tax_lines_state_tax_config_id_fkey FOREIGN KEY (state_tax_config_id) REFERENCES rms.state_tax_configs(id);


--
-- Name: invoices invoices_created_by_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.invoices
    ADD CONSTRAINT invoices_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.super_admin_users(id);


--
-- Name: invoices invoices_org_bill_structure_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.invoices
    ADD CONSTRAINT invoices_org_bill_structure_id_fkey FOREIGN KEY (org_bill_structure_id) REFERENCES rms.org_bill_structure(id) ON DELETE SET NULL;


--
-- Name: invoices invoices_org_subscription_change_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.invoices
    ADD CONSTRAINT invoices_org_subscription_change_id_fkey FOREIGN KEY (org_subscription_change_id) REFERENCES subscription.org_subscription_changes(id) ON DELETE SET NULL;


--
-- Name: invoices invoices_organization_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.invoices
    ADD CONSTRAINT invoices_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: merchant_ledger_entries merchant_ledger_entries_created_by_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.merchant_ledger_entries
    ADD CONSTRAINT merchant_ledger_entries_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.super_admin_users(id);


--
-- Name: merchant_ledger_entries merchant_ledger_entries_end_user_transaction_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.merchant_ledger_entries
    ADD CONSTRAINT merchant_ledger_entries_end_user_transaction_id_fkey FOREIGN KEY (end_user_transaction_id) REFERENCES rms.end_user_transactions(id) ON DELETE SET NULL;


--
-- Name: merchant_ledger_entries merchant_ledger_entries_invoice_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.merchant_ledger_entries
    ADD CONSTRAINT merchant_ledger_entries_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES rms.invoices(id) ON DELETE SET NULL;


--
-- Name: merchant_ledger_entries merchant_ledger_entries_organization_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.merchant_ledger_entries
    ADD CONSTRAINT merchant_ledger_entries_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: merchant_ledger_entries merchant_ledger_entries_payment_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.merchant_ledger_entries
    ADD CONSTRAINT merchant_ledger_entries_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES rms.payments(id) ON DELETE SET NULL;


--
-- Name: merchant_ledger_entries merchant_ledger_entries_salon_payout_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.merchant_ledger_entries
    ADD CONSTRAINT merchant_ledger_entries_salon_payout_id_fkey FOREIGN KEY (salon_payout_id) REFERENCES rms.salon_payouts(id) ON DELETE SET NULL;


--
-- Name: org_bill_structure org_bill_structure_billing_cycle_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.org_bill_structure
    ADD CONSTRAINT org_bill_structure_billing_cycle_id_fkey FOREIGN KEY (billing_cycle_id) REFERENCES rms.billing_cycles(id);


--
-- Name: org_bill_structure org_bill_structure_configured_by_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.org_bill_structure
    ADD CONSTRAINT org_bill_structure_configured_by_fkey FOREIGN KEY (configured_by) REFERENCES public.super_admin_users(id);


--
-- Name: org_bill_structure org_bill_structure_organization_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.org_bill_structure
    ADD CONSTRAINT org_bill_structure_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: org_bill_structure org_bill_structure_state_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.org_bill_structure
    ADD CONSTRAINT org_bill_structure_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.states(id);


--
-- Name: org_bill_structure org_bill_structure_subscription_plan_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.org_bill_structure
    ADD CONSTRAINT org_bill_structure_subscription_plan_id_fkey FOREIGN KEY (subscription_plan_id) REFERENCES subscription.subscription_plans(id);


--
-- Name: org_merchant_balances org_merchant_balances_organization_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.org_merchant_balances
    ADD CONSTRAINT org_merchant_balances_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: payments payments_created_by_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.payments
    ADD CONSTRAINT payments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.super_admin_users(id);


--
-- Name: payments payments_organization_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.payments
    ADD CONSTRAINT payments_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: refunds refunds_created_by_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.refunds
    ADD CONSTRAINT refunds_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.super_admin_users(id);


--
-- Name: refunds refunds_credit_note_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.refunds
    ADD CONSTRAINT refunds_credit_note_id_fkey FOREIGN KEY (credit_note_id) REFERENCES rms.credit_notes(id) ON DELETE SET NULL;


--
-- Name: refunds refunds_payment_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.refunds
    ADD CONSTRAINT refunds_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES rms.payments(id) ON DELETE RESTRICT;


--
-- Name: salon_payout_items salon_payout_items_end_user_transaction_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.salon_payout_items
    ADD CONSTRAINT salon_payout_items_end_user_transaction_id_fkey FOREIGN KEY (end_user_transaction_id) REFERENCES rms.end_user_transactions(id) ON DELETE SET NULL;


--
-- Name: salon_payout_items salon_payout_items_payout_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.salon_payout_items
    ADD CONSTRAINT salon_payout_items_payout_id_fkey FOREIGN KEY (payout_id) REFERENCES rms.salon_payouts(id) ON DELETE CASCADE;


--
-- Name: salon_payouts salon_payouts_created_by_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.salon_payouts
    ADD CONSTRAINT salon_payouts_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.super_admin_users(id);


--
-- Name: salon_payouts salon_payouts_organization_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.salon_payouts
    ADD CONSTRAINT salon_payouts_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: state_tax_configs state_tax_configs_created_by_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.state_tax_configs
    ADD CONSTRAINT state_tax_configs_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.super_admin_users(id);


--
-- Name: state_tax_configs state_tax_configs_state_id_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.state_tax_configs
    ADD CONSTRAINT state_tax_configs_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.states(id) ON DELETE CASCADE;


--
-- Name: state_tax_configs state_tax_configs_updated_by_fkey; Type: FK CONSTRAINT; Schema: rms; Owner: -
--

ALTER TABLE ONLY rms.state_tax_configs
    ADD CONSTRAINT state_tax_configs_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.super_admin_users(id);


--
-- Name: branch_service_specialists branch_service_specialists_branch_service_id_fkey; Type: FK CONSTRAINT; Schema: services; Owner: -
--

ALTER TABLE ONLY services.branch_service_specialists
    ADD CONSTRAINT branch_service_specialists_branch_service_id_fkey FOREIGN KEY (branch_service_id) REFERENCES services.branch_services(id) ON DELETE CASCADE;


--
-- Name: branch_service_specialists branch_service_specialists_employee_id_fkey; Type: FK CONSTRAINT; Schema: services; Owner: -
--

ALTER TABLE ONLY services.branch_service_specialists
    ADD CONSTRAINT branch_service_specialists_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES employee.employees(id) ON DELETE CASCADE;


--
-- Name: branch_services branch_services_branch_id_fkey; Type: FK CONSTRAINT; Schema: services; Owner: -
--

ALTER TABLE ONLY services.branch_services
    ADD CONSTRAINT branch_services_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;


--
-- Name: branch_services branch_services_category_id_fkey; Type: FK CONSTRAINT; Schema: services; Owner: -
--

ALTER TABLE ONLY services.branch_services
    ADD CONSTRAINT branch_services_category_id_fkey FOREIGN KEY (category_id) REFERENCES services.service_categories(id) ON DELETE RESTRICT;


--
-- Name: branch_services branch_services_organization_id_fkey; Type: FK CONSTRAINT; Schema: services; Owner: -
--

ALTER TABLE ONLY services.branch_services
    ADD CONSTRAINT branch_services_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: branch_services branch_services_subcategory_id_fkey; Type: FK CONSTRAINT; Schema: services; Owner: -
--

ALTER TABLE ONLY services.branch_services
    ADD CONSTRAINT branch_services_subcategory_id_fkey FOREIGN KEY (subcategory_id) REFERENCES services.service_subcategories(id) ON DELETE RESTRICT;


--
-- Name: service_categories service_categories_created_by_fkey; Type: FK CONSTRAINT; Schema: services; Owner: -
--

ALTER TABLE ONLY services.service_categories
    ADD CONSTRAINT service_categories_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.super_admin_users(id);


--
-- Name: service_categories service_categories_updated_by_fkey; Type: FK CONSTRAINT; Schema: services; Owner: -
--

ALTER TABLE ONLY services.service_categories
    ADD CONSTRAINT service_categories_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.super_admin_users(id);


--
-- Name: service_subcategories service_subcategories_category_id_fkey; Type: FK CONSTRAINT; Schema: services; Owner: -
--

ALTER TABLE ONLY services.service_subcategories
    ADD CONSTRAINT service_subcategories_category_id_fkey FOREIGN KEY (category_id) REFERENCES services.service_categories(id) ON DELETE CASCADE;


--
-- Name: service_subcategories service_subcategories_created_by_fkey; Type: FK CONSTRAINT; Schema: services; Owner: -
--

ALTER TABLE ONLY services.service_subcategories
    ADD CONSTRAINT service_subcategories_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.super_admin_users(id);


--
-- Name: service_subcategories service_subcategories_updated_by_fkey; Type: FK CONSTRAINT; Schema: services; Owner: -
--

ALTER TABLE ONLY services.service_subcategories
    ADD CONSTRAINT service_subcategories_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.super_admin_users(id);


--
-- Name: org_subscription_changes org_subscription_changes_from_billing_cycle_id_fkey; Type: FK CONSTRAINT; Schema: subscription; Owner: -
--

ALTER TABLE ONLY subscription.org_subscription_changes
    ADD CONSTRAINT org_subscription_changes_from_billing_cycle_id_fkey FOREIGN KEY (from_billing_cycle_id) REFERENCES rms.billing_cycles(id);


--
-- Name: org_subscription_changes org_subscription_changes_from_subscription_plan_id_fkey; Type: FK CONSTRAINT; Schema: subscription; Owner: -
--

ALTER TABLE ONLY subscription.org_subscription_changes
    ADD CONSTRAINT org_subscription_changes_from_subscription_plan_id_fkey FOREIGN KEY (from_subscription_plan_id) REFERENCES subscription.subscription_plans(id);


--
-- Name: org_subscription_changes org_subscription_changes_org_bill_structure_id_fkey; Type: FK CONSTRAINT; Schema: subscription; Owner: -
--

ALTER TABLE ONLY subscription.org_subscription_changes
    ADD CONSTRAINT org_subscription_changes_org_bill_structure_id_fkey FOREIGN KEY (org_bill_structure_id) REFERENCES rms.org_bill_structure(id) ON DELETE CASCADE;


--
-- Name: org_subscription_changes org_subscription_changes_organization_id_fkey; Type: FK CONSTRAINT; Schema: subscription; Owner: -
--

ALTER TABLE ONLY subscription.org_subscription_changes
    ADD CONSTRAINT org_subscription_changes_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: org_subscription_changes org_subscription_changes_performed_by_fkey; Type: FK CONSTRAINT; Schema: subscription; Owner: -
--

ALTER TABLE ONLY subscription.org_subscription_changes
    ADD CONSTRAINT org_subscription_changes_performed_by_fkey FOREIGN KEY (performed_by) REFERENCES public.super_admin_users(id);


--
-- Name: org_subscription_changes org_subscription_changes_to_billing_cycle_id_fkey; Type: FK CONSTRAINT; Schema: subscription; Owner: -
--

ALTER TABLE ONLY subscription.org_subscription_changes
    ADD CONSTRAINT org_subscription_changes_to_billing_cycle_id_fkey FOREIGN KEY (to_billing_cycle_id) REFERENCES rms.billing_cycles(id);


--
-- Name: org_subscription_changes org_subscription_changes_to_subscription_plan_id_fkey; Type: FK CONSTRAINT; Schema: subscription; Owner: -
--

ALTER TABLE ONLY subscription.org_subscription_changes
    ADD CONSTRAINT org_subscription_changes_to_subscription_plan_id_fkey FOREIGN KEY (to_subscription_plan_id) REFERENCES subscription.subscription_plans(id);


--
-- Name: support_sla_policies support_sla_policies_updated_by_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_sla_policies
    ADD CONSTRAINT support_sla_policies_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.super_admin_users(id);


--
-- Name: support_ticket_attachments support_ticket_attachments_message_id_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_attachments
    ADD CONSTRAINT support_ticket_attachments_message_id_fkey FOREIGN KEY (message_id) REFERENCES tickets.support_ticket_messages(id) ON DELETE SET NULL;


--
-- Name: support_ticket_attachments support_ticket_attachments_ticket_id_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_attachments
    ADD CONSTRAINT support_ticket_attachments_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES tickets.support_tickets(id) ON DELETE CASCADE;


--
-- Name: support_ticket_categories support_ticket_categories_created_by_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_categories
    ADD CONSTRAINT support_ticket_categories_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.super_admin_users(id);


--
-- Name: support_ticket_categories support_ticket_categories_updated_by_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_categories
    ADD CONSTRAINT support_ticket_categories_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.super_admin_users(id);


--
-- Name: support_ticket_events support_ticket_events_performed_by_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_events
    ADD CONSTRAINT support_ticket_events_performed_by_fkey FOREIGN KEY (performed_by) REFERENCES public.super_admin_users(id);


--
-- Name: support_ticket_events support_ticket_events_ticket_id_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_events
    ADD CONSTRAINT support_ticket_events_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES tickets.support_tickets(id) ON DELETE CASCADE;


--
-- Name: support_ticket_internal_notes support_ticket_internal_notes_created_by_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_internal_notes
    ADD CONSTRAINT support_ticket_internal_notes_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.super_admin_users(id);


--
-- Name: support_ticket_internal_notes support_ticket_internal_notes_ticket_id_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_internal_notes
    ADD CONSTRAINT support_ticket_internal_notes_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES tickets.support_tickets(id) ON DELETE CASCADE;


--
-- Name: support_ticket_messages support_ticket_messages_author_super_admin_id_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_messages
    ADD CONSTRAINT support_ticket_messages_author_super_admin_id_fkey FOREIGN KEY (author_super_admin_id) REFERENCES public.super_admin_users(id);


--
-- Name: support_ticket_messages support_ticket_messages_ticket_id_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_messages
    ADD CONSTRAINT support_ticket_messages_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES tickets.support_tickets(id) ON DELETE CASCADE;


--
-- Name: support_ticket_subtypes support_ticket_subtypes_type_id_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_subtypes
    ADD CONSTRAINT support_ticket_subtypes_type_id_fkey FOREIGN KEY (type_id) REFERENCES tickets.support_ticket_types(id) ON DELETE CASCADE;


--
-- Name: support_ticket_types support_ticket_types_category_id_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_ticket_types
    ADD CONSTRAINT support_ticket_types_category_id_fkey FOREIGN KEY (category_id) REFERENCES tickets.support_ticket_categories(id) ON DELETE CASCADE;


--
-- Name: support_tickets support_tickets_assigned_to_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_tickets
    ADD CONSTRAINT support_tickets_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.super_admin_users(id);


--
-- Name: support_tickets support_tickets_branch_id_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_tickets
    ADD CONSTRAINT support_tickets_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE SET NULL;


--
-- Name: support_tickets support_tickets_category_id_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_tickets
    ADD CONSTRAINT support_tickets_category_id_fkey FOREIGN KEY (category_id) REFERENCES tickets.support_ticket_categories(id);


--
-- Name: support_tickets support_tickets_created_by_super_admin_id_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_tickets
    ADD CONSTRAINT support_tickets_created_by_super_admin_id_fkey FOREIGN KEY (created_by_super_admin_id) REFERENCES public.super_admin_users(id);


--
-- Name: support_tickets support_tickets_organization_id_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_tickets
    ADD CONSTRAINT support_tickets_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE SET NULL;


--
-- Name: support_tickets support_tickets_sla_policy_id_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_tickets
    ADD CONSTRAINT support_tickets_sla_policy_id_fkey FOREIGN KEY (sla_policy_id) REFERENCES tickets.support_sla_policies(id);


--
-- Name: support_tickets support_tickets_subtype_id_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_tickets
    ADD CONSTRAINT support_tickets_subtype_id_fkey FOREIGN KEY (subtype_id) REFERENCES tickets.support_ticket_subtypes(id);


--
-- Name: support_tickets support_tickets_type_id_fkey; Type: FK CONSTRAINT; Schema: tickets; Owner: -
--

ALTER TABLE ONLY tickets.support_tickets
    ADD CONSTRAINT support_tickets_type_id_fkey FOREIGN KEY (type_id) REFERENCES tickets.support_ticket_types(id);


--
-- Name: sub_admin_branches data_api_authenticated_all; Type: POLICY; Schema: admin_org; Owner: -
--

CREATE POLICY data_api_authenticated_all ON admin_org.sub_admin_branches TO authenticated USING (true) WITH CHECK (true);


--
-- Name: sub_admin_modules data_api_authenticated_all; Type: POLICY; Schema: admin_org; Owner: -
--

CREATE POLICY data_api_authenticated_all ON admin_org.sub_admin_modules TO authenticated USING (true) WITH CHECK (true);


--
-- Name: sub_admins data_api_authenticated_all; Type: POLICY; Schema: admin_org; Owner: -
--

CREATE POLICY data_api_authenticated_all ON admin_org.sub_admins TO authenticated USING (true) WITH CHECK (true);


--
-- Name: sub_admin_branches; Type: ROW SECURITY; Schema: admin_org; Owner: -
--

ALTER TABLE admin_org.sub_admin_branches ENABLE ROW LEVEL SECURITY;

--
-- Name: sub_admin_modules; Type: ROW SECURITY; Schema: admin_org; Owner: -
--

ALTER TABLE admin_org.sub_admin_modules ENABLE ROW LEVEL SECURITY;

--
-- Name: sub_admins; Type: ROW SECURITY; Schema: admin_org; Owner: -
--

ALTER TABLE admin_org.sub_admins ENABLE ROW LEVEL SECURITY;

--
-- Name: cms_media; Type: ROW SECURITY; Schema: cms; Owner: -
--

ALTER TABLE cms.cms_media ENABLE ROW LEVEL SECURITY;

--
-- Name: cms_pages; Type: ROW SECURITY; Schema: cms; Owner: -
--

ALTER TABLE cms.cms_pages ENABLE ROW LEVEL SECURITY;

--
-- Name: cms_posts; Type: ROW SECURITY; Schema: cms; Owner: -
--

ALTER TABLE cms.cms_posts ENABLE ROW LEVEL SECURITY;

--
-- Name: cms_media data_api_authenticated_all; Type: POLICY; Schema: cms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON cms.cms_media TO authenticated USING (true) WITH CHECK (true);


--
-- Name: cms_pages data_api_authenticated_all; Type: POLICY; Schema: cms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON cms.cms_pages TO authenticated USING (true) WITH CHECK (true);


--
-- Name: cms_posts data_api_authenticated_all; Type: POLICY; Schema: cms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON cms.cms_posts TO authenticated USING (true) WITH CHECK (true);


--
-- Name: portal_banners data_api_authenticated_all; Type: POLICY; Schema: cms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON cms.portal_banners TO authenticated USING (true) WITH CHECK (true);


--
-- Name: portal_banners; Type: ROW SECURITY; Schema: cms; Owner: -
--

ALTER TABLE cms.portal_banners ENABLE ROW LEVEL SECURITY;

--
-- Name: branches; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;

--
-- Name: branches data_api_authenticated_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY data_api_authenticated_all ON public.branches TO authenticated USING (true) WITH CHECK (true);


--
-- Name: org_status_actions data_api_authenticated_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY data_api_authenticated_all ON public.org_status_actions TO authenticated USING (true) WITH CHECK (true);


--
-- Name: organizations data_api_authenticated_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY data_api_authenticated_all ON public.organizations TO authenticated USING (true) WITH CHECK (true);


--
-- Name: platform_commission_config data_api_authenticated_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY data_api_authenticated_all ON public.platform_commission_config TO authenticated USING (true) WITH CHECK (true);


--
-- Name: reason_codes data_api_authenticated_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY data_api_authenticated_all ON public.reason_codes TO authenticated USING (true) WITH CHECK (true);


--
-- Name: states data_api_authenticated_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY data_api_authenticated_all ON public.states TO authenticated USING (true) WITH CHECK (true);


--
-- Name: super_admin_users data_api_authenticated_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY data_api_authenticated_all ON public.super_admin_users TO authenticated USING (true) WITH CHECK (true);


--
-- Name: user_access_actions data_api_authenticated_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY data_api_authenticated_all ON public.user_access_actions TO authenticated USING (true) WITH CHECK (true);


--
-- Name: org_status_actions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.org_status_actions ENABLE ROW LEVEL SECURITY;

--
-- Name: organizations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

--
-- Name: platform_commission_config; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.platform_commission_config ENABLE ROW LEVEL SECURITY;

--
-- Name: reason_codes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.reason_codes ENABLE ROW LEVEL SECURITY;

--
-- Name: states; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.states ENABLE ROW LEVEL SECURITY;

--
-- Name: super_admin_users; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.super_admin_users ENABLE ROW LEVEL SECURITY;

--
-- Name: user_access_actions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_access_actions ENABLE ROW LEVEL SECURITY;

--
-- Name: review_abuse_rules data_api_authenticated_all; Type: POLICY; Schema: review; Owner: -
--

CREATE POLICY data_api_authenticated_all ON review.review_abuse_rules TO authenticated USING (true) WITH CHECK (true);


--
-- Name: review_images data_api_authenticated_all; Type: POLICY; Schema: review; Owner: -
--

CREATE POLICY data_api_authenticated_all ON review.review_images TO authenticated USING (true) WITH CHECK (true);


--
-- Name: review_moderation_actions data_api_authenticated_all; Type: POLICY; Schema: review; Owner: -
--

CREATE POLICY data_api_authenticated_all ON review.review_moderation_actions TO authenticated USING (true) WITH CHECK (true);


--
-- Name: review_moderation_settings data_api_authenticated_all; Type: POLICY; Schema: review; Owner: -
--

CREATE POLICY data_api_authenticated_all ON review.review_moderation_settings TO authenticated USING (true) WITH CHECK (true);


--
-- Name: review_replies data_api_authenticated_all; Type: POLICY; Schema: review; Owner: -
--

CREATE POLICY data_api_authenticated_all ON review.review_replies TO authenticated USING (true) WITH CHECK (true);


--
-- Name: review_reports data_api_authenticated_all; Type: POLICY; Schema: review; Owner: -
--

CREATE POLICY data_api_authenticated_all ON review.review_reports TO authenticated USING (true) WITH CHECK (true);


--
-- Name: reviews data_api_authenticated_all; Type: POLICY; Schema: review; Owner: -
--

CREATE POLICY data_api_authenticated_all ON review.reviews TO authenticated USING (true) WITH CHECK (true);


--
-- Name: review_abuse_rules; Type: ROW SECURITY; Schema: review; Owner: -
--

ALTER TABLE review.review_abuse_rules ENABLE ROW LEVEL SECURITY;

--
-- Name: review_images; Type: ROW SECURITY; Schema: review; Owner: -
--

ALTER TABLE review.review_images ENABLE ROW LEVEL SECURITY;

--
-- Name: review_moderation_actions; Type: ROW SECURITY; Schema: review; Owner: -
--

ALTER TABLE review.review_moderation_actions ENABLE ROW LEVEL SECURITY;

--
-- Name: review_moderation_settings; Type: ROW SECURITY; Schema: review; Owner: -
--

ALTER TABLE review.review_moderation_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: review_replies; Type: ROW SECURITY; Schema: review; Owner: -
--

ALTER TABLE review.review_replies ENABLE ROW LEVEL SECURITY;

--
-- Name: review_reports; Type: ROW SECURITY; Schema: review; Owner: -
--

ALTER TABLE review.review_reports ENABLE ROW LEVEL SECURITY;

--
-- Name: reviews; Type: ROW SECURITY; Schema: review; Owner: -
--

ALTER TABLE review.reviews ENABLE ROW LEVEL SECURITY;

--
-- Name: billing_cycles; Type: ROW SECURITY; Schema: rms; Owner: -
--

ALTER TABLE rms.billing_cycles ENABLE ROW LEVEL SECURITY;

--
-- Name: billing_discount_configs; Type: ROW SECURITY; Schema: rms; Owner: -
--

ALTER TABLE rms.billing_discount_configs ENABLE ROW LEVEL SECURITY;

--
-- Name: commission_rate_history; Type: ROW SECURITY; Schema: rms; Owner: -
--

ALTER TABLE rms.commission_rate_history ENABLE ROW LEVEL SECURITY;

--
-- Name: credit_note_line_items; Type: ROW SECURITY; Schema: rms; Owner: -
--

ALTER TABLE rms.credit_note_line_items ENABLE ROW LEVEL SECURITY;

--
-- Name: credit_notes; Type: ROW SECURITY; Schema: rms; Owner: -
--

ALTER TABLE rms.credit_notes ENABLE ROW LEVEL SECURITY;

--
-- Name: billing_cycles data_api_authenticated_all; Type: POLICY; Schema: rms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON rms.billing_cycles TO authenticated USING (true) WITH CHECK (true);


--
-- Name: billing_discount_configs data_api_authenticated_all; Type: POLICY; Schema: rms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON rms.billing_discount_configs TO authenticated USING (true) WITH CHECK (true);


--
-- Name: commission_rate_history data_api_authenticated_all; Type: POLICY; Schema: rms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON rms.commission_rate_history TO authenticated USING (true) WITH CHECK (true);


--
-- Name: credit_note_line_items data_api_authenticated_all; Type: POLICY; Schema: rms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON rms.credit_note_line_items TO authenticated USING (true) WITH CHECK (true);


--
-- Name: credit_notes data_api_authenticated_all; Type: POLICY; Schema: rms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON rms.credit_notes TO authenticated USING (true) WITH CHECK (true);


--
-- Name: end_user_transactions data_api_authenticated_all; Type: POLICY; Schema: rms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON rms.end_user_transactions TO authenticated USING (true) WITH CHECK (true);


--
-- Name: invoice_line_items data_api_authenticated_all; Type: POLICY; Schema: rms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON rms.invoice_line_items TO authenticated USING (true) WITH CHECK (true);


--
-- Name: invoice_payments data_api_authenticated_all; Type: POLICY; Schema: rms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON rms.invoice_payments TO authenticated USING (true) WITH CHECK (true);


--
-- Name: invoice_tax_lines data_api_authenticated_all; Type: POLICY; Schema: rms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON rms.invoice_tax_lines TO authenticated USING (true) WITH CHECK (true);


--
-- Name: invoices data_api_authenticated_all; Type: POLICY; Schema: rms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON rms.invoices TO authenticated USING (true) WITH CHECK (true);


--
-- Name: merchant_ledger_entries data_api_authenticated_all; Type: POLICY; Schema: rms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON rms.merchant_ledger_entries TO authenticated USING (true) WITH CHECK (true);


--
-- Name: org_bill_structure data_api_authenticated_all; Type: POLICY; Schema: rms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON rms.org_bill_structure TO authenticated USING (true) WITH CHECK (true);


--
-- Name: org_merchant_balances data_api_authenticated_all; Type: POLICY; Schema: rms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON rms.org_merchant_balances TO authenticated USING (true) WITH CHECK (true);


--
-- Name: payments data_api_authenticated_all; Type: POLICY; Schema: rms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON rms.payments TO authenticated USING (true) WITH CHECK (true);


--
-- Name: refunds data_api_authenticated_all; Type: POLICY; Schema: rms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON rms.refunds TO authenticated USING (true) WITH CHECK (true);


--
-- Name: salon_payout_items data_api_authenticated_all; Type: POLICY; Schema: rms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON rms.salon_payout_items TO authenticated USING (true) WITH CHECK (true);


--
-- Name: salon_payouts data_api_authenticated_all; Type: POLICY; Schema: rms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON rms.salon_payouts TO authenticated USING (true) WITH CHECK (true);


--
-- Name: state_tax_configs data_api_authenticated_all; Type: POLICY; Schema: rms; Owner: -
--

CREATE POLICY data_api_authenticated_all ON rms.state_tax_configs TO authenticated USING (true) WITH CHECK (true);


--
-- Name: end_user_transactions; Type: ROW SECURITY; Schema: rms; Owner: -
--

ALTER TABLE rms.end_user_transactions ENABLE ROW LEVEL SECURITY;

--
-- Name: invoice_line_items; Type: ROW SECURITY; Schema: rms; Owner: -
--

ALTER TABLE rms.invoice_line_items ENABLE ROW LEVEL SECURITY;

--
-- Name: invoice_payments; Type: ROW SECURITY; Schema: rms; Owner: -
--

ALTER TABLE rms.invoice_payments ENABLE ROW LEVEL SECURITY;

--
-- Name: invoice_tax_lines; Type: ROW SECURITY; Schema: rms; Owner: -
--

ALTER TABLE rms.invoice_tax_lines ENABLE ROW LEVEL SECURITY;

--
-- Name: invoices; Type: ROW SECURITY; Schema: rms; Owner: -
--

ALTER TABLE rms.invoices ENABLE ROW LEVEL SECURITY;

--
-- Name: merchant_ledger_entries; Type: ROW SECURITY; Schema: rms; Owner: -
--

ALTER TABLE rms.merchant_ledger_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: org_bill_structure; Type: ROW SECURITY; Schema: rms; Owner: -
--

ALTER TABLE rms.org_bill_structure ENABLE ROW LEVEL SECURITY;

--
-- Name: org_merchant_balances; Type: ROW SECURITY; Schema: rms; Owner: -
--

ALTER TABLE rms.org_merchant_balances ENABLE ROW LEVEL SECURITY;

--
-- Name: payments; Type: ROW SECURITY; Schema: rms; Owner: -
--

ALTER TABLE rms.payments ENABLE ROW LEVEL SECURITY;

--
-- Name: refunds; Type: ROW SECURITY; Schema: rms; Owner: -
--

ALTER TABLE rms.refunds ENABLE ROW LEVEL SECURITY;

--
-- Name: salon_payout_items; Type: ROW SECURITY; Schema: rms; Owner: -
--

ALTER TABLE rms.salon_payout_items ENABLE ROW LEVEL SECURITY;

--
-- Name: salon_payouts; Type: ROW SECURITY; Schema: rms; Owner: -
--

ALTER TABLE rms.salon_payouts ENABLE ROW LEVEL SECURITY;

--
-- Name: state_tax_configs; Type: ROW SECURITY; Schema: rms; Owner: -
--

ALTER TABLE rms.state_tax_configs ENABLE ROW LEVEL SECURITY;

--
-- Name: service_categories data_api_authenticated_all; Type: POLICY; Schema: services; Owner: -
--

CREATE POLICY data_api_authenticated_all ON services.service_categories TO authenticated USING (true) WITH CHECK (true);


--
-- Name: service_subcategories data_api_authenticated_all; Type: POLICY; Schema: services; Owner: -
--

CREATE POLICY data_api_authenticated_all ON services.service_subcategories TO authenticated USING (true) WITH CHECK (true);


--
-- Name: service_categories; Type: ROW SECURITY; Schema: services; Owner: -
--

ALTER TABLE services.service_categories ENABLE ROW LEVEL SECURITY;

--
-- Name: service_subcategories; Type: ROW SECURITY; Schema: services; Owner: -
--

ALTER TABLE services.service_subcategories ENABLE ROW LEVEL SECURITY;

--
-- Name: org_subscription_changes data_api_authenticated_all; Type: POLICY; Schema: subscription; Owner: -
--

CREATE POLICY data_api_authenticated_all ON subscription.org_subscription_changes TO authenticated USING (true) WITH CHECK (true);


--
-- Name: subscription_plans data_api_authenticated_all; Type: POLICY; Schema: subscription; Owner: -
--

CREATE POLICY data_api_authenticated_all ON subscription.subscription_plans TO authenticated USING (true) WITH CHECK (true);


--
-- Name: org_subscription_changes; Type: ROW SECURITY; Schema: subscription; Owner: -
--

ALTER TABLE subscription.org_subscription_changes ENABLE ROW LEVEL SECURITY;

--
-- Name: subscription_plans; Type: ROW SECURITY; Schema: subscription; Owner: -
--

ALTER TABLE subscription.subscription_plans ENABLE ROW LEVEL SECURITY;

--
-- Name: support_sla_policies data_api_authenticated_all; Type: POLICY; Schema: tickets; Owner: -
--

CREATE POLICY data_api_authenticated_all ON tickets.support_sla_policies TO authenticated USING (true) WITH CHECK (true);


--
-- Name: support_ticket_attachments data_api_authenticated_all; Type: POLICY; Schema: tickets; Owner: -
--

CREATE POLICY data_api_authenticated_all ON tickets.support_ticket_attachments TO authenticated USING (true) WITH CHECK (true);


--
-- Name: support_ticket_categories data_api_authenticated_all; Type: POLICY; Schema: tickets; Owner: -
--

CREATE POLICY data_api_authenticated_all ON tickets.support_ticket_categories TO authenticated USING (true) WITH CHECK (true);


--
-- Name: support_ticket_events data_api_authenticated_all; Type: POLICY; Schema: tickets; Owner: -
--

CREATE POLICY data_api_authenticated_all ON tickets.support_ticket_events TO authenticated USING (true) WITH CHECK (true);


--
-- Name: support_ticket_internal_notes data_api_authenticated_all; Type: POLICY; Schema: tickets; Owner: -
--

CREATE POLICY data_api_authenticated_all ON tickets.support_ticket_internal_notes TO authenticated USING (true) WITH CHECK (true);


--
-- Name: support_ticket_messages data_api_authenticated_all; Type: POLICY; Schema: tickets; Owner: -
--

CREATE POLICY data_api_authenticated_all ON tickets.support_ticket_messages TO authenticated USING (true) WITH CHECK (true);


--
-- Name: support_ticket_subtypes data_api_authenticated_all; Type: POLICY; Schema: tickets; Owner: -
--

CREATE POLICY data_api_authenticated_all ON tickets.support_ticket_subtypes TO authenticated USING (true) WITH CHECK (true);


--
-- Name: support_ticket_types data_api_authenticated_all; Type: POLICY; Schema: tickets; Owner: -
--

CREATE POLICY data_api_authenticated_all ON tickets.support_ticket_types TO authenticated USING (true) WITH CHECK (true);


--
-- Name: support_tickets data_api_authenticated_all; Type: POLICY; Schema: tickets; Owner: -
--

CREATE POLICY data_api_authenticated_all ON tickets.support_tickets TO authenticated USING (true) WITH CHECK (true);


--
-- Name: support_sla_policies; Type: ROW SECURITY; Schema: tickets; Owner: -
--

ALTER TABLE tickets.support_sla_policies ENABLE ROW LEVEL SECURITY;

--
-- Name: support_ticket_attachments; Type: ROW SECURITY; Schema: tickets; Owner: -
--

ALTER TABLE tickets.support_ticket_attachments ENABLE ROW LEVEL SECURITY;

--
-- Name: support_ticket_categories; Type: ROW SECURITY; Schema: tickets; Owner: -
--

ALTER TABLE tickets.support_ticket_categories ENABLE ROW LEVEL SECURITY;

--
-- Name: support_ticket_events; Type: ROW SECURITY; Schema: tickets; Owner: -
--

ALTER TABLE tickets.support_ticket_events ENABLE ROW LEVEL SECURITY;

--
-- Name: support_ticket_internal_notes; Type: ROW SECURITY; Schema: tickets; Owner: -
--

ALTER TABLE tickets.support_ticket_internal_notes ENABLE ROW LEVEL SECURITY;

--
-- Name: support_ticket_messages; Type: ROW SECURITY; Schema: tickets; Owner: -
--

ALTER TABLE tickets.support_ticket_messages ENABLE ROW LEVEL SECURITY;

--
-- Name: support_ticket_subtypes; Type: ROW SECURITY; Schema: tickets; Owner: -
--

ALTER TABLE tickets.support_ticket_subtypes ENABLE ROW LEVEL SECURITY;

--
-- Name: support_ticket_types; Type: ROW SECURITY; Schema: tickets; Owner: -
--

ALTER TABLE tickets.support_ticket_types ENABLE ROW LEVEL SECURITY;

--
-- Name: support_tickets; Type: ROW SECURITY; Schema: tickets; Owner: -
--

ALTER TABLE tickets.support_tickets ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--



