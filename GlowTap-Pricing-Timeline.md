# GlowTap Platform
## Pricing & Timeline Document

**Version:** 1.3  
**Date:** June 27, 2026  
**Audience:** Stakeholders, project sponsors, delivery team  
**Purpose:** Define project phases, SDLC-aligned delivery schedule, milestone-based pricing, payment terms, and change-management SLAs for the GlowTap platform (Super Admin, Salon Admin, End Customer).

---

## 1. Executive Summary

GlowTap delivery follows a **strict three-phase sequence**. Each phase gates the next stage of work:

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────────────────┐
│  PHASE 1         │     │  PHASE 2         │     │  PHASE 3B — FRONTEND         │
│  Solutioning     │ ──► │  Design          │ ──► │  starts after Phase 2        │
│  (Documents)     │     │  (UI/UX Figma)   │     │  AND Phase 3A (Backend)      │
└────────┬─────────┘     └──────────────────┘     └──────────────────────────────┘
         │
         └──────────────────► Phase 3A: DB + Backend
                              starts after Phase 1
                              (runs in parallel with Phase 2)
```

| Phase | Order | Scope | Investment |
|-------|-------|-------|------------|
| **Phase 1 — Solutioning** | **1st** | Functional + Solutioning documents (all portals) | Part of **₹2,30,000** (M1, M2) |
| **Phase 2 — Design** | **2nd** | UI/UX screen designs (Super Admin, Admin, Customer) | **₹60,000** |
| **Phase 3 — Development** | **3rd** | DB architecture, backend APIs, frontend (React) | Part of **₹2,30,000** (M3–M5) |
| **Grand Total** | | | **₹2,90,000** |

### Phase Gate Rules

| Gate | Rule |
|------|------|
| **Design (Phase 2)** | Starts **after Phase 1 (Solutioning)** — designs are based on approved functional & solution specs |
| **DB + Backend (Phase 3A)** | Starts **after Phase 1 (Solutioning)** — schema and APIs derived from approved solution documents |
| **Frontend (Phase 3B)** | Starts **after Phase 2 (Design) closure AND Phase 3A (Backend) closure** — 20 working days; Super Admin + Admin React only |

> **Note:** Backend and Design may **run in parallel** once solutioning is complete. **Frontend starts only after both Design sign-off and Backend closure** (all APIs available via Swagger).

> End Customer **React Native** app development is **out of scope** for Phase 3 frontend. Customer **APIs** and **UI designs** are included.

---

## 2. SDLC Overview

| SDLC Phase | GlowTap Deliverable | Project Phase | Target |
|------------|---------------------|---------------|--------|
| **Planning & Requirements** | Kickoff, scope agreement, sample screen review | Pre-Phase 2 | June 29, 2026 |
| **Analysis & Solutioning** | Functional + Solutioning PDFs (all portals) | **Phase 1** | See §3 |
| **Design** | Figma screen designs (first drafts + iterations) | **Phase 2** | See §4 |
| **Architecture** | DB schema, system architecture, infra sizing | **Phase 3** (post-Phase 1) | July 20–25, 2026 |
| **Development — Backend** | Interlinked microservices + Swagger | **Phase 3** (post-Phase 1) | End of August, 2026 |
| **Development — Frontend** | React web — Super Admin + Admin | **Phase 3B** (post-Phase 2 + 3A) | 20 days after design **and** backend closure |
| **Testing** | Unit tests, DB performance report (PL/SQL) | Phase 3 | With M3–M5 |
| **Deployment** | AWS EC2 production handover | Phase 3 | Post frontend |
| **Maintenance** | Post-go-live support | — | Separate agreement |

```
SDLC Flow (sequential phases):

  Phase 1          Phase 2              Phase 3B
  Solutioning  →   Design          →    Frontend
       │                │                    ▲
       └────────► Phase 3A: DB + Backend ───┘
                (parallel with Design;
                 both must close before Frontend)
