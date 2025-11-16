# Pixora - Product Roadmap & Backlog

## 📊 Release Plan Overview

| Version | Timeline | Target Users | Key Features | Status |
|---------|----------|--------------|--------------|--------|
| **MVP** | Q1 2025 (8 weeks) | Early adopters, beta testers | Auth, Projects, Whiteboard, Mock AI | 🔄 In Progress |
| **v1.0** | Q2 2025 (6 weeks) | SMBs, Marketing agencies | Real-time collab, Live AI, Stripe | 📋 Planned |
| **v1.5** | Q3 2025 (8 weeks) | Startups, Design teams | Brand library, Templates, Integrations | 🔮 Future |
| **Enterprise** | Q4 2025 (12 weeks) | Enterprises (100+ users) | SSO, Audit logs, On-premise | 🔮 Future |

---

## Sprint Planning (2-week sprints)

### Sprint 0: Foundation (Week 1-2) ✅ DONE
**Goal**: Infrastructure & architecture setup

| Story ID | User Story | Story Points | Status |
|----------|-----------|--------------|--------|
| INFRA-1 | Setup project structure (mono-repo, workspaces) | 2 | ✅ Done |
| INFRA-2 | Create Docker Compose dev environment | 3 | ✅ Done |
| INFRA-3 | Design & document architecture | 3 | ✅ Done |
| INFRA-4 | Setup PostgreSQL schema & migrations | 5 | ✅ Done |
| INFRA-5 | Create Makefile with dev commands | 1 | ✅ Done |
| INFRA-6 | Setup CI/CD pipeline (GitHub Actions) | 3 | 🔄 In Progress |

**Total**: 17 SP | **Velocity**: ~17 SP/sprint

---

### Sprint 1: Authentication & User Management (Week 3-4)
**Goal**: Users can signup, login, and manage profile

| Story ID | User Story | Acceptance Criteria | Story Points | Priority |
|----------|-----------|---------------------|--------------|----------|
| AUTH-1 | **As a** new user, **I want to** sign up with email/password **so that** I can create an account | - Email validation<br>- Password min 8 chars<br>- Password hashed with bcrypt<br>- 100 free tokens credited<br>- Confirmation email sent | 5 | P0 |
| AUTH-2 | **As a** registered user, **I want to** log in **so that** I can access my account | - Email/password validation<br>- JWT + refresh token issued<br>- Redirect to /projects | 3 | P0 |
| AUTH-3 | **As a** user, **I want to** log in with Google OAuth **so that** I can skip manual signup | - OAuth2 flow<br>- Auto-create account if new<br>- Merge account if email exists | 5 | P1 |
| AUTH-4 | **As a** user, **I want to** refresh my session **so that** I don't have to re-login constantly | - Refresh token endpoint<br>- New JWT issued<br>- Old refresh token invalidated | 3 | P0 |
| AUTH-5 | **As a** user, **I want to** log out **so that** my session is terminated | - Refresh token revoked in DB<br>- Client cleared | 1 | P1 |
| USER-1 | **As a** user, **I want to** view my profile **so that** I can see my info | - GET /users/me endpoint<br>- Returns user data + token balance | 2 | P1 |
| USER-2 | **As a** user, **I want to** update my profile **so that** I can change my name/avatar | - PATCH /users/me endpoint<br>- Validation<br>- Update timestamp | 3 | P2 |

**Total**: 22 SP

---

### Sprint 2: Projects & Whiteboard MVP (Week 5-6)
**Goal**: Users can create projects and basic whiteboard

