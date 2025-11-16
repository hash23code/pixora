# Pixora - Architecture Documentation

## Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Structure de Dossiers](#structure-de-dossiers)
3. [Layers & Responsabilités](#layers--responsabilités)
4. [Data Flow](#data-flow)
5. [Real-time Collaboration](#real-time-collaboration)
6. [AI Agent Architecture](#ai-agent-architecture)
7. [Security & Authentication](#security--authentication)
8. [Scaling Strategy](#scaling-strategy)

---

## Vue d'ensemble

Pixora est une plateforme SaaS modulaire construite avec:
- **Frontend**: Next.js 14 (App Router) + React + TypeScript
- **Backend**: NestJS + TypeScript
- **Real-time**: Yjs CRDT + WebSocket
- **AI**: Microservice avec BullMQ job queue
- **Database**: PostgreSQL 15+
- **Cache/Queue**: Redis
- **Storage**: S3-compatible

### Principes d'Architecture

1. **Separation of Concerns**: Chaque service a une responsabilité unique
2. **Scalability**: Services stateless, horizontal scaling
3. **Resilience**: Retries, circuit breakers, graceful degradation
4. **Observability**: Logs structurés, metrics, tracing
5. **Security-first**: Auth à tous les layers, validation, rate limiting

---

## Structure de Dossiers

```
pixora/
│
├── backend/                          # NestJS API Backend
│   ├── src/
│   │   ├── modules/                  # Feature modules
│   │   │   ├── auth/                 # Authentication & Authorization
│   │   │   │   ├── auth.controller.ts
│   │   │   │   ├── auth.service.ts
│   │   │   │   ├── auth.module.ts
│   │   │   │   ├── strategies/       # Passport strategies (JWT, OAuth2)
│   │   │   │   ├── dto/              # Data Transfer Objects
│   │   │   │   └── guards/           # Auth guards
│   │   │   │
│   │   │   ├── users/                # User management
│   │   │   ├── projects/             # Projects CRUD
│   │   │   ├── boards/               # Whiteboard state persistence
│   │   │   ├── assets/               # Asset upload & management
│   │   │   ├── tokens/               # Token balance & transactions
│   │   │   ├── billing/              # Stripe integration
│   │   │   ├── collaborators/        # Sharing & permissions
│   │   │   └── agent/                # AI tool-router coordinator
│   │   │
│   │   ├── common/                   # Shared utilities
│   │   │   ├── guards/               # Global guards (RBAC, throttle)
│   │   │   ├── decorators/           # Custom decorators
│   │   │   ├── interceptors/         # Logging, transform, cache
│   │   │   ├── filters/              # Exception filters
│   │   │   └── pipes/                # Validation pipes
│   │   │
│   │   ├── database/                 # Database related
│   │   │   ├── migrations/           # TypeORM migrations
│   │   │   ├── seeds/                # Seed scripts
│   │   │   └── entities/             # TypeORM entities (si utilisées)
│   │   │
│   │   ├── config/                   # Configuration
│   │   │   ├── database.config.ts
│   │   │   ├── redis.config.ts
│   │   │   ├── s3.config.ts
│   │   │   └── app.config.ts
│   │   │
│   │   └── main.ts                   # Application entry point
│   │
│   ├── test/                         # E2E tests
│   │   ├── auth.e2e-spec.ts
│   │   ├── projects.e2e-spec.ts
│   │   └── ...
│   │
│   ├── Dockerfile
│   ├── package.json
│   ├── tsconfig.json
│   ├── nest-cli.json
│   └── .env.example
│
├── frontend/                         # Next.js Frontend
│   ├── app/                          # App Router
│   │   ├── layout.tsx                # Root layout
│   │   ├── page.tsx                  # Landing page
│   │   │
│   │   ├── (auth)/                   # Auth route group
│   │   │   ├── login/
│   │   │   │   └── page.tsx
│   │   │   ├── signup/
│   │   │   │   └── page.tsx
│   │   │   └── layout.tsx
│   │   │
│   │   ├── (dashboard)/              # Protected routes
│   │   │   ├── layout.tsx            # Dashboard layout (sidebar, nav)
│   │   │   ├── projects/
│   │   │   │   ├── page.tsx          # Projects list
│   │   │   │   └── [id]/
│   │   │   │       └── page.tsx      # Project details
│   │   │   ├── board/
│   │   │   │   └── [id]/
│   │   │   │       └── page.tsx      # Whiteboard canvas
│   │   │   ├── settings/
│   │   │   │   └── page.tsx
│   │   │   └── billing/
│   │   │       └── page.tsx
│   │   │
│   │   └── api/                      # API routes (BFF pattern si besoin)
│   │       └── webhooks/
│   │
│   ├── components/                   # React components
│   │   ├── whiteboard/
│   │   │   ├── Whiteboard.tsx        # Main canvas component
│   │   │   ├── Toolbar.tsx           # Tools (select, draw, text, etc.)
│   │   │   ├── LayerPanel.tsx        # Layer management
│   │   │   ├── AssetLibrary.tsx      # Asset browser
│   │   │   ├── PropertiesPanel.tsx   # Object properties
│   │   │   └── CollaboratorCursors.tsx
│   │   │
│   │   ├── ui/                       # shadcn/ui components
│   │   │   ├── button.tsx
│   │   │   ├── dialog.tsx
│   │   │   ├── input.tsx
│   │   │   └── ...
│   │   │
│   │   └── shared/                   # Shared components
│   │       ├── Header.tsx
│   │       ├── Sidebar.tsx
│   │       └── TokenMeter.tsx
│   │
│   ├── hooks/                        # Custom React hooks
│   │   ├── useYjs.ts                 # Yjs collaboration
│   │   ├── useTokens.ts              # Token balance
│   │   ├── useProjects.ts            # Projects fetching
│   │   ├── useAuth.ts                # Auth state
│   │   └── useWebSocket.ts
│   │
│   ├── lib/                          # Utilities
│   │   ├── api.ts                    # API client (axios/fetch wrapper)
│   │   ├── yjs.ts                    # Yjs setup & providers
│   │   ├── utils.ts                  # Helpers
│   │   └── constants.ts
│   │
│   ├── types/                        # TypeScript types
│   │   ├── api.ts
│   │   └── whiteboard.ts
│   │
│   ├── styles/
│   │   └── globals.css
│   │
│   ├── Dockerfile
│   ├── package.json
│   ├── tsconfig.json
│   ├── next.config.js
│   ├── tailwind.config.js
│   └── .env.example
│
├── y-websocket-server/               # Real-time WebSocket server
│   ├── src/
│   │   ├── index.ts                  # Server entry point
│   │   ├── awareness.ts              # Yjs awareness (cursors, presence)
│   │   └── persistence.ts            # Optional: persist Yjs to DB
│   ├── Dockerfile
│   ├── package.json
│   └── tsconfig.json
│
├── ai-service/                       # AI Agent Microservice
│   ├── src/
│   │   ├── index.ts                  # Service entry point
│   │   ├── planner.ts                # Intent classification
│   │   ├── selector.ts               # Tool selection logic
│   │   ├── estimator.ts              # Token cost estimation
│   │   │
│   │   ├── executors/                # Tool executors
│   │   │   ├── base.executor.ts
│   │   │   ├── logo-generator.executor.ts
│   │   │   ├── social-post.executor.ts
│   │   │   ├── copywriter.executor.ts
│   │   │   └── mockup-generator.executor.ts
│   │   │
│   │   ├── workers/                  # BullMQ workers
│   │   │   ├── ai-job.worker.ts
│   │   │   └── postprocessor.worker.ts
│   │   │
│   │   ├── prompts/                  # AI prompts templates
│   │   │   └── logo-generator.prompt.ts
│   │   │
│   │   └── utils/
│   │       ├── api-clients.ts        # Anthropic, Stability, Replicate clients
│   │       └── image-processing.ts
│   │
│   ├── Dockerfile
│   ├── package.json
│   └── tsconfig.json
│
├── infra/                            # Infrastructure as Code
│   ├── k8s/                          # Kubernetes manifests
│   │   ├── namespace.yaml
│   │   ├── deployments/
│   │   │   ├── backend.deployment.yaml
│   │   │   ├── frontend.deployment.yaml
│   │   │   ├── y-websocket.deployment.yaml
│   │   │   └── ai-service.deployment.yaml
│   │   ├── services/
│   │   │   ├── backend.service.yaml
│   │   │   └── ...
│   │   ├── ingress/
│   │   │   └── ingress.yaml
│   │   ├── configmaps/
│   │   └── secrets/
│   │       └── .gitkeep
│   │
│   ├── helm/                         # Helm charts
│   │   └── pixora/
│   │       ├── Chart.yaml
│   │       ├── values.yaml
│   │       ├── values.prod.yaml
│   │       └── templates/
│   │
│   └── terraform/                    # Terraform (optional)
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── .github/
│   └── workflows/
│       ├── ci.yml                    # Lint, test, build
│       ├── deploy-staging.yml
│       └── deploy-prod.yml
│
├── docs/                             # Documentation
│   ├── API.md
│   ├── DATABASE.md
│   ├── WHITEBOARD.md
│   ├── AI_AGENT.md
│   ├── DEPLOYMENT.md
│   └── SECURITY.md
│
├── docker-compose.yml                # Local dev environment
├── docker-compose.test.yml           # Test environment
├── docker-compose.prod.yml           # Production (référence)
│
├── Makefile                          # Dev commands
├── package.json                      # Root workspace
├── .env.example
├── .gitignore
├── .prettierrc
├── .eslintrc.json
├── README.md
└── ARCHITECTURE.md                   # Ce fichier
```

---

## Layers & Responsabilités

### 1. Presentation Layer (Frontend)
- **Technologie**: Next.js, React, TailwindCSS
- **Responsabilités**:
  - Rendering UI
  - User interactions
  - Client-side validation
  - State management (Zustand ou React Context)
  - Real-time CRDT sync (Yjs provider)
  - API calls via REST/WebSocket

### 2. API Layer (Backend)
- **Technologie**: NestJS
- **Responsabilités**:
  - REST API endpoints
  - Authentication & Authorization (JWT, OAuth2)
  - Business logic
  - Server-side validation
  - Database operations
  - Integration avec external services (Stripe, AI)
  - Rate limiting, caching

### 3. Real-time Layer (Y-WebSocket Server)
- **Technologie**: Node.js + Yjs + WebSocket
- **Responsabilités**:
  - Real-time collaboration sync
  - CRDT conflict resolution
  - Awareness (cursors, selections)
  - Persister snapshots à intervalles (optionnel)

### 4. AI Agent Layer (AI Service)
- **Technologie**: Node.js + BullMQ
- **Responsabilités**:
  - Intent classification (planner)
  - Tool selection (selector)
  - Cost estimation (estimator)
  - Async job execution (workers)
  - Calling external AI APIs
  - Postprocessing results (thumbnails, metadata)

### 5. Data Layer
- **PostgreSQL**: Source of truth pour structured data
- **Redis**: Cache, sessions, job queue, pub/sub
- **S3**: Binary assets (images, SVG, videos)

---

## Data Flow

### User Creates Asset via AI

```
┌─────────┐      ┌─────────┐      ┌─────────┐      ┌─────────┐      ┌─────────┐
│ User    │─(1)─>│ Frontend│─(2)─>│ Backend │─(3)─>│ Tokens  │      │   AI    │
│         │      │         │      │   API   │      │ Service │      │ Service │
└─────────┘      └─────────┘      └─────────┘      └─────────┘      └─────────┘
                       │                │                │                │
                       │                │                │                │
                       │            (4) Reserve         (5) Deduct        │
                       │                │ Tokens         │ Tokens         │
                       │                │                │                │
                       │                ├───────────────>│                │
                       │                │                │                │
                       │                │<───────────────┤                │
                       │                │   (6) Confirmed                 │
                       │                │                                 │
                       │                ├─(7) Enqueue Job────────────────>│
                       │                │                                 │
                       │<───(8) Job ID──┤                                 │
                       │                                                  │
         ┌─────────────┴────────────┐                                    │
         │  (9) Poll job status     │                                    │
         │      OR WebSocket event  │                                    │
         └─────────────┬────────────┘                                    │
                       │                                           (10) Process
                       │                                                  │
                       │<────────────────────────(11) Callback────────────┤
                       │                    (result asset URL)
                       │
                  (12) Display asset on whiteboard
```

**Étapes**:
1. User entre un prompt ("Créer un logo...")
2. Frontend POST `/agent/plan` pour estimation
3. Backend vérifie tokens balance
4. Si suffisant, réserve tokens (transaction PENDING)
5. Tokens déductés (transaction COMPLETED)
6. Backend enqueue job dans BullMQ
7. Job ID retourné immédiatement (202 Accepted)
8. Frontend poll `/assets/jobs/{jobId}` OU écoute WebSocket event
9. AI Service worker traite le job (appel API externe)
10. Résultat uploadé sur S3, asset créé en DB
11. Callback webhook `/webhook/ai-callback` notifie le backend
12. Frontend reçoit asset et l'affiche sur le board

---

## Real-time Collaboration

### Architecture Yjs

```
┌─────────────────────────────────────────────────────────────┐
│                        Y-WebSocket Server                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Yjs Document (Y.Doc)                                 │  │
│  │  - Shared state (canvas objects, sticky notes, etc.)  │  │
│  │  - CRDT operations log                                │  │
│  └───────────────────────────────────────────────────────┘  │
│                           │                                  │
│         ┌─────────────────┼─────────────────┐                │
│         │                 │                 │                │
│    ┌────▼────┐      ┌─────▼─────┐    ┌─────▼─────┐          │
│    │ Client  │      │  Client   │    │  Client   │          │
│    │   A     │      │     B     │    │     C     │          │
│    └─────────┘      └───────────┘    └───────────┘          │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ Periodic Snapshot (optional)
                           ▼
                    ┌─────────────┐
                    │ PostgreSQL  │
                    │ (boards)    │
                    └─────────────┘
```

### Conflict Resolution
- **CRDT (Yjs)** résout automatiquement les conflits
- **Eventual consistency** garantie
- **Offline support**: les modifications sont bufferisées et syncées à la reconnexion

### Awareness (Cursors, Selections)
- Yjs Awareness protocol pour présence temps-réel
- Broadcast via WebSocket (pas persisté)
- Affichage couleurs/nom de chaque utilisateur

---

## AI Agent Architecture

### Tool Router Flow

```
┌──────────────────────────────────────────────────────────────┐
│                       User Prompt                            │
│   "Je veux un logo moderne pour une startup fintech"        │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
                  ┌──────────────┐
                  │   Planner    │ (Intent Classification)
                  │ - NLP / LLM  │
                  └──────┬───────┘
                         │
                         ▼
                  ┌──────────────┐
                  │   Selector   │ (Tool Selection)
                  │ - Rules /    │
                  │   Classifier │
                  └──────┬───────┘
                         │
                         ▼
                  ┌──────────────┐
                  │  Estimator   │ (Token Cost)
                  │ - Fixed or   │
                  │   Model-based│
                  └──────┬───────┘
                         │
                         ▼
           ┌─────────────────────────────┐
           │  Selected Tool: Logo Gen    │
           │  Estimated Tokens: 150      │
           │  Parameters: {              │
           │    style: "modern",         │
           │    industry: "fintech"      │
           │  }                          │
           └─────────────┬───────────────┘
                         │
                         ▼
                  ┌──────────────┐
                  │   Executor   │ (API Call)
                  │ - Stability  │
                  │ - Replicate  │
                  │ - Custom     │
                  └──────┬───────┘
                         │
                         ▼
                  ┌──────────────┐
                  │Postprocessor │
                  │ - Thumbnail  │
                  │ - Metadata   │
                  │ - Upload S3  │
                  └──────┬───────┘
                         │
                         ▼
                  ┌──────────────┐
                  │    Result    │
                  │ Asset URL    │
                  └──────────────┘
```

### Tools Disponibles (MVP)

1. **Logo Generator**
   - API: Stability AI / DALL-E
   - Output: PNG/SVG
   - Coût: 100-200 tokens

2. **Social Post Generator**
   - API: Anthropic Claude + Image gen
   - Output: Image + copy
   - Coût: 150-300 tokens

3. **Copywriter**
   - API: Anthropic Claude
   - Output: Text
   - Coût: 50-100 tokens

4. **Mockup Generator**
   - API: Custom pipeline (template + AI)
   - Output: PNG/JPEG
   - Coût: 200-400 tokens

5. **Image Upscaler**
   - API: Replicate (ESRGAN)
   - Output: PNG
   - Coût: 100 tokens

---

## Security & Authentication

### Authentication Flow (JWT + OAuth2)

```
┌──────────────────────────────────────────────────────────────┐
│                    1. User Signup/Login                      │
└────────────────────────┬─────────────────────────────────────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
         ▼                               ▼
  ┌──────────────┐              ┌──────────────┐
  │   Email +    │              │    OAuth2    │
  │   Password   │              │ (Google, etc)│
  └──────┬───────┘              └──────┬───────┘
         │                               │
         └───────────────┬───────────────┘
                         │
                         ▼
                  ┌──────────────┐
                  │   Backend    │
                  │   Validates  │
                  └──────┬───────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  JWT Access Token    │ (7d)
              │  JWT Refresh Token   │ (30d)
              └──────┬───────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │  Store in httpOnly   │
              │  cookies (or client) │
              └──────────────────────┘
```

### Authorization (RBAC)

**Rôles**:
- `user`: Utilisateur standard
- `admin`: Administrateur plateforme

**Project Permissions**:
- `owner`: Créateur du projet (all permissions)
- `editor`: Peut éditer le board, créer assets
- `viewer`: Read-only

**Guards**:
- `JwtAuthGuard`: Vérifie JWT valid
- `RolesGuard`: Vérifie rôle global (admin)
- `ProjectPermissionGuard`: Vérifie permissions projet (owner/editor/viewer)

### Security Checklist

- [x] Input validation (class-validator)
- [x] Rate limiting (Throttler)
- [x] CORS strict
- [x] Helmet.js headers
- [x] SQL injection prevention (Prisma/TypeORM)
- [x] XSS sanitization
- [x] CSRF tokens (forms critiques)
- [x] JWT rotation
- [x] Secrets management (env vars, Vault en prod)
- [x] HTTPS only (production)
- [ ] MFA (roadmap v1.5)
- [ ] Audit logs (roadmap Enterprise)

---

## Scaling Strategy

### Horizontal Scaling

**Stateless Services**:
- Backend API: Scale via Kubernetes HPA (CPU/memory)
- Y-WebSocket: Multiple instances + Redis pub/sub pour sync
- AI Service workers: Scale workers selon queue depth

**Stateful Services**:
- PostgreSQL: Read replicas (pgpool-II)
- Redis: Cluster mode pour HA

### Performance Optimizations

1. **Caching**:
   - Redis pour API responses (users, projects)
   - CDN pour assets statiques (CloudFront)
   - Browser caching (immutable assets)

2. **Database**:
   - Indexes sur foreign keys, queries fréquentes
   - Pagination cursor-based (pas offset)
   - Connection pooling

3. **Frontend**:
   - Code splitting (Next.js automatic)
   - Image optimization (next/image)
   - Lazy loading components
   - SWR/React Query cache

4. **AI Jobs**:
   - Priority queue (urgent vs batch)
   - Rate limiting external APIs
   - Retry avec exponential backoff

### Monitoring & Alerting

**Metrics** (Prometheus):
- Request latency (p50, p95, p99)
- Throughput (req/s)
- Error rate
- Queue depth
- Database connections
- Cache hit ratio

**Alerts**:
- Latency > 1s (p95)
- Error rate > 1%
- Queue depth > 1000
- DB connections > 80%
- Disk usage > 85%

**Dashboards** (Grafana):
- API Overview
- Real-time Connections
- AI Jobs Status
- Token Economy
- User Activity

---

## Next Steps

1. **MVP Phase**: Implement core features (auth, projects, whiteboard, basic AI)
2. **v1.0**: Real-time collaboration, full AI tools, production-ready
3. **v1.5**: Advanced features (templates, integrations, MFA)
4. **Enterprise**: SSO SAML, audit logs, on-premise

**Questions? Consulter `/docs` ou contacter l'équipe tech.**