```

---

## 3. Phase 1 — Solutioning *(First)*

### 3.1 Objective

Define **what** the platform does and **how** it will be built — functional specifications and technical solutioning documents for all three portals **before** design or development begins.

### 3.2 Solution Documentation Timeline

| Document / Portal | Status | Target Date |
|-------------------|--------|-------------|
| **Super Admin** — Functional + Solutioning | **Closed & Approved** | Complete |
| **Salon Admin** — Functional + Solutioning | In progress | **July 1, 2026** |
| **End Customer** — Functional + Solutioning | In progress | **July 5, 2026** |

### 3.3 Phase 1 Deliverables

- Functional Specification PDF (business flows, modules, rules)
- Solutioning & Technical Architecture PDF (stack, data model, APIs, deployment)
- Stakeholder review and written approval per portal
- Baseline for Phase 2 (Design) and Phase 3 (DB / Backend)

### 3.4 Phase 1 — Pricing & Payment Milestones

| Milestone | Description | Amount | Cumulative |
|-----------|-------------|--------|------------|
| **M1 — Advance Payment** | Project kickoff | **₹20,000** | ₹20,000 |
| **M2 — Solutioning & Functional Document Closure** | All three portal specs approved (Super Admin ✓, Admin, Customer) | **₹20,000** | **₹40,000** |

**Phase 1 subtotal (within development engagement): ₹40,000**

> Phase 1 closure (all solution docs approved by **July 5, 2026**) **unlocks** Phase 2 (Design kickoff) and Phase 3 DB/Backend work.

---

## 4. Phase 2 — Design *(Second)*

### 4.1 Objective

Deliver **first-draft UI/UX screen designs** in Figma for all three portals — **after** solutioning documents are approved. Designs reflect approved functional flows, brand identity (logo, purple/violet theme), and mobile-first beauty-tech positioning.

### 4.2 Pre-Requisite

| Requirement | Date | Impact if Delayed |
|-------------|------|-------------------|
| **Phase 1 complete** — solution docs approved | **By July 5, 2026** | Blocks design kickoff |
| Stakeholder confirmation of **sample screens** | **June 29, 2026** | Shifts all design dates below |

### 4.3 Design Timeline (First Drafts)

| Portal | First Draft Target | Payment Trigger |
|--------|-------------------|-----------------|
| **Super Admin** screens | **July 10, 2026** | D2 milestone |
| **Salon Admin** portal | **July 25, 2026** | D3 milestone |
| **End Customer** screens | **August 10, 2026** | D4 milestone |

> First drafts only. Final closure driven by feedback cycles. Delays in sample confirmation or feedback shift dates proportionally.

### 4.4 Design Feedback SLA

| Priority | Definition | Turnaround |
|----------|------------|------------|
| **Critical** | Blocker — impacts dependent screens or delivery dates | **2 business days** |
| **High** | Blocker for a screen but not overall schedule | **3 business days** |
| **Low** | Cosmetic / non-blocking changes | **5 business days** |

### 4.5 Design Scope & Exclusions

**Included:** Screen designs (3 portals), logo/brand integration, iteration per SLA, Figma exports (free tier).

**Excluded:** Figma paid plan costs (reimbursed on actuals if required), React Native build, advanced prototypes (unless CR).

### 4.6 Phase 2 — Pricing & Payment Milestones

| Milestone | Description | Amount | Cumulative |
|-----------|-------------|--------|------------|
| **D1 — Advance** | Design kickoff (post-Phase 1) | **₹10,000** | ₹10,000 |
| **D2 — Super Admin Screen Closure** | Super Admin designs approved | **₹15,000** | ₹25,000 |
| **D3 — Admin Portal Design** | Salon Admin designs accepted | **₹20,000** | ₹45,000 |
| **D4 — Customer Screen Design** | Customer designs accepted | **₹15,000** | **₹60,000** |

**Phase 2 Total: ₹60,000**

> Revised from ₹40,000 to **₹60,000** for complexity, logo integration, and iteration volume.

> **Phase 2 full closure (D4)** is required for frontend. **Phase 3A backend closure** is also required. Frontend kickoff occurs when **both** are complete.

---

## 5. Phase 3 — Development *(Third)*

### 5.1 Objective

Build production-ready **database**, **backend microservices**, and **React frontend** per approved solutioning (Phase 1) and design (Phase 2).

### 5.2 Technology Stack

| Layer | Technology |
|-------|------------|
| Frontend (Web) | React + TypeScript, Redux Toolkit + RTK Query |
| Frontend (Mobile) | React Native *(out of scope for dev milestone)* |
| Backend | Node.js + Fastify (TypeScript) |
| Database | PostgreSQL or MongoDB *(TBD)* |
| Cache | Redis / Valkey |
| Storage | AWS S3 |
| Jobs | BullMQ |
| Deployment | AWS EC2 |
| API Docs | Swagger (OpenAPI) |

---

### 5.3 Track A — DB & Backend *(Starts after Phase 1)*

Begins once solutioning documents are approved. May **run in parallel** with Phase 2 (Design).

#### Database & Architecture + Performance Testing

| Deliverable | Target Date |
|-------------|-------------|
| Database schema | **July 20–25, 2026** |
| System architecture document | **July 20–25, 2026** |
| Performance testing report (PL/SQL) | **July 20–25, 2026** |

**Performance test environment:**

| Resource | Specification |
|----------|---------------|
| vCPU | 8 Cores |
| RAM | 32 GB |
| Disk | 400 GB NVMe |
| Bandwidth | 32 TB |

#### Backend Microservices

Interlinked services — planned closure **End of August 2026**.

| Module | Swagger | Milestone Value |
|--------|---------|-----------------|
| Super Admin APIs | Yes | ₹20,000 |
| Salon Admin APIs | Yes | ₹20,000 |
| Customer APIs | Yes | ₹40,000 |

**Per module:** REST endpoints, Swagger docs, unit tests, shared service integration (auth, DB, Redis, S3, BullMQ).

---

### 5.4 Track B — Frontend *(Starts after Phase 2 + Phase 3A)*

| Item | Detail |
|------|--------|
| **Start condition** | **Both** gates satisfied: (1) Phase 2 (Design) fully closed — D4 sign-off, **AND** (2) Phase 3A (Backend) closed — all APIs live with Swagger (end Aug) |
| **Duration** | **20 working days** from dual-closure date |
| **In scope** | Super Admin + Salon Admin React web portals |
| **Out of scope** | End Customer React Native app |
| **Estimated start** | ~Early September, 2026 *(design ~August 10 + backend end of August)* |
| **Estimated completion** | ~Late September / Early October 2026 |

```
Phase sequence (development tracks):

  Phase 1: Solutioning ──► by 5 Jul
         │
         ├──────────────────────────────────┐
         ▼                                  ▼
  Phase 3A: DB (20-25 Jul)         Phase 2: Design
         + Backend (→ end Aug)       Super Admin  10 Jul
         (parallel with design)      Admin        25 Jul
                                      Customer     10 Aug
         │                                  │
         └──────────────┬───────────────────┘
                        ▼
              BOTH must close
                        ▼
              Track B: Frontend
              20 working days
              Super Admin + Admin React
