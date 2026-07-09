# GlowTap Super Admin Portal
## Functional Specification Document

**Version:** 1.2  
**Date:** July 4, 2026  
**Audience:** Business stakeholders, product owners, operations teams  
**Purpose:** Define what the Super Admin platform does, who uses it, and how day-to-day operations are managed across the GlowTap ecosystem.

---

## 1. Executive Summary

The **GlowTap Super Admin Portal** is the centralized command center for managing the entire GlowTap platform. It enables the GlowTap backend and operations team to onboard salons, approve branches, manage subscriptions and billing, monitor transactions, control user access, publish content, analyze platform health, and resolve support issues — all from a single secure interface.

GlowTap follows an **Organization → Branch** model: a salon owner creates an **Organization (Org)** when subscribing. Each org can operate **multiple branches** (physical locations). Branch creation is initiated by the salon admin but requires **Super Admin approval** before going live.

---

## 2. User Roles & Access

| Role | Description |
|------|-------------|
| **Super Admin** | Full platform access. Manages salons, subscriptions, content, reports, and support. |
| **Super Admin (Read-only)** | View-only access for audit, finance, or compliance teams. |
| **Operations Agent** | Limited access to approvals, support tickets, and defaulter reports. |

> Super Admin login is secured with email/password, optional MFA, and session timeout policies.

---

## 3. Platform Navigation Overview

```
Dashboard
├── Salon Approvals          (new subscription leads)
├── Branch Approvals         (new branch requests from onboarded salons)
├── All Salons               (active, suspended, terminated)
├── Transactions             (end-user payments to salons)
├── Subscription Management  (plans, discounts, salon billing)
├── Reports                  (defaulters, revenue, growth)
├── User Access Control      (Salon Admins, Sub Admins, End Users)
├── CMS & Banners            (website content, salon-admin promotional banners)
├── Configure Admin CMS      (customer-app ad platform: pricing, slots, policies)
├── Platform Analytics       (KPIs, trends, usage)
├── Support & Ticketing      (platform and salon-raised tickets)
├── Master Configuration     (reason codes, notifications, tax settings)
└── Audit Log                (who did what, when)
```

---

## 4. Module Specifications

### 4.1 Dashboard (Home)

The landing page provides an at-a-glance view of platform health:

- **Pending actions:** Salon approvals, branch approvals, open tickets, defaulter count
- **Key metrics:** Total active salons, total branches, MRR (Monthly Recurring Revenue), active end users, today's transaction volume
- **Alerts:** Failed payments, salons nearing subscription expiry, high-priority tickets
- **Quick actions:** Approve salon, view defaulter report, create ticket

---

### 4.2 Salon Approvals

**Trigger:** When a salon owner completes the subscription purchase/sign-up flow on GlowTap, a **lead** is automatically created and appears in the Salon Approvals tab.

**Workflow:**

1. Lead appears with status **Pending Review**
2. Super Admin reviews salon details: business name, owner name, email, phone, address, selected subscription plan, payment status, uploaded documents (if KYC enabled)
3. Super Admin sets **Commission Percentage** — the rate GlowTap earns on each end-user payment to this salon (e.g., 5%, 8%, 10%). Default can be pre-filled from platform config; editable per salon at approval.
4. Super Admin can:
   - **Approve** → Salon is onboarded; a Salon Admin account is auto-created and credentials are emailed to the registered email
   - **Reject** → Reason selected from configured list; notification sent to applicant
   - **Request More Info** → Status changes to Awaiting Documents; applicant is notified

**Post-Approval Actions (automatic):**
- Organization record created with **commission percentage** saved
- First branch (primary location) created and activated
- Salon Admin account created with full branch access
- Welcome email with login credentials sent
- Subscription activated per selected plan

**Filters:** Status (Pending, Approved, Rejected, Awaiting Info), date range, subscription plan, city/region

---

### 4.3 Branch Approvals

**Context:** After onboarding, a Salon Admin can request to open additional branches under their organization. Each new branch requires Super Admin approval.

**Workflow:**