| Story ID | User Story | Acceptance Criteria | Story Points | Priority |
|----------|-----------|---------------------|--------------|----------|
| PROJ-1 | **As a** user, **I want to** create a project **so that** I can organize my work | - POST /projects endpoint<br>- Auto-create empty board<br>- Set default settings | 3 | P0 |
| PROJ-2 | **As a** user, **I want to** list my projects **so that** I can see all my work | - GET /projects with pagination<br>- Order by updated_at DESC<br>- Show thumbnail | 2 | P0 |
| PROJ-3 | **As a** user, **I want to** view a project **so that** I can see details | - GET /projects/:id<br>- Show metadata, settings, collaborators | 1 | P0 |
| PROJ-4 | **As a** user, **I want to** update a project **so that** I can change title/settings | - PATCH /projects/:id<br>- Validation<br>- Only owner can update | 2 | P1 |
| PROJ-5 | **As a** user, **I want to** delete a project **so that** I can remove unwanted projects | - DELETE /projects/:id (soft delete)<br>- Only owner can delete<br>- Confirmation modal | 2 | P2 |
| BOARD-1 | **As a** user, **I want to** open a whiteboard **so that** I can start creating | - Load /board/:id page<br>- Render canvas with React Konva<br>- Show toolbar | 5 | P0 |
| BOARD-2 | **As a** user, **I want to** upload an image to the board **so that** I can add visuals | - Upload button<br>- Generate presigned S3 URL<br>- Upload to S3<br>- Place image on canvas | 5 | P0 |
| BOARD-3 | **As a** user, **I want to** move/resize/rotate images **so that** I can arrange my design | - Drag & drop<br>- Transform handles<br>- Snap to grid (optional) | 5 | P0 |
| BOARD-4 | **As a** user, **I want to** save my board **so that** my work persists | - POST /boards/:id/save<br>- Serialize canvas to JSON<br>- Save to DB | 3 | P0 |
| BOARD-5 | **As a** user, **I want to** my board to auto-load on refresh **so that** I don't lose work | - Load board state from DB<br>- Deserialize and render canvas | 3 | P0 |

**Total**: 31 SP

---

### Sprint 3: Real-time Collaboration (Week 7-8)
**Goal**: Multiple users can edit simultaneously

| Story ID | User Story | Acceptance Criteria | Story Points | Priority |
|----------|-----------|---------------------|--------------|----------|
| COLLAB-1 | **As a** user, **I want to** see other users' cursors **so that** I know who's editing | - Yjs awareness<br>- Show cursor position + name<br>- Color-coded per user | 5 | P0 |
| COLLAB-2 | **As a** user, **I want to** edits to sync in real-time **so that** I see changes immediately | - Yjs CRDT sync<br>- WebSocket connection<br>- <500ms sync latency | 8 | P0 |
| COLLAB-3 | **As a** user, **I want to** my changes to persist after disconnect **so that** I don't lose work | - Offline buffer (Yjs)<br>- Auto-sync on reconnect<br>- No conflicts | 5 | P0 |
| COLLAB-4 | **As a** user, **I want to** invite collaborators **so that** my team can work together | - POST /projects/:id/collaborators<br>- Send email invite<br>- Token link expires in 7 days | 5 | P1 |
| COLLAB-5 | **As a** project owner, **I want to** set permissions **so that** I control who can edit | - Roles: owner, editor, viewer<br>- RBAC guards<br>- Viewer can't edit | 3 | P1 |
| COLLAB-6 | **As a** collaborator, **I want to** accept invite **so that** I can join project | - GET /invites/:token<br>- Auto-add to collaborators<br>- Redirect to board | 2 | P1 |
| YJS-1 | **As a** developer, **I want to** Y-WebSocket server deployed **so that** real-time works | - WebSocket server setup<br>- Redis pub/sub for multi-instance<br>- Persistence snapshots | 8 | P0 |

**Total**: 36 SP

---

### Sprint 4: Token System & Billing (Week 9-10)
**Goal**: Monetization ready with Stripe

| Story ID | User Story | Acceptance Criteria | Story Points | Priority |
|----------|-----------|---------------------|--------------|----------|
| TOKEN-1 | **As a** user, **I want to** see my token balance **so that** I know how many I have | - Display in nav bar<br>- GET /tokens/balance<br>- Real-time update on use | 2 | P0 |
| TOKEN-2 | **As a** user, **I want to** view transaction history **so that** I can track usage | - GET /tokens/transactions<br>- Show date, type, amount<br>- Filter by type | 3 | P1 |
| TOKEN-3 | **As a** developer, **I want to** token deduction to be ACID **so that** no double-spend | - Reserve tokens (PENDING tx)<br>- Complete on success<br>- Refund on failure<br>- Idempotency key | 8 | P0 |
| TOKEN-4 | **As a** user, **I want to** purchase tokens **so that** I can use AI features | - Stripe Checkout session<br>- Packages: 100, 500, 2000 tokens<br>- Webhook handler | 5 | P0 |
| TOKEN-5 | **As a** user, **I want to** subscribe monthly **so that** I get recurring tokens | - Stripe Subscriptions<br>- Plans: Free (0), Pro (1000/mo), Business (5000/mo)<br>- Auto-renew | 5 | P0 |
| BILL-1 | **As a** user, **I want to** manage my billing **so that** I can update payment method | - Stripe Customer Portal<br>- Update card, cancel subscription<br>- View invoices | 3 | P1 |
| BILL-2 | **As a** user, **I want to** receive email receipts **so that** I have proof of purchase | - Stripe webhook: invoice.paid<br>- Send email with invoice PDF | 2 | P2 |

