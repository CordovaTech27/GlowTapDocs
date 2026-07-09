# GlowTap End Customer App
## Functional Specification Document

**Version:** 1.3  
**Date:** July 4, 2026  
**Audience:** Business stakeholders, product owners, design and delivery teams  
**Purpose:** Define what the GlowTap consumer app does, who uses it, and how end customers discover salons, book services, pay, manage appointments, and interact with the platform.

**Related:** Super-Admin-Functional-Spec.md v1.2 · Admin-Functional-Spec.md v1.2

**Platform:** React Native mobile app (iOS & Android) — primary consumer channel. Responsive web companion may follow in a later release.

---

## 1. Executive Summary

The **GlowTap End Customer App** is the consumer-facing mobile experience for discovering nearby salons, browsing services, booking appointments with specialists, and paying online or at the salon. End users **self-register** via the app (Super Admin §4.8.3 — no manual creation by operations).

GlowTap follows an **Organization → Branch** model. Consumers discover and book at the **branch** level (physical location). Each branch belongs to a salon organization and exposes its own service catalog, operating hours, specialists, and availability.

Bookings created in the consumer app appear in the **Salon Admin portal** (Admin §4.12) for confirmation, fulfillment, cancellation, and refund handling. Payments flow as **B2C transactions** (Super Admin §4.5) with GlowTap commission applied per salon configuration.

---

## 2. User Roles & Access

| Role | Description |
|------|-------------|
| **End User (Customer)** | Registered, authenticated consumer who discovers salons, books services, and pays via the app |

**Access principles:**
- **Authentication required** — the app has no guest or unauthenticated mode. Every session must sign in or complete sign up + required verification before any app feature (discovery, search, booking, profile) is accessible.
- Unauthenticated users see only the **Welcome / Sign In / Sign Up** flow until a valid session is established.
- End users self-register; Super Admin can **disable** accounts for abuse or policy violations (Super Admin §4.8.3)
- Disabled users see a clear message on login attempt; active bookings remain visible read-only where policy allows
- When a salon org or branch is **Suspended** or **Terminated**, that branch is hidden from discovery and existing bookings show restricted actions per platform policy (Admin §5.6)
- One end-user account per verified email; phone uniqueness enforced at signup

> Login supports **Google Sign-In** and **email + password**. **Google:** email is trusted from OAuth — **phone OTP only** before the main app unlocks. **Email + password:** **email OTP and phone OTP** required before the main app unlocks.

---

## 3. Platform Navigation Overview

```
Authentication (required gate — no guest access)
├── Welcome / Sign In / Sign Up
├── OTP Verification (phone; email OTP for email signup only)
└── Forgot Password

Home (authenticated users only)
├── Nearby Salons              (default landing — map + list)
├── Search & Advanced Search   (name, city, state, filters)
├── Salon Detail               (branch profile, services, gallery)
├── Service Detail             (price, duration, specialists)
└── Booking Flow               (date → slot → specialist → review → pay)

Bookings
├── My Bookings List           (search, filters, status tabs)
├── Booking Detail             (actions by status)
├── Reschedule Flow            (re-select date, slot, specialist)
├── Cancel / Request Cancel
├── Feedback & Rating
├── Invoice Download
└── Raise Ticket (linked to booking)

Profile
├── View / Edit Profile
├── Saved Addresses / Location
├── Payment Methods (optional saved cards — future)
├── Notification Preferences
└── Help & Support

Notifications
└── In-app notification center (booking, payment, refund, promo)

Settings & Legal
├── Change Password
├── Terms of Service / Privacy Policy
├── App Version / Logout
└── Delete Account Request (future / compliance)
```

**Primary navigation (bottom tab bar — recommended):**
- **Home** — discovery and search
- **Bookings** — appointment history and active bookings
- **Notifications** — alerts and messages
- **Profile** — account and settings

---

## 4. Module Specifications

### 4.1 Authentication & Onboarding

#### 4.1.1 Welcome / Sign In Screen

