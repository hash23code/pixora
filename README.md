# Pixora - AI-Powered Marketing Asset Creation Platform

> **Plateforme SaaS** permettant aux PME, agences marketing et startups de créer rapidement une image de marque et des assets marketing (logo, carte d'affaires, posts réseaux sociaux, mockups web, bannières pub).

---

## 🎯 Vision Produit

**Whiteboard collaboratif** (Miro-like) où toutes les créations apparaissent visuellement avec des **agents AI** qui génèrent automatiquement les assets selon vos besoins.

### Fonctionnalités Clés

- 🎨 **Whiteboard collaboratif temps-réel** (drag/drop, resize, layers, sticky notes)
- 🤖 **AI Tool Router** qui sélectionne automatiquement l'outil approprié (logo, social post, copywriter, mockup)
- 💳 **Système de tokens** (packs, abonnements, crédits)
- 👥 **Collaboration multi-utilisateur** (viewer/editor/owner permissions)
- 🔄 **Real-time CRDT sync** (Yjs) — édition simultanée sans conflits
- 📦 **Export assets** (SVG, PNG, JPEG, WebP)

---

## 🏗️ Architecture Technique

### Stack

| Layer | Technologies |
|-------|-------------|
| **Frontend** | Next.js 14 (App Router), TypeScript, React, SWR, shadcn/ui, React Konva |
| **Backend** | NestJS, TypeScript, Passport.js (OAuth2/JWT) |
| **Real-time** | Yjs, y-websocket, Redis Pub/Sub |
| **Database** | PostgreSQL 15+, Prisma ORM |
| **Storage** | S3-compatible (AWS S3 / DigitalOcean Spaces / Minio) |
| **Queue** | BullMQ (Redis-backed) |
| **AI** | Anthropic Claude, Stability AI, Replicate |
| **Payments** | Stripe (Billing, Subscriptions, Webhooks) |
| **Monitoring** | Sentry, Prometheus, Grafana |
| **DevOps** | Docker, Docker Compose, Kubernetes (prod), Helm |
| **CI/CD** | GitHub Actions |

### Services Architecture

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Next.js   │─────▶│  NestJS API │─────▶│ PostgreSQL  │
│  (Frontend) │      │  (Backend)  │      │   (Data)    │
└─────────────┘      └─────────────┘      └─────────────┘
       │                    │                     │
       │                    ▼                     │
       │             ┌─────────────┐              │
       │             │    Redis    │              │
       │             │ (Cache/Jobs)│              │
       │             └─────────────┘              │
       │                    │                     │
       ▼                    ▼                     ▼
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│ Y-WebSocket │      │ AI Agent    │      │     S3      │
│   Server    │      │  Service    │      │  (Assets)   │
└─────────────┘      └─────────────┘      └─────────────┘
```

---

## 🚀 Quick Start (Développement Local)

### Prérequis

- **Node.js** 20+ et **npm** 9+
- **Docker** & **Docker Compose**
- **Git**
- **Make** (optionnel, facilite les commandes)

### Installation

```bash
# 1. Cloner le repo
git clone https://github.com/your-org/pixora.git
cd pixora

# 2. Copier les fichiers d'environnement
cp .env.example .env
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env

# 3. Éditer les variables d'environnement (voir section Config)
nano .env

# 4. Démarrer les services (PostgreSQL, Redis, Minio, Backend, Frontend)
make dev
# OU
docker-compose up -d

# 5. Installer les dépendances
make install
# OU
npm install --workspaces

# 6. Exécuter les migrations DB
make migrate
# OU
cd backend && npm run migration:run

# 7. Seed la base de données (données de test)
make seed

# 8. Ouvrir l'app
# Frontend: http://localhost:3000
# Backend API: http://localhost:4000
# API Docs (Swagger): http://localhost:4000/api
# Minio Console: http://localhost:9001 (minioadmin / minioadmin)
```

### Commandes Make Disponibles

```bash
make dev          # Démarre tous les services en mode développement
make stop         # Arrête tous les services
make clean        # Supprime volumes et images Docker
make install      # Installe les dépendances npm
make migrate      # Exécute migrations DB
make seed         # Seed la DB avec données de test
make test         # Lance tous les tests (unit + e2e)
make lint         # Lint le code (ESLint)
make format       # Formate le code (Prettier)
make build        # Build production (backend + frontend)
make logs         # Affiche les logs de tous les services
```

---

## ⚙️ Configuration (.env)

### Backend (`backend/.env`)

```bash
# App
NODE_ENV=development
PORT=4000
API_PREFIX=/api

# Database
DATABASE_URL=postgresql://pixora:pixora@localhost:5432/pixora
DATABASE_SSL=false

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-me
JWT_EXPIRES_IN=7d
JWT_REFRESH_EXPIRES_IN=30d

# OAuth2 (Google example)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_CALLBACK_URL=http://localhost:4000/api/auth/google/callback

# S3 Storage
S3_ENDPOINT=http://localhost:9000
S3_BUCKET=pixora-assets
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin
S3_REGION=us-east-1
S3_PUBLIC_URL=http://localhost:9000/pixora-assets

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PUBLISHABLE_KEY=pk_test_...

# AI Services
ANTHROPIC_API_KEY=sk-ant-...
STABILITY_API_KEY=sk-...
REPLICATE_API_TOKEN=r8_...

# Monitoring
SENTRY_DSN=https://...@sentry.io/...

# Email (optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

### Frontend (`frontend/.env.local`)

```bash
# API
NEXT_PUBLIC_API_URL=http://localhost:4000/api
NEXT_PUBLIC_WS_URL=ws://localhost:4001

# Stripe
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...

# Sentry
NEXT_PUBLIC_SENTRY_DSN=https://...@sentry.io/...

# Feature Flags
NEXT_PUBLIC_ENABLE_OAUTH=true
NEXT_PUBLIC_ENABLE_AI_TOOLS=true
```

---

## 📁 Structure du Projet

```
pixora/
├── backend/                 # NestJS API
│   ├── src/
│   │   ├── modules/
│   │   │   ├── auth/       # Authentication (JWT, OAuth2, RBAC)
│   │   │   ├── users/      # User management
│   │   │   ├── projects/   # Projects CRUD
│   │   │   ├── boards/     # Whiteboard state management
│   │   │   ├── assets/     # Asset upload/metadata
│   │   │   ├── tokens/     # Token balance & deduction
│   │   │   ├── billing/    # Stripe integration
│   │   │   ├── collaborators/ # Project sharing & permissions
│   │   │   └── agent/      # AI tool router
│   │   ├── common/
│   │   │   ├── guards/     # Auth guards
│   │   │   ├── decorators/ # Custom decorators
│   │   │   ├── interceptors/
│   │   │   └── filters/    # Exception filters
│   │   ├── database/
│   │   │   ├── migrations/ # SQL migrations
│   │   │   └── seeds/      # Seed data
│   │   └── main.ts
│   ├── test/               # E2E tests
│   ├── Dockerfile
│   ├── package.json
│   └── tsconfig.json
│
├── frontend/               # Next.js App
│   ├── app/
│   │   ├── (auth)/        # Auth routes (login, signup)
│   │   ├── (dashboard)/   # Protected routes
│   │   │   ├── projects/
│   │   │   ├── board/[id]/
│   │   │   └── settings/
│   │   ├── api/           # API routes (BFF pattern)
│   │   └── layout.tsx
│   ├── components/
│   │   ├── whiteboard/    # Canvas components
│   │   │   ├── Whiteboard.tsx
│   │   │   ├── Toolbar.tsx
│   │   │   ├── LayerPanel.tsx
│   │   │   └── AssetLibrary.tsx
│   │   ├── ui/            # shadcn/ui components
│   │   └── shared/
│   ├── hooks/
│   │   ├── useYjs.ts      # Yjs collaboration hook
│   │   ├── useTokens.ts   # Token balance
│   │   └── useProjects.ts
│   ├── lib/
│   │   ├── api.ts         # API client
│   │   └── yjs.ts         # Yjs setup
│   ├── Dockerfile
│   ├── package.json
│   └── next.config.js
│
├── y-websocket-server/    # Real-time collaboration server
│   ├── src/
│   │   └── index.ts
│   ├── Dockerfile
│   └── package.json
│
├── ai-service/            # AI Agent microservice
│   ├── src/
│   │   ├── planner.ts     # Intent classification
│   │   ├── selector.ts    # Tool selection
│   │   ├── executor.ts    # API calls
│   │   └── workers/       # BullMQ workers
│   ├── Dockerfile
│   └── package.json
│
├── infra/                 # Infrastructure
│   ├── k8s/              # Kubernetes manifests
│   │   ├── deployments/
│   │   ├── services/
│   │   └── ingress/
│   ├── helm/             # Helm charts
│   └── terraform/        # Terraform (optionnel)
│
├── .github/
│   └── workflows/
│       ├── ci.yml        # Lint, test, build
│       └── deploy.yml    # Deploy to staging/prod
│
├── docker-compose.yml    # Dev environment
├── Makefile             # Dev commands
├── .env.example
└── README.md
```

---

## 🧪 Tests

### Tests Unitaires (Jest)

```bash
# Backend
cd backend
npm run test              # Tous les tests
npm run test:watch        # Mode watch
npm run test:cov          # Coverage

# Frontend
cd frontend
npm run test
```

### Tests E2E (Playwright)

```bash
# Démarrer l'app en mode test
make test:e2e

# Ou manuellement
docker-compose -f docker-compose.test.yml up -d
cd frontend
npx playwright test
```

### Tests de Charge (k6)

```bash
cd backend/test/load
k6 run --vus 100 --duration 30s api-load-test.js
```

---

## 🔒 Sécurité

### Checklist Sécurité

- [x] **Validation input** côté serveur (class-validator)
- [x] **Rate limiting** (Throttler module)
- [x] **CORS** configuré strictement
- [x] **Helmet.js** headers sécurisés
- [x] **SQL injection prevention** (Prisma parameterized queries)
- [x] **XSS protection** (sanitization)
- [x] **CSRF tokens** pour forms critiques
- [x] **JWT rotation** (refresh tokens)
- [x] **Secrets management** (Vault / AWS Secrets Manager en prod)
- [x] **HTTPS only** en production
- [x] **RBAC** pour projects (owner/editor/viewer)
- [ ] **MFA** (à venir v1.5)
- [ ] **Audit logs** (à venir Enterprise)

### Rapporter une Vulnérabilité

Envoyer à **security@pixora.com** — ne PAS créer d'issue publique.

---

## 🚢 Déploiement

### Environnements

| Env | URL | Branch | Auto-deploy |
|-----|-----|--------|-------------|
| **Dev** | localhost | `develop` | Non |
| **Staging** | staging.pixora.com | `staging` | Oui (PR merge) |
| **Production** | pixora.com | `main` | Manuel |

### Déploiement Production (Kubernetes)

```bash
# 1. Build & push images
make docker:build
make docker:push

# 2. Deploy via Helm
helm upgrade --install pixora ./infra/helm/pixora \
  --namespace production \
  --values ./infra/helm/values.prod.yaml

# 3. Vérifier déploiement
kubectl get pods -n production
kubectl logs -f deployment/pixora-backend -n production
```

### Rollback

```bash
helm rollback pixora -n production
```

---

## 📊 Monitoring & Observabilité

### Dashboards

- **Grafana**: https://grafana.pixora.com
- **Sentry**: https://sentry.io/organizations/pixora
- **Stripe Dashboard**: https://dashboard.stripe.com

### Métriques Clés

- **Latency API** (p50, p95, p99)
- **AI Job Queue** (pending, active, completed, failed)
- **Token Transactions** (rate, balance distribution)
- **Real-time Connections** (active WebSockets)
- **Error Rate** (5xx, exceptions Sentry)

### Alertes

Configurées dans `infra/monitoring/alerts.yml`:
- API latency > 1s (p95)
- Error rate > 1%
- Queue depth > 1000 jobs
- Database connections > 80%
- Disk usage > 85%

---

## 🗺️ Roadmap

### ✅ MVP (Sprint 1-3) — Q1 2025

- [x] Auth (email + Google OAuth)
- [x] Projects CRUD
- [x] Whiteboard minimal (upload, move, resize)
- [x] Save/load board state
- [x] Token system (mock)
- [x] AI agent (mock responses)
- [x] Stripe integration (test mode)

### 🚧 v1.0 (Sprint 4-6) — Q2 2025

- [ ] Real-time collaboration (Yjs)
- [ ] AI generators live (logo, social post)
- [ ] Responsive mobile UI
- [ ] Share links & permissions
- [ ] Email notifications
- [ ] Analytics dashboard

### 🔮 v1.5 (Q3 2025)

- [ ] Brand library (colors, fonts, guidelines)
- [ ] Templates marketplace
- [ ] Figma/Canva import
- [ ] Video mockups
- [ ] MFA
- [ ] Webhooks API for integrations

### 🏢 Enterprise (Q4 2025)

- [ ] SSO SAML
- [ ] Audit logs
- [ ] Custom domain white-labeling
- [ ] On-premise deployment option
- [ ] SLA 99.9%
- [ ] Dedicated support

---

## 🤝 Contribution

### Workflow

1. Fork le repo
2. Créer une feature branch (`git checkout -b feature/ma-feature`)
3. Commit (`git commit -m 'Add: ma feature'`)
4. Push (`git push origin feature/ma-feature`)
5. Ouvrir une Pull Request

### Conventions

- **Commits**: [Conventional Commits](https://www.conventionalcommits.org/)
  - `feat: add logo generator`
  - `fix: token deduction race condition`
  - `docs: update API docs`
- **Code style**: ESLint + Prettier (auto-format on save)
- **Tests**: Coverage > 80% pour features critiques
- **PR**: Doit passer CI + review de 2 devs

---

## 📚 Documentation Supplémentaire

- [API Documentation](./docs/API.md) — OpenAPI/Swagger
- [Database Schema](./docs/DATABASE.md) — Tables, relations, migrations
- [Whiteboard Architecture](./docs/WHITEBOARD.md) — CRDT, Yjs, conflict resolution
- [AI Agent Design](./docs/AI_AGENT.md) — Tool router, executors, prompts
- [Deployment Guide](./docs/DEPLOYMENT.md) — K8s, Helm, CI/CD
- [Security Policy](./docs/SECURITY.md) — Threat model, mitigations
- [Contributing Guide](./CONTRIBUTING.md)

---

## 📄 License

MIT License - voir [LICENSE](./LICENSE)

---

## 📧 Contact

- **Website**: https://pixora.com
- **Support**: support@pixora.com
- **Twitter**: [@PixoraHQ](https://twitter.com/PixoraHQ)
- **Discord**: https://discord.gg/pixora

---

## ✅ Checklist Développeur (Onboarding)

### Jour 1

- [ ] Installer prérequis (Node.js, Docker, Git)
- [ ] Cloner le repo et configurer .env
- [ ] Lancer `make dev` et vérifier que tous les services démarrent
- [ ] Créer un compte sur http://localhost:3000
- [ ] Créer un projet et uploader une image sur le whiteboard
- [ ] Lire l'architecture (ce README + docs/)

### Semaine 1

- [ ] Parcourir le code backend (modules NestJS)
- [ ] Parcourir le code frontend (components Next.js)
- [ ] Lancer les tests (`make test`) et comprendre la structure
- [ ] Faire une première contribution (fix typo, améliorer docs)
- [ ] Participer au standup quotidien
- [ ] Reviewer une PR d'un collègue

### Mois 1

- [ ] Implémenter une feature complète (backend + frontend + tests)
- [ ] Déployer sur staging
- [ ] Monitorer avec Grafana/Sentry
- [ ] Participer à la sprint planning

---

**🎉 Bienvenue dans l'équipe Pixora!**