```

---

### 5.5 Testing & Deployment

| Activity | When | Deliverable |
|----------|------|-------------|
| DB performance testing | July, 2026 (M3) | Benchmark report |
| Backend unit tests | August, 2026 (M4) | Test suites per service |
| API integration testing | August, 2026 | Swagger coverage |
| Frontend testing | Post 20-day sprint | React component + integration tests |
| UAT | Pre-deployment | Staging on EC2 |
| Deployment | Post frontend | Production handover, runbook, repo access |

---

### 5.6 Phase 3 — Pricing & Payment Milestones

| Milestone | Description | Amount | Cumulative (Phase 3) |
|-----------|-------------|--------|---------------------|
| **M3 — DB Architecture & Performance Report** | Schema, architecture, PL/SQL perf report | **₹30,000** | ₹30,000 |
| **M4 — Backend + Unit Tests** | All microservices + Swagger | **₹80,000** | ₹1,10,000 |
| **M5 — Frontend (React Only)** | Super Admin + Admin portals; Cursor included | **₹80,000** | **₹1,90,000** |

**Phase 3 subtotal: ₹1,90,000**  
**Phase 1 + Phase 3 combined: ₹2,30,000**

#### M4 Breakdown (Backend)

| Module | Amount |
|--------|--------|
| Super Admin APIs + Swagger | ₹20,000 |
| Admin APIs + Swagger | ₹20,000 |
| Customer APIs + Swagger | ₹40,000 |

#### M5 Breakdown (Frontend)

| Module | Amount |
|--------|--------|
| Super Admin — React | ₹40,000 |
| Salon Admin — React | ₹40,000 |
| Cursor usage | Included |

---

## 6. Combined Pricing Summary

| Phase | Order | Total |
|-------|-------|-------|
| **Phase 1 — Solutioning** | 1st | ₹40,000 *(M1 + M2)* |
| **Phase 2 — Design** | 2nd | ₹60,000 *(D1–D4)* |
| **Phase 3 — Development** | 3rd | ₹1,90,000 *(M3–M5)* |
| **Grand Total** | | **₹2,90,000** |

### Payment Schedule (Chronological)

| # | Phase | Milestone | Amount | Trigger |
|---|-------|-----------|--------|---------|
| 1 | 1 | M1 — Advance | ₹20,000 | On signing |
| 2 | 2 | D1 — Design advance | ₹10,000 | After Phase 1 kickoff / design start |
| 3 | 1 | M2 — Solution docs closure | ₹20,000 | Admin (July 1) + Customer (July 5) approved |
| 4 | 2 | D2 — Super Admin designs | ₹15,000 | Super Admin screens — July 10 |
| 5 | 3 | M3 — DB + Architecture + Perf | ₹30,000 | July 20–25 accepted |
| 6 | 2 | D3 — Admin designs | ₹20,000 | Admin portal — July 25 |
| 7 | 3 | M4 — Backend + unit tests | ₹80,000 | End of August — APIs + Swagger |
| 8 | 2 | D4 — Customer designs | ₹15,000 | Customer screens — August 10 |
| 9 | 3 | M5 — Frontend (React) | ₹80,000 | 20-day sprint complete (post design + backend closure) |

```
Phase 1  Solutioning   ₹20K ──► ₹20K                    = ₹40,000
Phase 2  Design         ₹10K ──► ₹15K ──► ₹20K ──► ₹15K = ₹60,000
Phase 3  Development              ₹30K ──► ₹80K ──► ₹80K = ₹1,90,000
         ─────────────────────────────────────────────────────────────
         Grand Total                                      ₹2,90,000