**App entry gate.** On launch, if the user has no valid session they remain on this screen (or Sign Up / OTP flows) — they **cannot** access Home, salon discovery, bookings, or any other module until authenticated and verified.

Entry screen for returning and new users.

**Options:**
- **Sign in with Google** — OAuth; if account exists and phone verified, log in to main app; if new or phone unverified, proceed to profile completion (§4.1.3) then **phone OTP only** (§4.1.4)
- **Sign in with Email** — email + password
- **Sign up** — navigate to registration (§4.1.2)
- **Forgot password** — email reset link flow (link expiry per platform policy)

**Validation:**
- Invalid credentials → generic error (do not reveal whether email exists)
- Disabled account → "Your account has been disabled. Contact support."
- Unverified phone on email login → user stays in verification flow; main app not accessible until required OTP complete (§4.1.4)

#### 4.1.2 Sign Up Screen

**Sign up with Google:**
- OAuth consent → collect or confirm: full name, email (from Google — **treated as verified**; no email OTP)
- Collect phone number → proceed to **phone OTP only** (§4.1.4)

**Sign up with Email (normal registration):**
- Required fields: full name, email, phone, password (strength rules per platform config)
- Optional: profile photo, gender, date of birth (if salons use for personalization — optional v1)
- Accept Terms of Service and Privacy Policy (checkbox + links)
- Submit → **email OTP and phone OTP** (§4.1.4)

**Rules:**
- Email and phone must be unique across end users
- Password reset and Google-linked accounts: if email already registered with password, guide user to sign in or link account per policy

#### 4.1.3 Profile Completion (Google / partial signup)

After OAuth or initial signup, user completes any missing required fields before OTP step:
- Phone number (required — always collected for Google signup if not already on file)
- Name confirmation
- Terms acceptance

> Google-provided email is stored as **verified** automatically; skip email OTP for this path.

#### 4.1.4 OTP Verification

Verification rules by signup / sign-in path:

| Path | Email OTP | Phone OTP | Unlock main app when |
|------|-----------|-----------|----------------------|
| **Google Sign-In / Sign-Up** | **Not required** (email trusted via OAuth) | **Required** | Phone OTP verified |
| **Email + password Sign-Up** | **Required** | **Required** | Both OTPs verified |
| **Email + password Sign-In** | Required only if email not yet verified | Required only if phone not yet verified | All required verifications complete |

| Channel | When | Behavior |
|---------|------|----------|
| **Email OTP** | Email + password signup only; or when user **changes email** in profile | Send code to registered email; user enters code; resend with cooldown |
| **Phone OTP** | All signup paths; or when user **changes phone** in profile | Send SMS OTP; user enters code; resend with cooldown |

- Verification status shown on profile (email ✓ auto for Google; phone ✓ after OTP)
- Change of **email** in profile → email OTP re-verification (applies to email/password accounts; Google users changing email follow same rule)
- Change of **phone** in profile → phone OTP re-verification

#### 4.1.5 Post-Login Onboarding (first session)

Optional lightweight onboarding after verification:
- Request **location permission** — used for nearby salon discovery (§4.2)
- Brief value proposition carousel (skippable)
- Land on **Home — Nearby Salons**

#### 4.1.6 Session & Security

- Logout from Profile / Settings
- Session timeout per platform configuration
- Optional **biometric unlock** (Face ID / fingerprint) for return visits — future enhancement

---

### 4.2 Home — Salon Discovery (Nearby)

Default landing for **authenticated, verified** users only. Surfaces **active branches** within configurable radius of the user's location.

#### 4.2.1 Location Context

| Source | Description |
|--------|-------------|
| **Device GPS** | Primary — used when permission granted |
| **Saved address** | User-selected home/work or custom pin from Profile |
| **Manual city selection** | Fallback when GPS denied — user picks city/area for discovery |

Display current search context: e.g., "Near Indiranagar, Bengaluru" with option to change.

#### 4.2.2 Nearby Salons List & Map