1. Salon Admin submits branch request from their portal (branch name, address, contact, operating hours)
2. Request appears in Branch Approvals with linked org/salon name
3. System validates: **Does the salon's current subscription allow another branch?**
   - If **within limit** → Proceed to review
   - If **at limit** → Request flagged as "Upgrade Required"; Super Admin can approve with plan upgrade or reject with upgrade prompt sent to salon
4. Super Admin reviews and **Approves** or **Rejects** (with reason)
5. On approval, branch becomes active and visible in the salon's admin portal

**Branch Limit by Subscription Plan (example tiers):**

| Plan | Max Branches | Notes |
|------|-------------|-------|
| Starter (1M) | 1 | Single location only |
| Growth (6M) | 3 | Small multi-location |
| Professional (12M) | 10 | Mid-size chains |
| Enterprise (24M) | Unlimited | Custom pricing |

> Plan-branch limits are configurable in Subscription Management. Existing salons are grandfathered or prompted to upgrade when limits change.

---

### 4.4 All Salons

Central registry of all onboarded salons (organizations).

**List View:**
- Salon name, city, status, plan, branch count, commission %, total earnings (subscription + commission)

**Detail View — Profile & Settings:**
- Business profile: name, logo, contact, GST/tax ID, registered address
- Owner details
- Current subscription: plan name, start date, renewal date, billing cycle, payment method
- **Commission settings:** current commission percentage (editable)
- Branch list with status per branch
- Account status: Active, Suspended, Terminated

**Detail View — Earnings Summary**

A dedicated earnings panel showing GlowTap revenue from this salon to date, split by source:

| Earnings Type | Description | Example Metrics |
|---------------|-------------|-----------------|
| **Subscription Revenue** | Salon → GlowTap subscription payments (plan purchase, renewals, upgrades) | Total paid, outstanding, last payment date, MRR contribution |
| **Commission Revenue** | GlowTap share on end-user → salon transactions | Total commission earned, transaction count, avg commission per txn, current rate % |
| **Advertisement Revenue** | Salon → GlowTap upfront payments for customer-app banner campaigns | Total ad revenue, active campaigns, slots sold, revenue by period |

**Earnings Breakdown (till date):**
- **Total GlowTap Earnings** = Subscription Revenue + Commission Revenue + **Advertisement Revenue**
- **Subscription:** itemized list of invoices/payments (date, type, amount)
- **Commission:** itemized list per transaction (date, end-user txn amount, commission %, commission amount)
- Date range filter (7D, 30D, 90D, custom, all-time)
- Export earnings report (CSV/PDF)

**Commission Percentage — Edit:**
- Editable from salon detail view at any time
- Valid range: configurable platform min/max (e.g., 1%–25%)
- Change takes effect on **next transaction** (not retroactive)
- Requires confirmation; previous rate and new rate logged in audit trail
- Optional effective date for scheduled rate changes

**Actions:**

| Action | Description | Reason Required |
|--------|-------------|-----------------|
| **Suspend** | Temporarily disables salon access. End users cannot book; admin portal locked. | Yes — from configured reason codes |
| **Resume** | Restores suspended salon to active status. | Optional note |
| **Terminate** | Permanent closure. Data retained per retention policy; no reactivation without re-onboarding. | Yes — from configured reason codes |

**Reason Codes:**
- Each suspend/terminate reason is pre-configured in the database
- Each reason code may be associated with a **pricing impact** (e.g., early termination fee, forfeiture of discount)
- Reason and pricing are displayed before confirmation

**Manual Subscription Updates:**
- Change subscription plan (upgrade/downgrade)
- Extend validity manually (goodwill gesture, dispute resolution)
- Apply **discount component**:
  - **RC (Recurring Charge discount)** — reduces ongoing monthly/recurring fee from next bill date
  - **NRC (Non-Recurring Charge discount)** — one-time credit on next invoice
- Discount has: amount/percentage, description, effective date, expiry (optional)

**Filters:** Status, plan, city, branch count, subscription expiry window, payment status

---

### 4.5 Transactions History