**Total**: 28 SP

---

### Sprint 5: AI Agent MVP (Week 11-12)
**Goal**: AI generates assets (mock first, real API later)

| Story ID | User Story | Acceptance Criteria | Story Points | Priority |
|----------|-----------|---------------------|--------------|----------|
| AI-1 | **As a** user, **I want to** request AI asset generation **so that** I can create quickly | - Prompt input UI<br>- POST /agent/plan endpoint<br>- Show estimated tokens | 3 | P0 |
| AI-2 | **As a** user, **I want to** know estimated cost **so that** I can decide before spending tokens | - Classifier determines tool<br>- Estimator returns token cost<br>- Confirm/cancel modal | 5 | P0 |
| AI-3 | **As a** user, **I want to** AI job to run async **so that** UI doesn't freeze | - BullMQ job queue<br>- POST /assets/generate (202 Accepted)<br>- Return job ID | 5 | P0 |
| AI-4 | **As a** user, **I want to** see job progress **so that** I know it's working | - GET /assets/jobs/:id<br>- Progress 0-100%<br>- Status: pending, processing, completed, failed | 3 | P0 |
| AI-5 | **As a** user, **I want to** generated asset to appear on board **so that** I can use it immediately | - WebSocket event on completion<br>- Auto-place asset on board<br>- Notification toast | 5 | P0 |
| AI-6 | **As a** developer, **I want to** implement logo generator **so that** users can create logos | - Planner classifies "logo" intent<br>- Selector picks logo-generator<br>- Executor calls Stability AI/mock<br>- Upload result to S3 | 8 | P0 |
| AI-7 | **As a** developer, **I want to** implement social post generator **so that** users can create posts | - Planner classifies "social" intent<br>- Generate image + caption<br>- Return both assets | 5 | P1 |
| AI-8 | **As a** developer, **I want to** implement copywriter **so that** users can generate text | - Anthropic Claude API<br>- Return text asset<br>- Lower token cost | 3 | P1 |

**Total**: 37 SP

---

### Sprint 6: Assets & Library (Week 13-14)
**Goal**: Asset management & organization

| Story ID | User Story | Acceptance Criteria | Story Points | Priority |
|----------|-----------|---------------------|--------------|----------|
| ASSET-1 | **As a** user, **I want to** browse my assets **so that** I can reuse them | - Asset library panel<br>- Grid view with thumbnails<br>- Filter by type, project | 5 | P0 |
| ASSET-2 | **As a** user, **I want to** drag asset from library to board **so that** I can place it easily | - Drag from library<br>- Drop on canvas<br>- Create new instance | 3 | P1 |
| ASSET-3 | **As a** user, **I want to** delete assets **so that** I can remove unwanted ones | - DELETE /assets/:id<br>- Soft delete<br>- Remove from S3 (async) | 2 | P2 |
| ASSET-4 | **As a** user, **I want to** download assets **so that** I can use them elsewhere | - Download button<br>- Original quality<br>- Signed S3 URL | 2 | P1 |
| ASSET-5 | **As a** user, **I want to** export board as image **so that** I can share my work | - Export canvas to PNG/JPEG<br>- High resolution option<br>- Download file | 5 | P1 |
| LAYER-1 | **As a** user, **I want to** see layers panel **so that** I can manage object order | - Layer list (z-index order)<br>- Show/hide layers<br>- Lock layers | 5 | P1 |
| LAYER-2 | **As a** user, **I want to** reorder layers **so that** I can change stacking | - Drag layer in list<br>- Update z-index<br>- Sync via Yjs | 3 | P2 |

**Total**: 25 SP

---

### Sprint 7-8: Production Hardening (Week 15-18)
**Goal**: Production-ready deployment