**Views:**
- **List view** — scrollable cards
- **Map view** — pins for branches; tap pin → salon card preview

**Salon card fields:**
- Branch name, salon/org brand name (if different)
- Distance from user (km)
- Rating average and review count (from completed booking feedback)
- Starting price or "From ₹X" (lowest active service price)
- Top service tags (e.g., Haircut, Facial, Spa)
- Open/closed indicator based on branch operating hours (Admin §4.4)
- Thumbnail / cover image

**Sort options:**
- Distance (default)
- Rating (high to low)
- Price (low to high)
- Popularity (booking volume — platform metric)

#### 4.2.3 Discovery Filters

Applied on nearby results and search results:

| Filter | Description |
|--------|-------------|
| **Services / categories** | Multi-select service types offered at branch |
| **Price range** | Min–max based on service catalog |
| **Rating** | Minimum star rating |
| **Open now** | Only branches currently within operating hours |
| **Online payment available** | Branches with at least one service allowing online pay |
| **Gender preference** | If branch/salon tags support unisex / men / women (optional v1) |

Filters persist until cleared; active filter chips shown above results.

#### 4.2.4 Search Radius Control

- Default radius from platform config (e.g., 5 km)
- User-adjustable slider or presets: **2 km · 5 km · 10 km · 15 km · 25 km**
- Increasing radius expands result set; empty state suggests increasing radius or changing location
- Radius applies to GPS/saved-address discovery only

#### 4.2.5 Advanced Search (Other Locations)

For users searching outside current GPS radius or for a specific destination.

**Search modes (combinable):**
- **Salon / branch name** — typeahead as user types
- **City** — select or type city
- **State / region** — select state, then optionally narrow by city
- **Pin code / area** — optional precision

**Behavior:**
- Dynamic, flexible query — name-only, city-only, or combined (e.g., "Lakme Indiranagar Bengaluru")
- Results ranked by relevance, then distance if location known
- Same filters as §4.2.3 apply to search results
- Recent searches saved locally (clear history option)

#### 4.2.6 Favorites / Saved Salons

- User can **save** a branch to favorites from list or salon detail
- **Favorites** section on Home or Profile for quick rebooking
- Removing favorite is instant

#### 4.2.7 Promotional Banners (Consumer)

In-app banners configured by Super Admin (consumer audience — parallel to salon admin banners in Super Admin §4.9.2):

- Online payment discount promos ("Pay online & save 10%")
- Seasonal offers, new salon in area
- Tap banner → deep link to salon, service, or offer terms

---

### 4.3 Salon Detail (Branch Profile)

Opened when user selects a salon from discovery or search.

**Displayed content:**
- Branch name, address, map pin, distance
- Photo gallery
- Operating hours (today highlighted)
- Contact phone (tap to call — optional)
- Overall rating and review summary
- **Recent reviews:** star rating, text snippet, reviewer first name (or anonymous label), date — uploaded **image** shown when provided (tap to view full size)
- List of **active services** (Admin §4.10) with name, duration, price, thumbnail
- Specialists count or "X specialists available" (optional summary)
- Policies snippet: cancellation window, online vs pay-at-salon accepted

**Actions:**
- **Book** on a service → enters booking flow (§4.5)
- **Save to favorites**
- **Share salon** (deep link / share sheet)

**Rules:**
- Inactive or suspended branches not reachable via discovery; direct link shows unavailable message
- Services with `Offline payment allowed = No` still visible; booking requires online payment at checkout

---

### 4.4 Service Detail

Optional intermediate screen or expandable section before booking.

- Service name, description, photo, duration, price
- List of specialists who perform this service (names, photos, ratings if available)
- **Book Now** → booking flow with service pre-selected

---

### 4.5 Booking Flow

Multi-step flow; user can navigate back to change prior steps without losing context until payment.

#### 4.5.1 Step 1 — Select Service

- If entered from salon detail, service pre-selected
- User confirms one service per booking (v1 — **one service per appointment**; multi-service cart future release)
- Show price, duration, payment mode flags (online allowed / pay at salon allowed)