Records all **end-user payments made to salons** (appointment bookings, service payments, product purchases, etc.).

**Displayed Fields:**
- Transaction ID, date/time
- End user (masked ID/name)
- Salon & branch
- Service/product description
- **Gross amount** (paid by end user)
- **Commission %** and **Commission amount** (GlowTap share)
- **Net to salon** (gross − commission)
- Payment method, status (Success, Failed, Refunded, Disputed)
- Gateway reference ID

**Filters:**
- Date range
- Salon / branch
- Transaction status
- Payment method
- Amount range
- City/region

**Actions:**
- View transaction detail
- Export to CSV/Excel
- Flag for dispute investigation (links to Support & Ticketing)

> This module tracks **B2C transactions** (end user → salon). Subscription payments (salon → GlowTap) are tracked under Subscription Management.

---

### 4.6 Subscription Management

#### 4.6.0 GlowTap Earning Model (Overview)

GlowTap generates revenue through **three streams**:

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         GlowTap Revenue Model                             │
├─────────────────────┬──────────────────────┬─────────────────────────────┤
│ 1. Subscription     │ 2. Commission        │ 3. Advertisement (Banner)    │
│    Revenue          │    Revenue           │    Revenue                   │
│ (Salon → GlowTap)   │ (End User → Salon    │ (Salon → GlowTap)            │
│                     │  → GlowTap)          │                              │
├─────────────────────┼──────────────────────┼─────────────────────────────┤
│ Plan purchase       │ % of each B2C txn    │ Upfront per-day banner       │
│ Renewals            │ Set at salon approval│ pricing × booked days        │
│ Upgrades            │ Editable per salon   │ Slot capacity enforced       │
│ RC / NRC discounts  │ Tracked in Txns +    │ Configured in Configure      │
│                     │ Salon earnings view  │ Admin CMS                    │
└─────────────────────┴──────────────────────┴─────────────────────────────┘
```

- **Subscription:** Fixed/recurring fees based on plan tier and contract length
- **Commission:** Variable fee per end-user payment; percentage configured per salon
- **Advertisement:** Salons purchase banner slots in the **end-customer app** via the Salon Admin **CMS & Banners** module; **upfront payment** required; pricing and daily capacity set in **Configure Admin CMS**
- All three streams visible in **All Salons → Detail → Earnings**, **Subscription Management**, **Configure Admin CMS**, **Platform Analytics**, and **Reports**

#### 4.6.1 Plan Overview

Dashboard showing:
- Count of salons per subscription plan (1M, 6M, 12M, 24M, etc.)
- Revenue breakdown by plan
- Upcoming renewals (7/30/90 day windows)
- Churn risk indicators

#### 4.6.2 Plan Configuration

**Create / Edit Subscription Plans:**

| Field | Description |
|-------|-------------|
| Plan name & code | e.g., "Growth 6M", `GROWTH_6M` |
| Duration | 1, 6, 12, 24 months |
| Base price (NRC) | One-time or upfront component |
| Recurring price (RC) | Monthly recurring charge (if applicable) |
| Max branches | Branch limit for this plan |
| Feature entitlements | Appointments, manpower, services, analytics tier, etc. |
| Status | Active, Deprecated (no new sign-ups), Retired |

**Contract Discounts:**
- Discounts tied to contract length (6M, 12M, 24M)
- Types: percentage off, fixed amount, free months
- **Display description** — marketing text shown to salon owners during purchase and in-app (e.g., "Save 20% with our 12-month plan")
- Validity period for promotional discounts

**Plan Change Rules:**
- Upgrade: immediate effect, prorated billing
- Downgrade: effective at next renewal; branch count must fit new plan limit

#### 4.6.3 Subscription Transactions

Tracks **salon → GlowTap** payments:
- Subscription purchase, renewal, upgrade charges
- Refunds and credits applied
- Invoice history per salon
- Failed payment attempts and retry status

**Filters:** Salon, plan, date range, payment status, invoice number

#### 4.6.4 Commission Configuration (Platform Defaults)

Master settings for commission model (in Master Configuration):
- Default commission % for new salons
- Min / max allowed commission range
- Whether commission applies to refunds (pro-rata reversal)
- Commission settlement cycle (real-time ledger vs periodic payout report)

---

### 4.7 Reports

#### 4.7.1 Daily Defaulter Report (Primary)

**Purpose:** Replace automatic salon suspension for non-payment. Instead, generate a daily report so the backend team can proactively call salons before taking action.

**Report Contents:**
- Salon name, owner contact, email, phone
- Outstanding amount and days overdue
- Last payment date
- Current plan and renewal date
- Branch count
- Previous contact attempts (if logged)
- Recommended action (Call, Send Reminder, Suspend Warning)

**Delivery:** Generated daily at configured time; available in portal and optionally emailed to operations distribution list.

**Follow-up Actions (manual):**
- Log call outcome
- Extend grace period
- Apply discount
- Initiate suspension (manual, with reason)

#### 4.7.2 Additional Reports

| Report | Description |
|--------|-------------|
| **Revenue Summary** | MRR, ARR, subscription revenue, **commission revenue**, **advertisement revenue**, combined platform revenue |
| **Advertisement Revenue Report** | Banner campaigns, slots sold, revenue by salon/city/period, utilization vs capacity |
| **Commission Report** | Commission earned by salon, by city, by period; avg rate, top earners |
| **Salon Growth** | New onboardings, approvals pending, rejection rate |
| **Branch Activity** | Branch additions, approvals pending, utilization by plan |
| **Transaction Volume** | End-user transaction trends by salon, city, service category |
| **Churn & Retention** | Salons that did not renew, downgrade patterns |
| **Support SLA** | Ticket volume, resolution time, open backlog by priority |
| **Discount Utilization** | RC/NRC discounts applied, revenue impact |
| **Plan Distribution** | Salons by plan tier, upgrade/downgrade funnel |
| **Geographic Performance** | Salons and revenue by city/region |

All reports support date range selection and CSV/Excel export.

---

### 4.8 User Access Control

Three tabs for viewing and limited management of platform users.

#### 4.8.1 Salon Admins

- **Creation:** Auto-generated on salon approval with access to all branches under the org
- **Portal Use:** View profile, login history, branch access, status
- **Manual Edit:** Update email, reset password, modify contact (with audit log)
- **Disable:** Block login for fraud or policy violation (does not delete data)

#### 4.8.2 Sub Admins

- **Creation:** Done by Salon Admin from their portal (not manually creatable by Super Admin)
- **Portal Use:** View-only for Super Admin — see which sub-admin has access to which branches and modules (appointments, manpower, services)
- **Edit Restriction:** Super Admin **cannot** modify branch/module permissions (salon admin owns this)
- **Disable Only:** Super Admin can disable a sub-admin ID if fraudulent or illegal activity is detected
- **Audit:** All disable actions logged with reason

#### 4.8.3 End Users

- **Portal Use:** View end-user profiles linked to bookings and transactions
- **Disable Only:** Block account for abuse, fraud, or policy violations
- **No manual creation** — end users self-register via the consumer app

**Common Features Across Tabs:**
- Search by name, email, phone, salon
- Filter by status (Active, Disabled)
- View activity summary (last login, transaction count)
- Export user list

---

### 4.9 CMS & Banner Management

#### 4.9.1 Website Content (CMS)

Manage public-facing website content:
- Pages: About, Pricing, Features, FAQ, Terms, Privacy Policy
- Blog/news posts
- Media library (images, videos)
- SEO metadata (title, description)
- Publish / draft / schedule workflow
- Preview before publish

#### 4.9.2 Salon Admin Portal Banners (Platform Promotional)

Promotional banners shown to **salon admins** inside the GlowTap Salon Admin portal (not the end-customer app).

**Banner Configuration:**
- Title, image, CTA text, CTA link (e.g., upgrade plan page)
- Target audience (logic-driven):
  - Current plan (e.g., show 12M discount banner to 1M subscribers)
  - Subscription expiry window (e.g., 30 days before renewal)
  - Renewal behavior (e.g., "Renew 12M plan → get 1 extra month free"; "Renew 24M → get 2 extra months")
  - Branch utilization (e.g., "You've reached your branch limit — upgrade to add more")
  - New feature announcements
- Display priority and rotation order
- Active date range
- A/B test variant (optional, future)

**Example Logic Rules:**

| Condition | Banner Message |
|-----------|---------------|
| Plan = 1M, tenure > 3 months | "Upgrade to 12M and save 20%" |
| Plan = 12M, expiry within 30 days | "Renew 12M now and get 1 month free" |
| Plan = 12M, expiry within 30 days, offer 24M | "Switch to 24M renewal and get 2 months free" |
| Branch count = plan max | "Add more locations — upgrade your plan" |

> **Customer-app advertisement banners** (paid by salons) are configured by Salon Admin in their **CMS & Banners** module. Platform rules, pricing, and slot capacity are set in **Configure Admin CMS** (§4.10).

---

### 4.10 Configure Admin CMS (Customer App Advertising)

Central configuration for the **Salon Admin → CMS & Banners** advertisement product — a third GlowTap revenue stream.

#### 4.10.1 Platform Settings

| Setting | Description |
|---------|-------------|
| **Per-day banner price** | Fixed price charged for each calendar day a campaign runs (currency per platform region) |
| **Max banners per day (customer app)** | Maximum number of advertisement banners that can be **live simultaneously** in the end-customer app on any given calendar day (e.g., 4) |
| **Max campaign duration** | Optional cap on consecutive days per single campaign (e.g., 30 days) |
| **Banner image spec** | Required dimensions, max file size, allowed formats |
| **Minimum lead time** | Earliest start date offset from booking date (e.g., 2 days) |
| **Advertisement refund policy** | Full / partial / no refund when salon cancels a paid scheduled campaign |
| **Tax applicability** | Whether GST/VAT applies to ad purchases |
| **Module enabled** | Global on/off for customer-app advertising feature |

Changes are audit-logged; price changes apply to **new campaigns only** (existing paid campaigns honor booked rate).

#### 4.10.2 Banner Slot Engine (Auto-Calculated)

The platform maintains a **daily slot ledger** for the end-customer app:

```
For each calendar date D:
  capacity(D)     = max_banners_per_day (from settings)
  booked(D)       = count of paid campaign-days reserved on D
  available(D)    = capacity(D) − booked(D)