| Story ID | User Story | Acceptance Criteria | Story Points | Priority |
|----------|-----------|---------------------|--------------|----------|
| OPS-1 | **As a** developer, **I want to** deploy to staging **so that** I can test in prod-like env | - Kubernetes cluster setup<br>- Staging namespace<br>- Auto-deploy on PR merge to `staging` | 8 | P0 |
| OPS-2 | **As a** developer, **I want to** monitoring dashboards **so that** I can see app health | - Prometheus metrics<br>- Grafana dashboards<br>- Key metrics: latency, errors, queue depth | 5 | P0 |
| OPS-3 | **As a** developer, **I want to** alerting **so that** I'm notified of issues | - Alert rules (latency > 1s, error rate > 1%)<br>- Slack notifications<br>- PagerDuty (optional) | 3 | P1 |
| OPS-4 | **As a** developer, **I want to** centralized logging **so that** I can debug issues | - Structured JSON logs<br>- ELK stack or Datadog<br>- Searchable by user, request ID | 5 | P1 |
| OPS-5 | **As a** developer, **I want to** error tracking **so that** I catch bugs in prod | - Sentry integration<br>- Source maps<br>- Grouping & alerts | 3 | P0 |
| OPS-6 | **As a** developer, **I want to** secrets management **so that** API keys are secure | - Vault or AWS Secrets Manager<br>- Auto-rotate secrets<br>- No secrets in Git | 5 | P0 |
| OPS-7 | **As a** developer, **I want to** CI/CD **so that** deployments are automated | - GitHub Actions<br>- Lint, test, build, deploy<br>- Manual approval for prod | 5 | P0 |
| OPS-8 | **As a** developer, **I want to** load testing **so that** I know app can scale | - k6 scripts<br>- Test 100 concurrent users<br>- P95 latency < 500ms | 3 | P1 |
| SEC-1 | **As a** developer, **I want to** security audit **so that** vulnerabilities are fixed | - OWASP top 10 check<br>- Dependency scan (Snyk)<br>- Penetration test | 8 | P0 |
| PERF-1 | **As a** user, **I want to** fast page loads **so that** I have good UX | - Lighthouse score > 90<br>- Code splitting<br>- Image optimization | 5 | P1 |
| PERF-2 | **As a** user, **I want to** responsive mobile UI **so that** I can use on phone | - Mobile-first CSS<br>- Touch gestures<br>- Responsive canvas | 8 | P1 |

**Total**: 58 SP (spread over 2 sprints)

---

## v1.0 Release Checklist

### Features
- [x] User authentication (email + OAuth2)
- [x] Projects CRUD
- [x] Whiteboard (upload, move, resize, rotate)
- [x] Real-time collaboration (Yjs)
- [x] Token system with ACID transactions
- [x] Stripe billing (purchases + subscriptions)
- [x] AI asset generation (logo, social post, copy)
- [x] Asset library
- [x] Collaborator invites & permissions

### Quality
- [ ] Test coverage > 80%
- [ ] E2E tests for critical flows
- [ ] Load testing (100+ concurrent users)
- [ ] Security audit passed
- [ ] Lighthouse score > 90

### Operations
- [ ] Deployed to production
- [ ] Monitoring & alerting configured
- [ ] Backup & disaster recovery plan
- [ ] Runbook for on-call
- [ ] Incident response plan

### Documentation
- [ ] API documentation (Swagger)
- [ ] User guides
- [ ] Developer onboarding
- [ ] Architecture diagrams
- [ ] Security policy

---

## v1.5 Features (Q3 2025)

### Brand Library
| Story ID | Feature | Description | Story Points |
|----------|---------|-------------|--------------|
| BRAND-1 | Save brand colors | User can save palette to library | 3 |
| BRAND-2 | Save brand fonts | User can save font stack | 2 |
| BRAND-3 | Brand guidelines | User can write tone, voice, rules | 5 |
| BRAND-4 | Auto-apply brand | AI uses brand settings automatically | 5 |

### Templates
| Story ID | Feature | Description | Story Points |
|----------|---------|-------------|--------------|
| TMPL-1 | Template marketplace | Browse & purchase templates | 8 |
| TMPL-2 | Create template from board | Save board as reusable template | 5 |
| TMPL-3 | Apply template | Load template into new project | 3 |

### Integrations
| Story ID | Feature | Description | Story Points |
|----------|---------|-------------|--------------|
| INT-1 | Figma import | Import Figma frames to board | 13 |
| INT-2 | Canva export | Export board to Canva | 8 |
| INT-3 | Zapier webhook | Trigger actions from Pixora events | 5 |