```

---

## 7. Master Timeline (Gantt View)

| Activity | Jun | Jul | Aug | Sep | Oct |
|----------|-----|-----|-----|-----|-----|
| **PHASE 1** Sample screens confirm (June 29) | ◆ | | | | |
| **PHASE 1** Super Admin solution docs | ✓ | | | | |
| **PHASE 1** Admin + Customer solution docs | | ◆◆ | | | |
| **PHASE 3A** DB + Architecture + Perf (July 20–25) | | ◆ | | | |
| **PHASE 3A** Backend microservices (→ end Aug) | | ████████ | ████ | | |
| **PHASE 2** Super Admin designs (July 10) | | ◆ | | | |
| **PHASE 2** Admin designs (July 25) | | ◆ | | | |
| **PHASE 2** Customer designs (August 10) | | | ◆ | | |
| **PHASE 3B** Frontend React — 20 days (post design + backend) | | | | ████ | ◆ |
| Deployment & handover | | | | ◆ |

**Legend:** ✓ Done | ◆ Milestone | ████ Active work  
**Note:** Phase 3A (DB/Backend) runs **parallel** to Phase 2 (Design) after Phase 1 closes.

---

## 8. Assumptions & Dependencies

### Stakeholder

- Confirm sample screens by **June 29, 2026**
- Approve solution docs within **5 business days** of submission
- Provide feedback per design SLA (§4.4)
- Designate single point of contact

### Delivery Team

- Complete Phase 1 before Phase 2 kickoff
- Start DB/Backend immediately after Phase 1 approval
- Start Frontend only after **Phase 2 (D4) and Phase 3A (backend)** both signed off
- Weekly status updates during active sprints

### Key Assumptions

- Phase order: **Solutioning → Design**; **Backend post-Solutioning**; **Frontend post-Design AND post-Backend**
- DB selection finalized before M3 (target: July 15, 2026)
- Scope per approved specs; additions are change requests
- Customer React Native quoted separately if needed

---

## 9. Change Request Policy

Out-of-scope changes documented within 3 business days, executed on written approval only.

| Change Type | Impact |
|-------------|--------|
| New API module | Backend timeline + cost |
| Design rework post sign-off | Design extension + quote |
| Customer mobile app | Separate SOW |

---

## 10. Risk Register

| Risk | Mitigation |
|------|------------|
| Phase 1 delay past July 5 | Blocks Phase 2 and Phase 3A start — recalculate all dates |
| Sample screens not confirmed (June 29) | Escalate; shifts Phase 2 dates |
| Design started before solutioning | **Not permitted** — enforce phase gate |
| Frontend started before design or backend closure | **Not permitted** — dual gate enforced |
| Design or backend lag near frontend start | Confirm dual-closure date in writing before M5 kickoff |
| Figma free tier limits | Reimburse paid plan on actuals |

---

## 11. Acceptance Criteria

### Phase 1 — Solutioning

- [ ] Functional + Solutioning PDFs delivered per portal
- [ ] Written stakeholder approval

### Phase 2 — Design

- [ ] Figma screens per portal with brand theme
- [ ] Written sign-off or feedback log per D2–D4

### Phase 3 — Development

| Milestone | Criteria |
|-----------|----------|
| M3 | ER diagram, schema, architecture doc, perf report |
| M4 | Swagger live; unit tests pass; core flows operational |
| M5 | Super Admin + Admin React on staging, API-connected |

---

## 12. Out of Scope

- End Customer React Native development
- Figma paid fees (reimbursed if required)
- AWS running costs, payment gateway setup, app store submission
- Post-warranty maintenance, content creation

---

## 13. Document Control

| Version | Date | Changes |
|---------|------|---------|
| 1.3 | June 27, 2026 | Added §14 Delivery Delay Tracker |
| 1.2 | June 27, 2026 | Frontend gate: requires both Design closure and Backend closure |
| 1.1 | June 27, 2026 | Reordered phases: Solutioning 1st → Design 2nd → Dev tracks |
| 1.0 | June 27, 2026 | Initial release |

---

## 14. Delivery Delay Tracker

Use this section to record **actual vs planned delivery dates**, delay duration, root cause, and agreed recovery actions. Update after each phase or milestone review.

### 14.1 Phase 1 — Solutioning

| Deliverable | Planned Date | Actual Date | Delay (Days) | Reason | Owner | Recovery / Revised Date |
|-------------|-------------|-------------|--------------|--------|-------|-------------------------|
| Super Admin — Functional + Solutioning | Complete | | — | | | |
| Salon Admin — Functional + Solutioning | July 1, 2026 | | | | | |
| End Customer — Functional + Solutioning | July 5, 2026 | | | | | |
| **M2 — Phase 1 closure (all docs approved)** | July 5, 2026 | | | | | |

### 14.2 Phase 2 — Design

| Deliverable | Planned Date | Actual Date | Delay (Days) | Reason | Owner | Recovery / Revised Date |
|-------------|-------------|-------------|--------------|--------|-------|-------------------------|
| Sample screens — stakeholder confirmation | June 29, 2026 | | | | | |
| Super Admin — first draft (D2) | July 10, 2026 | | | | | |
| Salon Admin — first draft (D3) | July 25, 2026 | | | | | |
| End Customer — first draft (D4) | August 10, 2026 | | | | | |
| **Phase 2 closure (all designs signed off)** | August 10, 2026 | | | | | |

### 14.3 Phase 3A — DB & Backend

| Deliverable | Planned Date | Actual Date | Delay (Days) | Reason | Owner | Recovery / Revised Date |
|-------------|-------------|-------------|--------------|--------|-------|-------------------------|
| DB schema + architecture document | July 20–25, 2026 | | | | | |
| Performance testing report (PL/SQL) | July 20–25, 2026 | | | | | |
| **M3 — DB + Architecture + Perf report accepted** | July 25, 2026 | | | | | |
| Super Admin APIs + Swagger | End of August, 2026 | | | | | |
| Salon Admin APIs + Swagger | End of August, 2026 | | | | | |
| Customer APIs + Swagger | End of August, 2026 | | | | | |
| **M4 — Backend closure (all APIs + unit tests)** | End of August, 2026 | | | | | |

### 14.4 Phase 3B — Frontend

| Deliverable | Planned Date | Actual Date | Delay (Days) | Reason | Owner | Recovery / Revised Date |
|-------------|-------------|-------------|--------------|--------|-------|-------------------------|
| **Dual gate met** (Design D4 + Backend M4) | End of August, 2026 | | | | | |
| Frontend sprint start (Super Admin + Admin React) | TBD post dual gate | | | | | |
| **M5 — Frontend closure (20 working days)** | TBD + 20 days | | | | | |
| Deployment & handover (EC2 staging/prod) | Post M5 | | | | | |

### 14.5 Delay Summary Log

| # | Date Logged | Phase / Milestone | Days Delayed | Category | Reason (summary) | Impact | Action Taken |
|---|-------------|-------------------|--------------|----------|------------------|--------|--------------|
| 1 | | | | Stakeholder / Delivery / Technical / Scope | | | |
| 2 | | | | | | | |
| 3 | | | | | | | |

**Delay categories:**

| Category | Examples |
|----------|----------|
| **Stakeholder** | Late feedback, sample screen confirmation slip, approval delays |
| **Delivery** | Resource availability, dependency on third-party access |
| **Technical** | DB selection pending, infra provisioning, integration blockers |
| **Scope** | Change requests, new requirements post sign-off |

> **Review cadence:** Update this tracker at each milestone payment trigger and in weekly status meetings. Revised dates in the Recovery column supersede planned dates in §3–§5 until the next change.

---

*Phase 1 must complete before Phase 2 begins. Phase 3A (Backend) may start after Phase 1 and run parallel to Phase 2. Phase 3B (Frontend) starts only after **both** Phase 2 and Phase 3A close.*