```

**Rules:**
- When Salon Admin selects a date range, each day in the range consumes **one slot** on that date upon successful upfront payment
- If `available(D) = 0` (e.g., 28 July fully booked when max = 4), that date is **unselectable** in the Salon Admin date picker
- Slots are **platform-wide** (shared across all salons), not per-salon quotas
- Partial-day booking is not supported — one slot = one full calendar day of banner visibility

**Super Admin visibility:**
- Calendar heatmap: capacity vs booked vs available by date
- List of campaigns consuming slots (salon, date range, status)
- Manual slot release only via campaign cancellation/refund workflow (with audit)

#### 4.10.3 Campaign Oversight (Read + Moderation)

Super Admin can view all salon advertisement campaigns:

- Filter by salon, status (Draft, Scheduled, Live, Expired, Cancelled), date range, city
- Preview banner content before/during live period
- **Reject / take down** live banner for policy violation (refund per policy; slot released)
- View payment and invoice reference per campaign
- Export campaign list (CSV)

#### 4.10.4 Advertisement Revenue Tracking

- Dashboard KPIs: total ad revenue (MTD/YTD), active campaigns, slot utilization %, avg revenue per slot-day
- Revenue rolls into **All Salons → Earnings → Advertisement Revenue** per paying salon
- Included in platform **Revenue Summary** and **Advertisement Revenue Report** (§4.7.2)

---

### 4.11 Platform Analytics

Visual dashboards for strategic insight:

- **Salon Metrics:** Active salons, new sign-ups, churn rate, avg branches per salon
- **Revenue Metrics:** MRR, ARR, ARPU, **subscription revenue**, **commission revenue**, **advertisement revenue**, combined LTV
- **Usage Metrics:** Appointments booked, active end users, transaction GMV
- **Geographic Heatmap:** Salon density and revenue by region
- **Funnel Analytics:** Lead → approval → active → renewal conversion
- **Feature Adoption:** Which modules (appointments, manpower, services) are most used
- **Time-series Charts:** Daily/weekly/monthly trends with comparison periods

Filters: date range, plan tier, region, salon segment.

---

### 4.12 Support & Ticketing

Central helpdesk for platform-level and salon-raised issues.

**Ticket Creation:**
- Select **Reason** (from configured master list)
- Select **Sub-Reason** (dependent on reason)
- Description (free text)
- Attach files (screenshots, documents)
- Link to salon/branch/user (optional)
- Priority: Low, Medium, High, Critical

**Ticket Sources:**
- Created by Super Admin/Ops team
- Escalated from salon admin portal
- Auto-created from failed payments, approval bottlenecks (configurable)

**Ticket Status Flow:**

```
Created → In Progress → On Hold → Awaiting User Confirmation → Resolved
                ↑              ↓
                └──────────────┘