#### 4.5.2 Step 2 — Select Date

- Calendar view: selectable dates based on branch availability
- Dates with no operating hours, branch holidays, or no specialist availability shown disabled (Admin §4.8.2, §4.11)
- Minimum advance booking window and maximum future window per platform/salon config (e.g., book up to 30 days ahead)

#### 4.5.3 Step 3 — Select Time Slot

- Slots generated per Admin §4.11 rules: branch hours, service duration, specialist availability, existing appointments
- Display available start times for selected date
- Unavailable slots hidden or shown disabled with reason where helpful ("Fully booked", "No specialist available")
- Slot reflects **service duration** (e.g., 45 min service blocks consecutive slot capacity)

#### 4.5.4 Step 4 — Select Specialist

| Option | Description |
|--------|-------------|
| **Choose specialist** | List specialists available for selected date/time and service; show photo, name, designation, rating |
| **Auto-assign specialist** | System picks best available specialist (e.g., highest rating, least loaded, or round-robin — platform rule) |

- If only one specialist qualified → auto-selected; user may still view profile
- If no specialist for slot → user returned to slot selection with message

#### 4.5.5 Step 5 — Review & Pre-Invoice

Summary screen before payment — **pre-invoice / order review**:

| Line item | Detail |
|-----------|--------|
| Salon & branch | Name, address |
| Service | Name, duration |
| Specialist | Name or "Auto-assigned" |
| Date & time | Formatted local datetime |
| Service price | Base amount |
| Discounts | Online payment promo, salon offer, coupon (if applicable) |
| Taxes | GST/tax lines per platform config |
| **Total payable** | Final amount |

**Optional fields:**
- Notes to salon (special requests — max length configurable)
- Apply promo code (if enabled)

**Payment method selection:**

| Method | When available | Behavior |
|--------|----------------|----------|
| **Pay online** | Service/branch allows; gateway configured | Redirect to payment gateway; discount badges shown if online promo active |
| **Pay at salon** | Service `Offline payment allowed = Yes` (Admin §4.10) | No charge at booking; appointment confirmed as unpaid until salon marks paid |

- If service requires online only → pay at salon hidden
- Online payment discounts (e.g., "Save ₹50 when you pay online") displayed prominently when configured by Super Admin / salon campaign

#### 4.5.6 Step 6 — Payment (Online Path)

- Launch secure payment gateway (UPI, cards, wallets per integration)
- Success → create booking → confirmation (§4.5.7)
- Failure → remain on review screen with retry; slot held temporarily (hold TTL per platform config, e.g., 10 minutes)

#### 4.5.7 Booking Confirmation

On successful booking (online paid or pay-at-salon selected):

- **Confirmation popup / full screen** with:
  - **Booking ID** (human-readable appointment reference)
  - Date, time, salon, service, specialist
  - Payment status: Paid / Pay at salon
  - Add to calendar (optional — device calendar export)
- Actions: **View booking**, **Book another**, **Back to home**
- Email/SMS/push confirmation sent (§4.10)

**Initial appointment status:**
- **Booked** — default when consumer completes booking (Admin §4.12)
- Salon may **Confirm** appointment (Admin §4.12.3) → status becomes **Salon Confirmed** (`Confirmed` in system)

---

### 4.6 My Bookings

Central module for appointment lifecycle management.

#### 4.6.1 Bookings List

**Views:**
- **Upcoming** — Booked, Confirmed, In Progress
- **Past** — Completed, Cancelled, No-Show
- **All** — combined with filters

**Search & filters:**

| Filter | Options |
|--------|---------|
| Status | Booked, Confirmed, In Progress, Completed, Cancelled, No-Show |
| Date range | Presets + custom |
| Salon / branch | Typeahead |
| Payment status | Paid, Unpaid, Refunded, Refund pending |
| Payment method | Online, Pay at salon |

**List card fields:**
- Booking ID, date/time, salon name, service, status badge, amount, payment indicator