### Advanced AI
| Story ID | Feature | Description | Story Points |
|----------|---------|-------------|--------------|
| AI-ADV-1 | Video mockups | Generate animated mockups | 13 |
| AI-ADV-2 | Fine-tuned models | Train on user's brand style | 21 |
| AI-ADV-3 | Batch generation | Generate 10+ variants at once | 8 |

### Security
| Story ID | Feature | Description | Story Points |
|----------|---------|-------------|--------------|
| SEC-2 | MFA (2FA) | TOTP authentication | 5 |
| SEC-3 | Session management | View/revoke active sessions | 3 |

**Total v1.5**: ~107 SP (~7-8 sprints)

---

## Enterprise Features (Q4 2025)

| Story ID | Feature | Description | Story Points |
|----------|---------|-------------|--------------|
| ENT-1 | SSO SAML | Enterprise single sign-on | 13 |
| ENT-2 | Advanced audit logs | Track all actions with retention | 8 |
| ENT-3 | Custom domain | White-label on custom domain | 8 |
| ENT-4 | On-premise deployment | Self-hosted option | 21 |
| ENT-5 | SLA 99.9% | Uptime guarantees | 13 |
| ENT-6 | Dedicated support | Slack channel, priority tickets | 5 |
| ENT-7 | Custom contracts | Legal, compliance, security | 3 |
| ENT-8 | Role-based access (RBAC) | Fine-grained permissions | 13 |
| ENT-9 | Data residency | Choose data center region | 8 |
| ENT-10 | Volume discounts | Custom token packages | 3 |

**Total Enterprise**: ~95 SP (~6 sprints)

---

## Story Point Reference (Fibonacci)

| Points | Complexity | Time | Example |
|--------|-----------|------|---------|
| **1** | Trivial | 1-2h | Add a simple GET endpoint, update copy |
| **2** | Simple | 2-4h | Create DTO, add validation, simple UI component |
| **3** | Medium | 4-8h | CRUD endpoint with DB, form with validation |
| **5** | Complex | 1-2 days | Module with controller + service + tests, complex UI feature |
| **8** | Very Complex | 2-3 days | Authentication flow, real-time sync, integration |
| **13** | Epic-level | 3-5 days | Entire feature area, external integration, performance optimization |
| **21** | Too large | 1-2 weeks | Should be broken down into smaller stories |

---

## Velocity Tracking

| Sprint | Planned SP | Completed SP | Velocity | Notes |
|--------|-----------|--------------|----------|-------|
| Sprint 0 | 17 | 17 | 17 | Infrastructure setup |
| Sprint 1 | 22 | - | - | Auth & Users |
| Sprint 2 | 31 | - | - | Projects & Whiteboard |
| Sprint 3 | 36 | - | - | Real-time |
| Sprint 4 | 28 | - | - | Billing |
| Sprint 5 | 37 | - | - | AI MVP |
| Sprint 6 | 25 | - | - | Assets |
| Sprint 7-8 | 58 | - | - | Production |

**Average Velocity**: TBD (target: 25-30 SP/sprint for 2 devs)

---

## Risk Register

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **AI API costs exceed budget** | High | Medium | - Implement aggressive caching<br>- Token limits per user<br>- Monitor usage closely |
| **Real-time sync conflicts** | Medium | Low | - Yjs CRDT handles automatically<br>- Thorough testing<br>- Fallback to manual refresh |
| **Stripe integration issues** | High | Low | - Use test mode extensively<br>- Follow Stripe best practices<br>- Idempotent webhooks |
| **Database performance** | Medium | Medium | - Proper indexing<br>- Read replicas<br>- Query optimization |
| **Security vulnerability** | High | Medium | - Regular audits<br>- Dependency scanning<br>- Penetration testing |

---

## Success Metrics (KPIs)

| Metric | Target (MVP) | Target (v1.0) | Target (v1.5) |
|--------|--------------|---------------|---------------|
| **MAU** (Monthly Active Users) | 100 | 1,000 | 10,000 |
| **Retention (D7)** | 30% | 50% | 60% |
| **Conversion (Free → Paid)** | 5% | 10% | 15% |
| **ARPU** (Average Revenue Per User) | $10 | $20 | $30 |
| **P95 Latency** | < 1s | < 500ms | < 300ms |
| **Uptime** | 99% | 99.5% | 99.9% |
| **AI Success Rate** | 80% | 90% | 95% |
| **Customer Satisfaction (NPS)** | 30 | 50 | 60 |

---

**Questions? See [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md) for technical details.**