```

| Status | Meaning |
|--------|---------|
| **Created** | New ticket, not yet assigned |
| **In Progress** | Assigned agent working on it |
| **On Hold** | Waiting on internal dependency |
| **Awaiting User Confirmation** | Solution proposed; waiting for salon/user response |
| **Resolved** | Closed with resolution notes |

**Features:**
- Assign to team member
- Internal notes (not visible to salon)
- SLA timers based on priority
- Ticket history and audit trail
- Reopen resolved tickets
- Dashboard: open count, avg resolution time, overdue tickets

---

### 4.13 Master Configuration

Centralized settings managed by Super Admin:

- **Reason Codes:** Suspend, terminate, reject, ticket reasons and sub-reasons
- **Pricing Rules:** Reason code → fee/penalty mapping
- **Notification Templates:** Email/SMS templates for onboarding, renewal, suspension, etc.
- **Tax/GST Settings:** Rates by region
- **Grace Period:** Days before a salon appears on defaulter report
- **Feature Entitlements Matrix:** Which features each plan includes
- **Payment Gateway Settings:** Active gateways, retry rules

> **Customer-app advertisement settings** (per-day price, max banners, refund policy) are managed in **Configure Admin CMS** (§4.10), not Master Configuration.

---

### 4.14 Audit Log

Immutable log of all Super Admin actions:

- Who performed the action
- What was changed (before/after values)
- When (timestamp)
- IP address and session ID

**Tracked Actions:** Approvals, suspensions, plan changes, discount applications, user disables, configuration changes, ticket updates.

Retention: configurable (recommended minimum 2 years).

---

## 5. Key Business Rules

### 5.1 Subscription & Branch Limits

- Each subscription plan defines a **maximum number of branches**
- Salon cannot activate a branch beyond their plan limit without upgrading
- Downgrading a plan requires branch count to be at or below the new plan's limit
- Super Admin can override limits case-by-case with audit trail

### 5.2 Non-Payment Handling

- **No automatic suspension** for payment defaults
- Daily defaulter report drives manual outreach
- Super Admin decides: grace extension, discount, reminder, or suspension
- Suspension for non-payment uses configured reason code with associated pricing impact

### 5.3 Discount Application

- RC discounts apply to recurring charges from the **next bill date**
- NRC discounts apply as a one-time credit on the **next invoice**
- Discounts require description for salon visibility on invoice/portal
- All discounts logged with approver identity

### 5.6 Advertisement Banner & Slot Rules

- **Upfront payment only:** Salon Admin campaigns are activated only after successful payment; drafts do not reserve slots
- **Slot consumption:** Each paid campaign day reserves one slot on the global daily ledger (§4.10.2)
- **Capacity enforcement:** When `booked(date) = max_banners_per_day`, no salon can select that date for a new campaign
- **Pricing:** `total = per_day_price × number_of_days_in_range` (+ tax if configured)
- **Price changes:** Apply to new bookings only; paid campaigns retain original rate
- **Content moderation:** Super Admin may take down live banners for policy violations; refund per **Advertisement Refund Policy**
- **Revenue recognition:** Advertisement revenue recorded on payment success; appears in salon earnings and platform reports
- **Feature flag:** When **Configure Admin CMS → Module enabled** is off, Salon Admin CMS & Banners is hidden and no new slots sold

### 5.7 Commission Rules

- Commission percentage is set at **salon approval** and stored on the organization record
- Super Admin can **edit commission %** anytime from All Salons detail view
- Commission is calculated on **successful** end-user transactions: `commission_amount = gross_amount × (commission_pct / 100)`
- Rate changes apply to **future transactions only**; historical transactions retain original rate
- On refund, commission is reversed proportionally
- Commission earnings roll up into salon detail **Earnings Summary** and platform-wide reports

---

## 6. Notifications & Communications

| Event | Recipient | Channel |
|-------|-----------|---------|
| Salon approved | Salon owner | Email |
| Salon rejected | Applicant | Email |
| Branch approved/rejected | Salon admin | Email + in-app |
| Subscription renewal reminder | Salon admin | Email + in-app banner |
| Defaulter outreach | Salon admin | Email/SMS (manual trigger) |
| Account suspended/resumed | Salon admin | Email + in-app |
| Ticket status update | Ticket raiser | Email + in-app |
| Banner campaign payment received | Super Admin ops (optional digest) | Email |
| Banner campaign taken down (moderation) | Salon Main Admin | Email + in-app |
| Sub-admin disabled | Salon admin | Email |

---

## 7. Additional Recommendations

The following capabilities are recommended to strengthen the platform:

1. **Document Verification (KYC)** — Collect and verify business registration, owner ID during salon approval
2. **Invoice Management** — Generate, view, and resend subscription invoices from Super Admin
3. **Refund Processing** — Initiate full/partial refunds on subscription or flagged B2C transactions
4. **Bulk Operations** — Bulk approve, bulk email, bulk plan migration for enterprise deals
5. **Communication Hub** — Send targeted announcements to salon segments (by plan, region, status)
6. **Dispute Management** — Track payment disputes from end users with resolution workflow
7. **Data Export & Compliance** — GDPR/data deletion requests, salon data export on termination
8. **Maintenance Mode** — Platform-wide or per-salon maintenance flag for upgrades
9. **Referral Program Management** — Track salon referral codes and rewards
10. **Integration Marketplace** — Manage third-party integrations (payment, SMS, accounting) enabled per plan

---

## 8. Glossary

| Term | Definition |
|------|------------|
| **Org / Organization** | A salon business entity on GlowTap; can have multiple branches |
| **Branch** | A physical salon location under an organization |
| **Salon Admin** | Primary administrator for an org; full branch access |
| **Sub Admin** | Delegated admin created by Salon Admin with limited branch/module access |
| **End User** | Consumer who books appointments and pays salons via the GlowTap app |
| **Lead** | A pending salon sign-up awaiting Super Admin approval |
| **RC** | Recurring Charge — ongoing subscription fee |
| **NRC** | Non-Recurring Charge — one-time fee or credit |
| **Commission** | GlowTap's percentage share on each end-user payment to a salon |
| **Advertisement Revenue** | Upfront fees paid by salons for customer-app banner campaign slots |
| **Banner Slot** | One unit of daily customer-app banner capacity on a calendar date |
| **GMV** | Gross Merchandise Value — total end-user transaction volume |
| **MRR** | Monthly Recurring Revenue |
| **Defaulter** | Salon with overdue subscription payment beyond grace period |

---

## 9. Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.2 | July 4, 2026 | GlowTap Product Team | Configure Admin CMS, advertisement revenue model, banner slot engine |
| 1.1 | June 15, 2026 | GlowTap Product Team | Commission earning model, salon earnings detail view |
| 1.0 | May 31, 2026 | GlowTap Product Team | Initial release |

---

*This document describes the intended behavior of the GlowTap Super Admin Portal. Technical implementation details are covered in the companion Solutioning Document.*