#### 4.6.2 Booking Detail

Full view for a single appointment:

- Booking ID, status timeline (booked → confirmed → completed / cancelled)
- Salon, branch address (map link), service, specialist, date/time
- Payment breakdown, transaction ID (if online), invoice link
- Notes to salon
- Cancellation policy summary
- Action buttons based on status (§4.6.3–§4.6.8)

#### 4.6.3 Appointment Status Reference

Aligned with Salon Admin (Admin §4.12.1):

| Status | Consumer meaning | Typical next step |
|--------|------------------|-------------------|
| **Booked** | Appointment placed; awaiting salon confirmation (if confirmation step enabled) | Cancel, reschedule, request confirm |
| **Confirmed** | Salon acknowledged booking | Request cancel, reschedule |
| **In Progress** | Service underway at salon | View only |
| **Completed** | Service delivered | Feedback, invoice, raise ticket |
| **Cancelled** | Appointment cancelled | View refund status if applicable |
| **No-Show** | User did not attend | View record; may affect future booking policy |

#### 4.6.4 Cancel Booking

| Current status | Consumer action | Refund / payment |
|----------------|-----------------|------------------|
| **Booked** | **Cancel** directly — select reason (from master list) → confirm | If **paid online** → refund **initiated automatically** per platform rules; status visible in booking detail |
| **Confirmed** | **Request cancellation** — not instant; sent to salon for approval | On salon approval → cancelled; if paid online → refund initiated by salon/admin (Admin §4.12.4) |
| **In Progress / Completed / Cancelled / No-Show** | Cancel not available | — |

- Cancellation reason codes from Super Admin master configuration
- User notified when cancellation request approved/rejected (Confirmed path)
- Cancelled slot freed for rebooking (Admin §4.12.4)

#### 4.6.5 Reschedule Booking

Available when status is **Booked** or **Confirmed**:

1. User taps **Reschedule**
2. Re-enters flow: date → slot → specialist (same service; change service = cancel + new booking in v1)
3. Review updated summary
4. Confirm reschedule — prior slot released, new slot reserved
5. Notification to user and salon (Admin §4.12.3)

**Rules:**
- Reschedule cutoff: e.g., not within 2 hours of appointment (platform/salon configurable)
- If online paid, no additional charge if same price; price difference handling per platform rule (charge/refund delta — future or v1 simple: same service price only)

#### 4.6.6 Feedback & Rating

Available after status **Completed**:

- Star rating (1–5) for overall experience — **required**
- Optional category ratings: service quality, specialist, cleanliness, value
- Optional text review (moderated per Super Admin policy)
- **Image upload (optional)** — user can upload an image with their review (e.g., result photo, salon ambiance). **Submitting a review does not require an image**; star rating is still required.
- One feedback submission per completed booking; editable within 7 days (configurable)

**Image upload:**
- Add from camera or photo library after rating/text entry
- Preview before submit; user can remove and replace before posting
- Supported formats and max file size per platform config (e.g., JPEG/PNG/WebP, max 5 MB)
- Image submitted with the same review record; shown on salon review list when published
- If review is edited within the edit window, user may add, replace, or remove uploaded images
- If review is removed by moderation, associated images are removed from public display

Reviews contribute to salon/specialist aggregate ratings on discovery screens. Uploaded images display on the review they belong to.

#### 4.6.7 Invoice Download

- Available for **Completed** bookings (and **Cancelled** with payment/refund record where invoice policy applies)
- **Download PDF** from booking detail
- Invoice includes: booking ID, salon GST details (if configured), service, amount, tax, payment method, transaction ref, date

#### 4.6.8 Raise Ticket (Booking-Linked)

From booking detail, user raises support ticket:

- Reason & sub-reason (Super Admin master list — consumer-facing subset)
- Description, photo attachments (e.g., service issue)
- Booking auto-linked
- Ticket status: Open, In Progress, Resolved, Closed
- User views replies in app; notified on update (Super Admin §4.11 parallel for consumer tickets)

---

### 4.7 Profile & Account

#### 4.7.1 View Profile

- Full name, email, phone (masked partially), profile photo
- Verification badges on profile: email ✓ (auto for Google OAuth; OTP for email signup), phone ✓ (OTP)
- Member since date
- Booking count summary (optional)

#### 4.7.2 Edit Profile

- Editable: name, profile photo
- Email / phone change → triggers OTP re-verification for the changed field (email OTP skipped if account uses Google OAuth and email unchanged)
- Save with validation

#### 4.7.3 Saved Locations

- Home, work, or custom labels with address/map pin
- Used as discovery context alternative to GPS
- Add, edit, delete

#### 4.7.4 Notification Preferences

Toggle channels per event type:

| Event | Push | Email | SMS |
|-------|------|-------|-----|
| Booking confirmation | ✓ | ✓ | ✓ |
| Reminder (24h / 2h before) | ✓ | ✓ | ✓ |
| Status change (confirmed, cancelled) | ✓ | ✓ | ✓ |
| Refund processed | ✓ | ✓ | ✓ |
| Promotional offers | ✓ | ✓ | opt-in |

#### 4.7.5 Change Password

- For email/password accounts only
- Current password + new password + confirm
- Google-only accounts: optional "set password" for backup login

#### 4.7.6 Account Disabled / Delete

- Disabled accounts handled at login (§4.1.1)
- **Delete account request** — submit request for data deletion (GDPR-style); Super Admin processes (recommended future / compliance)

---

### 4.8 Help & Support (General)

Accessible from Profile without a booking context.

- Browse FAQ (from Super Admin CMS §4.9.1 — consumer FAQ section)
- **Contact support** — create ticket (reason, description, attachments)
- View **My tickets** — list and detail with status
- Platform support hours and expected response SLA (display only)

---

### 4.9 Notifications Center

In-app notification feed (bell icon / tab):

- Booking confirmations, reminders, status updates
- Cancellation approved/rejected
- Refund completed
- Promotional messages (if opted in)
- Tap notification → deep link to booking or relevant screen
- Mark as read; clear all

---

### 4.10 Notifications (Outbound)

Triggered events (minimum v1):

| Event | Recipient | Channels |
|-------|-----------|----------|
| Signup / verification OTP | End user | Email (email signup only) / SMS |
| Booking confirmed (created) | End user | Push, email, SMS |
| Salon confirmed appointment | End user | Push, email |
| Reminder 24h / 2h before | End user | Push, SMS |
| Rescheduled | End user | Push, email |
| Cancelled (by user or salon) | End user | Push, email, SMS |
| Refund initiated / completed | End user | Push, email |
| Cancellation request rejected | End user | Push, email |
| Ticket reply | End user | Push, email |

Templates and enablement configured in Super Admin Master Configuration.

---

## 5. Business Rules & Edge Cases

### 5.1 Discovery & Eligibility

- **Authentication required** — no salon list, search, map, or branch detail without a signed-in session and completed verification (phone OTP minimum; email OTP additionally for email + password signup)
- Only **Active** branches with **Active** org status appear in discovery
- Suspended/terminated orgs: branches hidden; existing bookings show limited actions with explanatory message
- **Google sign-up / sign-in:** phone OTP required; email OTP **not** required
- **Email + password sign-up:** email OTP and phone OTP required
- User must hold a valid session with required verifications complete before any in-app feature is available

### 5.2 Availability & Slots

- Slots follow Admin §4.11: operating hours, service duration, specialist weekly off, leave, branch holidays, existing appointments
- **No Specialist Available** slots are not bookable
- Auto-assign uses platform algorithm; user sees assigned specialist name on confirmation

### 5.3 Payments

- **Pay online:** B2C transaction recorded (Super Admin §4.5); GlowTap commission applied per salon rate
- **Pay at salon:** Booking created with unpaid status; salon collects offline; transaction may be recorded by salon/admin separately per future scope
- Online payment promos apply only when user selects pay online and payment succeeds
- Failed payment does not create booking

### 5.4 Cancellations & Refunds

| Scenario | Behavior |
|----------|----------|
| User cancels while **Booked** | Immediate cancel; online refund auto-initiated |
| User requests cancel while **Confirmed** | Pending salon approval; user notified of outcome |
| Salon/admin cancels | User notified; online refund initiated by salon side (Admin §4.12.4) |
| Refund status | Visible on booking: Initiated → Processing → Completed / Failed |

Refund timing subject to payment gateway; commission reversal per Super Admin rules.

### 5.5 Reschedule & No-Show

- Reschedule allowed only for Booked and Confirmed within policy window
- **No-Show** set by salon admin — user cannot dispute in-app beyond raising ticket
- Repeated no-shows may trigger booking restrictions (platform policy — future)

### 5.6 Reviews

- Only **Completed** bookings eligible for feedback
- Star rating **required** to submit a review; text, category ratings, and image are **optional**
- User **may** upload an image with the review — image is not mandatory
- Salons cannot edit consumer reviews or uploaded images; Super Admin may moderate/remove policy violations (text and/or image)
- Review images subject to same moderation policy as text (inappropriate content taken down with review or image-only removal per policy)

### 5.7 Account & Abuse

- Super Admin disable immediately blocks new bookings and login
- Rate limits on OTP requests and failed login attempts

---

## 6. Integration Summary (Cross-Portal)

| Capability | Consumer app | Salon Admin | Super Admin |
|------------|--------------|-------------|-------------|
| Self-registration | Yes | No (created on approval) | View/disable only |
| Service catalog | Read | Create/edit | — |
| Slot availability | Read (book) | Configure + preview | — |
| Appointments | Create, cancel, reschedule | Confirm, cancel, complete | View via transactions |
| B2C payment | Pay online | View transactions | Commission + reports |
| Support tickets | Raise (booking/general) | Raise to platform | Manage all |
| Promotional banners | Consumer audience | Salon admin audience | Configure |
| Reviews | Submit (optional image) | View (read-only) | Moderate (future) |

---

## 7. Out of Scope (v1.0)

- Multi-service cart / single checkout for multiple services
- In-app chat with salon (ticket-based support only)
- Loyalty points / wallet balance
- Gift cards
- Product retail purchase (services only)
- Staff-facing mobile app
- Walk-in booking creation by consumer without slot
- Video consultation bookings

---

## 8. Glossary

| Term | Definition |
|------|------------|
| **End User / Customer** | Consumer using the GlowTap app to book salon services |
| **Branch** | Physical salon location; primary bookable entity |
| **Org / Organization** | Salon business owning one or more branches |
| **Booking / Appointment** | Scheduled service reservation with date, time, specialist |
| **Booked** | Initial status after consumer completes booking flow |
| **Confirmed** | Salon acknowledged the appointment (Salon Confirmed) |
| **Specialist** | Employee tagged to perform specific services (Admin §4.10) |
| **Slot** | Bookable time window from availability engine (Admin §4.11) |
| **B2C Transaction** | End-user payment to salon for a booking |
| **Pre-invoice** | Order review screen showing line items before payment |
| **Review image** | Optional image uploaded by end user with booking feedback (not required to post the review) |
| **Pay at salon** | Offline payment option at time of visit — no online charge at booking |

---

## 9. Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.3 | July 4, 2026 | GlowTap Product Team | Optional image upload on booking reviews |
| 1.2 | June 30, 2026 | GlowTap Product Team | Google sign-in/sign-up skips email OTP; phone OTP still required |
| 1.1 | June 30, 2026 | GlowTap Product Team | Removed guest/unauthenticated access; auth required for all app features |
| 1.0 | June 30, 2026 | GlowTap Product Team | Initial End Customer app functional specification |

---

*This document describes the intended behavior of the GlowTap End Customer App. Technical implementation details will be covered in the companion Customer Solutioning Document.*
