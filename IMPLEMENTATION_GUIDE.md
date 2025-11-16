# Pixora - Guide d'Implémentation Complet

## 📋 État d'Avancement du Projet

### ✅ COMPLÉTÉ (Prêt à l'emploi)

#### 1. Documentation & Architecture
- [x] **README.md** - Guide complet avec quick start, commandes, checklist onboarding
- [x] **ARCHITECTURE.md** - Architecture détaillée, data flow, scaling strategy
- [x] **openapi.yaml** - Spécification OpenAPI complète de l'API
- [x] **.gitignore** - Configuration Git
- [x] **.prettierrc** - Configuration Prettier
- [x] **.commitlintrc.json** - Conventional commits
- [x] **Makefile** - 30+ commandes pour développement

#### 2. Infrastructure & DevOps
- [x] **docker-compose.yml** - Environnement dev complet (Postgres, Redis, Minio, services)
- [x] **docker-compose.test.yml** - Environnement test isolé
- [x] **Structure de dossiers** - Arborescence complète backend/frontend/infra

#### 3. Base de Données
- [x] **001_initial_schema.sql** - Schema SQL complet avec:
  - Tables: users, projects, boards, assets, tokens_balance, transactions, subscriptions, collaborators, ai_jobs, etc.
  - Enums: user_role, project_role, transaction_type, asset_type, job_status
  - Indexes optimisés
  - Triggers (auto-update timestamps, auto-create tokens_balance)
  - Seed data (admin + test users)
- [x] **dev-seed.sql** - Données de test pour développement

#### 4. Backend (NestJS) - Structure de Base
- [x] **package.json** - Dépendances complètes
- [x] **tsconfig.json** - Configuration TypeScript
- [x] **Dockerfile** - Multi-stage build (dev + prod)
- [x] **.env.example** - Variables d'environnement
- [x] **nest-cli.json** - Configuration NestJS
- [x] **src/main.ts** - Entry point avec Swagger, CORS, Helmet, validation
- [x] **src/app.module.ts** - Root module avec TypeORM, Throttler
- [x] **src/modules/health/** - Health check endpoint

#### 5. Configuration Workspace
- [x] **package.json (root)** - npm workspaces
- [x] Scripts pour build, test, lint, format

---

## 🚧 À IMPLÉMENTER (Détails Ci-Dessous)

### 1. Backend - Modules Critiques

#### Auth Module (src/modules/auth/)
**Fichiers à créer**:
```
auth/
├── auth.module.ts ✅ (créé)
├── auth.controller.ts
├── auth.service.ts
├── strategies/
│   ├── jwt.strategy.ts
│   └── google.strategy.ts
├── guards/
│   ├── jwt-auth.guard.ts
│   └── roles.guard.ts
├── dto/
│   ├── login.dto.ts
│   ├── signup.dto.ts
│   └── auth-response.dto.ts
└── auth.service.spec.ts
```

**Endpoints à implémenter**:
- `POST /auth/signup` - Créer compte (email + password hash bcrypt)
- `POST /auth/login` - Se connecter (retourne JWT + refresh token)
- `POST /auth/refresh` - Refresh access token
- `GET /auth/google` - Initier OAuth2 Google
- `GET /auth/google/callback` - Callback OAuth2
- `POST /auth/logout` - Invalider refresh token

**Logique clé**:
```typescript
// auth.service.ts (pseudo-code)
async signup(dto: SignupDto) {
  // 1. Vérifier email unique
  // 2. Hash password avec bcrypt (rounds: 10)
  // 3. Créer user dans DB
  // 4. Auto-créer tokens_balance (trigger)
  // 5. Générer JWT + refresh token
  // 6. Sauvegarder refresh token en DB
  // 7. Retourner { user, tokens }
}

async login(dto: LoginDto) {
  // 1. Trouver user par email
  // 2. Comparer password hash
  // 3. Générer JWT + refresh token
  // 4. Retourner { user, tokens }
}

async validateUser(userId: string) {
  // Utilisé par JwtStrategy
  // Retourne user si actif
}
```

**Test à écrire**:
```typescript
// auth.service.spec.ts
describe('AuthService', () => {
  it('should hash password on signup');
  it('should throw if email already exists');
  it('should validate correct password');
  it('should reject invalid password');
  it('should generate valid JWT');
});
```

---

#### Projects Module (src/modules/projects/)
**Fichiers**:
```
projects/
├── projects.module.ts
├── projects.controller.ts
├── projects.service.ts
├── entities/
│   └── project.entity.ts
├── dto/
│   ├── create-project.dto.ts
│   └── update-project.dto.ts
└── projects.service.spec.ts
```

**Endpoints**:
- `GET /projects` - Lister projets (cursor pagination)
- `POST /projects` - Créer projet
- `GET /projects/:id` - Obtenir projet
- `PATCH /projects/:id` - Modifier projet
- `DELETE /projects/:id` - Supprimer projet (soft delete)

**Entity TypeORM**:
```typescript
@Entity('projects')
export class Project {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column({ nullable: true })
  description: string;

  @Column('uuid')
  ownerId: string;

  @Column('jsonb', { default: {} })
  settings: Record<string, any>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @DeleteDateColumn()
  deletedAt: Date;
}
```

**Guards à ajouter**:
```typescript
@UseGuards(JwtAuthGuard, ProjectOwnerGuard)
@Delete(':id')
async remove(@Param('id') id: string) {
  // Seul le owner peut supprimer
}
```

---

#### Tokens Module (src/modules/tokens/)
**CRITIQUE: Transactions ACID pour tokens**

**Fichiers**:
```
tokens/
├── tokens.module.ts
├── tokens.controller.ts
├── tokens.service.ts
├── entities/
│   ├── tokens-balance.entity.ts
│   └── transaction.entity.ts
├── guards/
│   └── has-tokens.guard.ts
└── tokens.service.spec.ts
```

**Service avec transactions**:
```typescript
import { DataSource, QueryRunner } from 'typeorm';

export class TokensService {
  constructor(private dataSource: DataSource) {}

  /**
   * Reserve tokens atomically (PENDING transaction)
   */
  async reserveTokens(
    userId: string,
    amount: number,
    metadata: any,
    idempotencyKey?: string
  ): Promise<Transaction> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction('SERIALIZABLE');

    try {
      // 1. Check balance (FOR UPDATE pour lock la row)
      const balance = await queryRunner.manager.findOne(TokensBalance, {
        where: { userId },
        lock: { mode: 'pessimistic_write' },
      });

      if (balance.balance < amount) {
        throw new InsufficientTokensException();
      }

      // 2. Créer transaction PENDING
      const transaction = queryRunner.manager.create(Transaction, {
        userId,
        amount: -amount,
        type: TransactionType.DEDUCTION,
        status: TransactionStatus.PENDING,
        metadata,
        idempotencyKey,
      });
      await queryRunner.manager.save(transaction);

      // 3. Commit
      await queryRunner.commitTransaction();
      return transaction;
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * Complete token deduction (PENDING -> COMPLETED)
   */
  async completeDeduction(transactionId: string): Promise<void> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction('SERIALIZABLE');

    try {
      const transaction = await queryRunner.manager.findOne(Transaction, {
        where: { id: transactionId },
        lock: { mode: 'pessimistic_write' },
      });

      if (transaction.status !== TransactionStatus.PENDING) {
        throw new Error('Transaction already completed or failed');
      }

      // Update balance
      await queryRunner.manager.decrement(
        TokensBalance,
        { userId: transaction.userId },
        'balance',
        Math.abs(transaction.amount)
      );

      // Mark transaction completed
      transaction.status = TransactionStatus.COMPLETED;
      transaction.completedAt = new Date();
      await queryRunner.manager.save(transaction);

      await queryRunner.commitTransaction();
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * Refund tokens (PENDING -> FAILED)
   */
  async refundTokens(transactionId: string): Promise<void> {
    // Similar logic, mark transaction as FAILED
    // No balance change since tokens were only reserved
  }
}
```

**Guard pour vérifier tokens**:
```typescript
@Injectable()
export class HasTokensGuard implements CanActivate {
  constructor(private tokensService: TokensService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    const requiredTokens = request.body.estimatedTokens || 0;

    const balance = await this.tokensService.getBalance(user.id);
    return balance >= requiredTokens;
  }
}
```

---

### 2. Frontend (Next.js 14)

#### Structure de Base
**Fichiers critiques**:
```
frontend/
├── package.json
├── tsconfig.json
├── next.config.js
├── tailwind.config.js
├── Dockerfile
├── .env.example
├── app/
│   ├── layout.tsx
│   ├── page.tsx (landing page)
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   └── signup/page.tsx
│   ├── (dashboard)/
│   │   ├── layout.tsx (sidebar, nav)
│   │   ├── projects/page.tsx
│   │   └── board/[id]/page.tsx
│   └── api/
│       └── auth/[...nextauth]/route.ts (optionnel)
├── components/
│   ├── whiteboard/
│   │   ├── Whiteboard.tsx
│   │   ├── Toolbar.tsx
│   │   └── LayerPanel.tsx
│   ├── ui/ (shadcn/ui components)
│   └── shared/
├── hooks/
│   ├── useYjs.ts
│   ├── useAuth.ts
│   └── useTokens.ts
└── lib/
    ├── api.ts
    └── yjs.ts
```

#### package.json
```json
{
  "name": "@pixora/frontend",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "typecheck": "tsc --noEmit",
    "test:e2e": "playwright test"
  },
  "dependencies": {
    "next": "^14.1.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-konva": "^18.2.10",
    "konva": "^9.3.0",
    "yjs": "^13.6.10",
    "y-websocket": "^1.5.0",
    "swr": "^2.2.4",
    "zustand": "^4.4.7",
    "@radix-ui/react-dialog": "^1.0.5",
    "@radix-ui/react-dropdown-menu": "^2.0.6",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.1.0",
    "tailwind-merge": "^2.2.0",
    "lucide-react": "^0.303.0"
  },
  "devDependencies": {
    "@types/node": "^20.10.6",
    "@types/react": "^18.2.46",
    "@types/react-dom": "^18.2.18",
    "@playwright/test": "^1.40.1",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.33",
    "tailwindcss": "^3.4.0",
    "typescript": "^5.3.3"
  }
}
```

#### Whiteboard Component (React Konva)
```typescript
// components/whiteboard/Whiteboard.tsx
'use client';

import { useEffect, useRef, useState } from 'react';
import { Stage, Layer, Image, Rect, Text, Transformer } from 'react-konva';
import useImage from 'use-image';
import { useYjs } from '@/hooks/useYjs';

interface WhiteboardObject {
  id: string;
  type: 'image' | 'text' | 'sticky';
  x: number;
  y: number;
  width: number;
  height: number;
  rotation: number;
  data: any;
}

export function Whiteboard({ projectId }: { projectId: string }) {
  const stageRef = useRef<any>(null);
  const [objects, setObjects] = useState<WhiteboardObject[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);

  // Yjs real-time collaboration
  const { ydoc, provider, awareness } = useYjs(projectId);

  useEffect(() => {
    if (!ydoc) return;

    // Sync objects from Yjs shared map
    const yObjects = ydoc.getMap('objects');

    const updateObjects = () => {
      const newObjects: WhiteboardObject[] = [];
      yObjects.forEach((value, key) => {
        newObjects.push({ id: key, ...value });
      });
      setObjects(newObjects);
    };

    yObjects.observe(updateObjects);
    updateObjects();

    return () => yObjects.unobserve(updateObjects);
  }, [ydoc]);

  const handleDragEnd = (id: string, e: any) => {
    const node = e.target;
    const yObjects = ydoc.getMap('objects');
    const obj = yObjects.get(id);
    yObjects.set(id, {
      ...obj,
      x: node.x(),
      y: node.y(),
    });
  };

  const handleTransformEnd = (id: string, e: any) => {
    const node = e.target;
    const yObjects = ydoc.getMap('objects');
    const obj = yObjects.get(id);
    yObjects.set(id, {
      ...obj,
      x: node.x(),
      y: node.y(),
      rotation: node.rotation(),
      width: node.width() * node.scaleX(),
      height: node.height() * node.scaleY(),
    });
    node.scaleX(1);
    node.scaleY(1);
  };

  return (
    <div className="w-full h-full bg-gray-100">
      <Stage
        ref={stageRef}
        width={window.innerWidth}
        height={window.innerHeight}
        onMouseDown={(e) => {
          // Deselect when clicking on empty area
          if (e.target === e.target.getStage()) {
            setSelectedId(null);
          }
        }}
      >
        <Layer>
          {objects.map((obj) => {
            if (obj.type === 'image') {
              return (
                <URLImage
                  key={obj.id}
                  object={obj}
                  isSelected={obj.id === selectedId}
                  onSelect={() => setSelectedId(obj.id)}
                  onDragEnd={(e) => handleDragEnd(obj.id, e)}
                  onTransformEnd={(e) => handleTransformEnd(obj.id, e)}
                />
              );
            }
            // Handle other types (text, sticky notes, etc.)
            return null;
          })}
        </Layer>
      </Stage>
    </div>
  );
}

// Helper component for image objects
function URLImage({ object, isSelected, onSelect, onDragEnd, onTransformEnd }) {
  const [image] = useImage(object.data.url);
  const shapeRef = useRef();
  const trRef = useRef();

  useEffect(() => {
    if (isSelected && trRef.current && shapeRef.current) {
      trRef.current.nodes([shapeRef.current]);
      trRef.current.getLayer().batchDraw();
    }
  }, [isSelected]);

  return (
    <>
      <Image
        ref={shapeRef}
        image={image}
        x={object.x}
        y={object.y}
        width={object.width}
        height={object.height}
        rotation={object.rotation}
        draggable
        onClick={onSelect}
        onTap={onSelect}
        onDragEnd={onDragEnd}
        onTransformEnd={onTransformEnd}
      />
      {isSelected && (
        <Transformer
          ref={trRef}
          boundBoxFunc={(oldBox, newBox) => {
            // Limit resize
            if (newBox.width < 20 || newBox.height < 20) {
              return oldBox;
            }
            return newBox;
          }}
        />
      )}
    </>
  );
}
```

#### useYjs Hook
```typescript
// hooks/useYjs.ts
import { useEffect, useState } from 'react';
import * as Y from 'yjs';
import { WebsocketProvider } from 'y-websocket';

export function useYjs(roomId: string) {
  const [ydoc] = useState(() => new Y.Doc());
  const [provider, setProvider] = useState<WebsocketProvider | null>(null);
  const [awareness, setAwareness] = useState<any>(null);

  useEffect(() => {
    const wsProvider = new WebsocketProvider(
      process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:4001',
      `project-${roomId}`,
      ydoc,
      {
        connect: true,
      }
    );

    setProvider(wsProvider);
    setAwareness(wsProvider.awareness);

    // Set local user info
    wsProvider.awareness.setLocalStateField('user', {
      name: 'User', // Get from auth context
      color: '#' + Math.floor(Math.random() * 16777215).toString(16),
    });

    return () => {
      wsProvider.destroy();
    };
  }, [roomId, ydoc]);

  return { ydoc, provider, awareness };
}
```

---

### 3. Y-WebSocket Server

**Structure**:
```
y-websocket-server/
├── package.json
├── tsconfig.json
├── Dockerfile
├── src/
│   └── index.ts
```

**package.json**:
```json
{
  "name": "@pixora/y-websocket-server",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "ts-node-dev --respawn src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js"
  },
  "dependencies": {
    "yjs": "^13.6.10",
    "y-websocket": "^1.5.0",
    "ws": "^8.16.0",
    "ioredis": "^5.3.2"
  },
  "devDependencies": {
    "@types/node": "^20.10.6",
    "@types/ws": "^8.5.10",
    "ts-node-dev": "^2.0.0",
    "typescript": "^5.3.3"
  }
}
```

**src/index.ts**:
```typescript
import http from 'http';
import { WebSocketServer } from 'ws';
import * as Y from 'yjs';
import { setupWSConnection } from 'y-websocket/bin/utils';
import Redis from 'ioredis';

const PORT = process.env.PORT || 4001;
const REDIS_HOST = process.env.REDIS_HOST || 'localhost';
const REDIS_PORT = parseInt(process.env.REDIS_PORT || '6379');

// Redis pub/sub for multi-instance awareness sync
const redisPub = new Redis({ host: REDIS_HOST, port: REDIS_PORT });
const redisSub = new Redis({ host: REDIS_HOST, port: REDIS_PORT });

// Create HTTP server
const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok' }));
  } else {
    res.writeHead(404);
    res.end();
  }
});

// Create WebSocket server
const wss = new WebSocketServer({ server });

// Map of room -> Y.Doc
const docs = new Map<string, Y.Doc>();

wss.on('connection', (ws, req) => {
  const roomName = req.url?.slice(1); // Get room from URL path

  if (!roomName) {
    ws.close();
    return;
  }

  console.log(`New connection to room: ${roomName}`);

  // Get or create Y.Doc for this room
  if (!docs.has(roomName)) {
    const doc = new Y.Doc();
    docs.set(roomName, doc);

    // Load persisted state from Redis (optional)
    // const persistedState = await redis.get(`yjs:${roomName}`);
    // if (persistedState) {
    //   Y.applyUpdate(doc, Buffer.from(persistedState, 'base64'));
    // }

    // Persist updates to Redis periodically
    doc.on('update', async (update: Uint8Array) => {
      const state = Y.encodeStateAsUpdate(doc);
      await redisPub.set(`yjs:${roomName}`, Buffer.from(state).toString('base64'));
    });
  }

  const doc = docs.get(roomName)!;

  // Setup WebSocket connection for this doc
  setupWSConnection(ws, req, { doc });
});

// Subscribe to Redis for cross-instance updates
redisSub.on('message', (channel, message) => {
  const [, roomName] = channel.split(':');
  const doc = docs.get(roomName);
  if (doc) {
    const update = Buffer.from(message, 'base64');
    Y.applyUpdate(doc, update);
  }
});

server.listen(PORT, () => {
  console.log(`🔌 Y-WebSocket server running on ws://localhost:${PORT}`);
});
```

---

### 4. AI Service (Agent Tool-Router)

**Structure**:
```
ai-service/
├── package.json
├── tsconfig.json
├── Dockerfile
├── src/
│   ├── index.ts
│   ├── planner.ts
│   ├── selector.ts
│   ├── estimator.ts
│   ├── executors/
│   │   ├── base.executor.ts
│   │   ├── logo-generator.executor.ts
│   │   └── ...
│   └── workers/
│       └── ai-job.worker.ts
```

**planner.ts** (Intent Classification):
```typescript
import Anthropic from '@anthropic-ai/sdk';

export class Planner {
  private anthropic: Anthropic;

  constructor() {
    this.anthropic = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    });
  }

  async classifyIntent(prompt: string, context: any): Promise<{
    tool: string;
    parameters: any;
  }> {
    const systemPrompt = `You are a creative AI assistant that analyzes user requests and determines which tool to use.

Available tools:
- logo-generator: Create logos, brand marks, icons
- social-post: Generate social media posts with image + caption
- copywriter: Write marketing copy, headlines, descriptions
- mockup-generator: Create website or app mockups
- image-upscaler: Enhance image quality and resolution

Respond with JSON: { "tool": "<tool-name>", "parameters": { ... } }`;

    const response = await this.anthropic.messages.create({
      model: 'claude-3-haiku-20240307',
      max_tokens: 500,
      system: systemPrompt,
      messages: [
        {
          role: 'user',
          content: `User request: "${prompt}"\nContext: ${JSON.stringify(context)}`,
        },
      ],
    });

    const content = response.content[0];
    if (content.type === 'text') {
      return JSON.parse(content.text);
    }

    throw new Error('Failed to classify intent');
  }
}
```

**executors/logo-generator.executor.ts**:
```typescript
import Anthropic from '@anthropic-ai/sdk';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

export class LogoGeneratorExecutor {
  private anthropic: Anthropic;
  private s3: S3Client;

  constructor() {
    this.anthropic = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    });
    this.s3 = new S3Client({
      endpoint: process.env.S3_ENDPOINT,
      region: process.env.S3_REGION,
      credentials: {
        accessKeyId: process.env.S3_ACCESS_KEY!,
        secretAccessKey: process.env.S3_SECRET_KEY!,
      },
      forcePathStyle: true,
    });
  }

  async execute(prompt: string, parameters: any): Promise<{ assetUrls: string[] }> {
    // 1. Generate logo description with Claude
    const description = await this.generateLogoDescription(prompt, parameters);

    // 2. Generate image with external API (Stability AI, DALL-E, etc.)
    // For MVP: Mock implementation
    const mockImageUrl = `https://via.placeholder.com/512?text=Logo`;

    // 3. Upload to S3
    const s3Key = `logos/${Date.now()}.png`;
    await this.s3.send(new PutObjectCommand({
      Bucket: process.env.S3_BUCKET,
      Key: s3Key,
      Body: await fetch(mockImageUrl).then(r => r.arrayBuffer()),
      ContentType: 'image/png',
    }));

    const assetUrl = `${process.env.S3_PUBLIC_URL}/${s3Key}`;

    return { assetUrls: [assetUrl] };
  }

  private async generateLogoDescription(prompt: string, parameters: any): Promise<string> {
    const response = await this.anthropic.messages.create({
      model: 'claude-3-sonnet-20240229',
      max_tokens: 300,
      messages: [
        {
          role: 'user',
          content: `Create a detailed visual description for a logo based on this request: "${prompt}". Style: ${parameters.style || 'modern'}. Industry: ${parameters.industry || 'general'}. Colors: ${parameters.colors?.join(', ') || 'any'}.`,
        },
      ],
    });

    const content = response.content[0];
    if (content.type === 'text') {
      return content.text;
    }

    throw new Error('Failed to generate description');
  }
}
```

**workers/ai-job.worker.ts** (BullMQ):
```typescript
import { Worker, Job } from 'bullmq';
import Redis from 'ioredis';
import { LogoGeneratorExecutor } from '../executors/logo-generator.executor';
// Import other executors...

const connection = new Redis({
  host: process.env.REDIS_HOST,
  port: parseInt(process.env.REDIS_PORT || '6379'),
});

const executors = {
  'logo-generator': new LogoGeneratorExecutor(),
  // Add other executors...
};

const worker = new Worker(
  'ai-jobs',
  async (job: Job) => {
    console.log(`Processing job ${job.id}: ${job.data.tool}`);

    const { tool, prompt, parameters, transactionId } = job.data;

    try {
      // Update progress
      await job.updateProgress(10);

      // Execute tool
      const executor = executors[tool];
      if (!executor) {
        throw new Error(`Unknown tool: ${tool}`);
      }

      await job.updateProgress(50);

      const result = await executor.execute(prompt, parameters);

      await job.updateProgress(90);

      // Confirm token deduction
      // await tokensService.completeDeduction(transactionId);

      await job.updateProgress(100);

      return result;
    } catch (error) {
      // Refund tokens on failure
      // await tokensService.refundTokens(transactionId);
      throw error;
    }
  },
  {
    connection,
    concurrency: 5,
    limiter: {
      max: 10,
      duration: 1000, // 10 jobs per second max
    },
  }
);

worker.on('completed', (job) => {
  console.log(`✅ Job ${job.id} completed`);
});

worker.on('failed', (job, err) => {
  console.error(`❌ Job ${job?.id} failed:`, err);
});

console.log('🤖 AI worker started');
```

---

### 5. CI/CD (GitHub Actions)

**Fichier**: `.github/workflows/ci.yml`
```yaml
name: CI

on:
  push:
    branches: [main, develop, 'claude/**']
  pull_request:
    branches: [main, develop]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm run format:check

  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run typecheck

  test-backend:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_USER: pixora_test
          POSTGRES_PASSWORD: pixora_test
          POSTGRES_DB: pixora_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: cd backend && npm run test:cov
        env:
          DATABASE_URL: postgresql://pixora_test:pixora_test@localhost:5432/pixora_test
          REDIS_HOST: localhost
          REDIS_PORT: 6379
      - uses: codecov/codecov-action@v3
        with:
          files: ./backend/coverage/coverage-final.json

  test-e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: docker-compose -f docker-compose.test.yml up -d
      - run: sleep 10 # Wait for services
      - run: cd frontend && npm run test:e2e
      - uses: actions/upload-artifact@v3
        if: always()
        with:
          name: playwright-report
          path: frontend/playwright-report/

  build:
    runs-on: ubuntu-latest
    needs: [lint, typecheck, test-backend]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-artifact@v3
        with:
          name: build-artifacts
          path: |
            backend/dist/
            frontend/.next/

  docker-build:
    runs-on: ubuntu-latest
    needs: build
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          context: ./backend
          push: true
          tags: ghcr.io/${{ github.repository }}/backend:latest
      - uses: docker/build-push-action@v5
        with:
          context: ./frontend
          push: true
          tags: ghcr.io/${{ github.repository }}/frontend:latest
```

---

### 6. Tests

#### Backend Unit Test (Jest)
```typescript
// backend/src/modules/tokens/tokens.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import { TokensService } from './tokens.service';
import { InsufficientTokensException } from './exceptions';

describe('TokensService', () => {
  let service: TokensService;
  let dataSource: DataSource;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TokensService,
        {
          provide: DataSource,
          useValue: {
            createQueryRunner: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<TokensService>(TokensService);
    dataSource = module.get<DataSource>(DataSource);
  });

  describe('reserveTokens', () => {
    it('should reserve tokens when balance is sufficient', async () => {
      // Mock queryRunner
      const mockQueryRunner = {
        connect: jest.fn(),
        startTransaction: jest.fn(),
        manager: {
          findOne: jest.fn().mockResolvedValue({ balance: 500 }),
          create: jest.fn().mockReturnValue({}),
          save: jest.fn().mockResolvedValue({ id: '123' }),
        },
        commitTransaction: jest.fn(),
        rollbackTransaction: jest.fn(),
        release: jest.fn(),
      };

      jest.spyOn(dataSource, 'createQueryRunner').mockReturnValue(mockQueryRunner as any);

      const result = await service.reserveTokens('user-123', 100, {});

      expect(mockQueryRunner.connect).toHaveBeenCalled();
      expect(mockQueryRunner.startTransaction).toHaveBeenCalledWith('SERIALIZABLE');
      expect(mockQueryRunner.commitTransaction).toHaveBeenCalled();
    });

    it('should throw InsufficientTokensException when balance is insufficient', async () => {
      const mockQueryRunner = {
        connect: jest.fn(),
        startTransaction: jest.fn(),
        manager: {
          findOne: jest.fn().mockResolvedValue({ balance: 50 }),
        },
        rollbackTransaction: jest.fn(),
        release: jest.fn(),
      };

      jest.spyOn(dataSource, 'createQueryRunner').mockReturnValue(mockQueryRunner as any);

      await expect(service.reserveTokens('user-123', 100, {})).rejects.toThrow(
        InsufficientTokensException
      );

      expect(mockQueryRunner.rollbackTransaction).toHaveBeenCalled();
    });
  });
});
```

#### Frontend E2E Test (Playwright)
```typescript
// frontend/tests/auth.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Authentication', () => {
  test('should allow user to signup', async ({ page }) => {
    await page.goto('/signup');

    await page.fill('input[name="email"]', 'test@example.com');
    await page.fill('input[name="password"]', 'Test123!');
    await page.fill('input[name="firstName"]', 'Test');
    await page.fill('input[name="lastName"]', 'User');

    await page.click('button[type="submit"]');

    await expect(page).toHaveURL('/projects');
  });

  test('should allow user to login', async ({ page }) => {
    await page.goto('/login');

    await page.fill('input[name="email"]', 'test@pixora.com');
    await page.fill('input[name="password"]', 'Test123!');

    await page.click('button[type="submit"]');

    await expect(page).toHaveURL('/projects');
  });

  test('should show error on invalid credentials', async ({ page }) => {
    await page.goto('/login');

    await page.fill('input[name="email"]', 'wrong@example.com');
    await page.fill('input[name="password"]', 'WrongPass');

    await page.click('button[type="submit"]');

    await expect(page.locator('[role="alert"]')).toContainText('Invalid credentials');
  });
});
```

```typescript
// frontend/tests/whiteboard.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Whiteboard', () => {
  test.beforeEach(async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.fill('input[name="email"]', 'test@pixora.com');
    await page.fill('input[name="password"]', 'Test123!');
    await page.click('button[type="submit"]');
  });

  test('should load whiteboard for project', async ({ page }) => {
    // Navigate to first project
    await page.goto('/projects');
    await page.click('[data-testid="project-card"]:first-child');

    await expect(page).toHaveURL(/\/board\/.+/);
    await expect(page.locator('canvas')).toBeVisible();
  });

  test('should upload and place image on board', async ({ page, browser }) => {
    await page.goto('/board/test-project-id');

    // Upload image
    const fileInput = page.locator('input[type="file"]');
    await fileInput.setInputFiles('tests/fixtures/test-image.png');

    // Wait for image to appear on canvas
    await page.waitForSelector('[data-konva-type="Image"]');

    const imageCount = await page.locator('[data-konva-type="Image"]').count();
    expect(imageCount).toBeGreaterThan(0);
  });

  test('should sync changes across multiple users', async ({ browser }) => {
    // Create two browser contexts (two users)
    const context1 = await browser.newContext();
    const context2 = await browser.newContext();

    const page1 = await context1.newPage();
    const page2 = await context2.newPage();

    // Both users login and go to same project
    // ... login logic ...

    await page1.goto('/board/test-project-id');
    await page2.goto('/board/test-project-id');

    // User 1 adds a sticky note
    await page1.click('[data-testid="add-sticky-note"]');
    await page1.fill('[data-testid="sticky-note-text"]', 'Hello from User 1');

    // User 2 should see the sticky note (real-time sync)
    await expect(page2.locator('text=Hello from User 1')).toBeVisible({ timeout: 5000 });
  });
});
```

---

## 🗺️ ROADMAP DÉTAILLÉE

### Sprint 1-2: MVP Core (4 semaines)
**Objectif**: Application fonctionnelle localement

**Backend**:
- [x] Infrastructure (Docker, DB, migrations)
- [ ] Auth module complet (signup, login, JWT, OAuth2)
- [ ] Users module
- [ ] Projects module (CRUD)
- [ ] Boards module (save/load Yjs snapshot)
- [ ] Assets module (upload S3 presigned URLs)
- [ ] Tokens module (mock, pas de Stripe encore)
- [ ] Health checks

**Frontend**:
- [ ] Setup Next.js 14 + TailwindCSS
- [ ] Auth pages (login, signup)
- [ ] Projects list page
- [ ] Whiteboard page basique (upload + move + resize images)
- [ ] Toolbar (select, upload, sticky notes)
- [ ] Token meter display

**Real-time**:
- [ ] Y-WebSocket server basique
- [ ] Yjs integration frontend (sync canvas)

**Tests**:
- [ ] Tests unitaires backend (auth, projects, tokens)
- [ ] Tests E2E basiques (signup, login, create project)

**Critères d'acceptation**:
- ✅ User peut signup/login
- ✅ User peut créer un projet
- ✅ User peut uploader une image et la déplacer sur le whiteboard
- ✅ Board state est sauvegardé et restauré au refresh
- ✅ Token balance affiché (mock)

---

### Sprint 3-4: Real-time & AI Integration (4 semaines)
**Objectif**: Collaboration temps-réel + AI mock fonctionnel

**Backend**:
- [ ] Agent module (planner, selector, estimator)
- [ ] AI jobs queue (BullMQ)
- [ ] Token deduction transactionnel (ACID)
- [ ] Collaborators module (share, permissions)
- [ ] Billing module (Stripe test mode)

**Frontend**:
- [ ] Real-time collaboration (multi-users editing)
- [ ] Cursors awareness (Yjs awareness)
- [ ] AI prompt input
- [ ] Token purchase flow (Stripe Checkout)
- [ ] Asset library panel
- [ ] Layer panel

**AI Service**:
- [ ] Logo generator (mock d'abord, puis API externe)
- [ ] Social post generator (mock)
- [ ] Workers BullMQ

**Tests**:
- [ ] Tests real-time (convergence CRDT)
- [ ] Tests token deduction (race conditions)
- [ ] Tests E2E AI generation

**Critères d'acceptation**:
- ✅ Deux users éditent simultanément sans conflits
- ✅ User peut demander génération AI et voir résultat sur board
- ✅ Tokens sont déduits correctement et atomiquement
- ✅ User peut acheter tokens via Stripe (test mode)
- ✅ User peut inviter collaborateur (editor/viewer)

---

### Sprint 5-6: Production Hardening (3 semaines)
**Objectif**: Déploiement production-ready

**DevOps**:
- [ ] Kubernetes manifests (deployments, services, ingress)
- [ ] Helm charts
- [ ] CI/CD complet (staging + production)
- [ ] Monitoring (Sentry, Prometheus, Grafana dashboards)
- [ ] Alerting
- [ ] Secrets management (Vault)
- [ ] CDN setup (CloudFront)

**Backend**:
- [ ] Rate limiting avancé (par user, par IP)
- [ ] Audit logs
- [ ] Email notifications (welcome, invites, receipts)
- [ ] GDPR compliance (export data, delete account)

**Frontend**:
- [ ] Responsive mobile UI
- [ ] Performance optimizations (code splitting, lazy loading)
- [ ] Error boundaries
- [ ] Offline indicators

**Tests**:
- [ ] Load testing (k6)
- [ ] Security audit
- [ ] Coverage > 80%

**Critères d'acceptation**:
- ✅ Application déployée sur staging auto (PR merge)
- ✅ Zero-downtime deployments
- ✅ Monitoring dashboards opérationnels
- ✅ P95 latency < 500ms
- ✅ Error rate < 0.1%

---

### v1.0 Release (Q2 2025)
- ✅ All MVP features production-ready
- ✅ Documentation complète (API, architecture, guides)
- ✅ Onboarding tutorial
- ✅ Billing & invoicing
- ✅ Support portal

---

### v1.5 (Q3 2025)
**Nouvelles fonctionnalités**:
- [ ] Brand library (save colors, fonts, guidelines)
- [ ] Templates marketplace
- [ ] Figma import
- [ ] Canva export
- [ ] Video mockups
- [ ] AI fine-tuning (custom brand style)
- [ ] MFA
- [ ] Webhooks API

---

### Enterprise (Q4 2025)
- [ ] SSO SAML
- [ ] Advanced audit logs
- [ ] Custom domain white-labeling
- [ ] On-premise deployment option
- [ ] SLA 99.9% uptime
- [ ] Dedicated support
- [ ] Custom contracts

---

## 📝 NEXT STEPS (Actions Immédiates)

### Pour Démarrer le Développement

1. **Setup local**:
   ```bash
   cd pixora
   make setup
   # Edit .env files with your API keys
   make dev
   ```

2. **Implémenter Auth Module** (priorité haute):
   - Créer auth.controller.ts
   - Créer auth.service.ts (bcrypt password hashing)
   - Créer JWT strategies
   - Tester avec Postman/curl

3. **Implémenter Projects Module**:
   - Créer entity TypeORM
   - CRUD endpoints
   - Tests unitaires

4. **Frontend Setup**:
   - Initialiser Next.js 14
   - Setup Tailwind + shadcn/ui
   - Pages auth (login/signup)

5. **Whiteboard MVP**:
   - React Konva setup
   - Upload image
   - Drag/resize
   - Save/load

6. **Real-time**:
   - Y-WebSocket server
   - Yjs integration frontend

7. **CI/CD**:
   - GitHub Actions workflow
   - Tests auto

---

## 🆘 Ressources & Aide

### Documentation Externe
- **NestJS**: https://docs.nestjs.com
- **Next.js**: https://nextjs.org/docs
- **Yjs**: https://docs.yjs.dev
- **React Konva**: https://konvajs.org/docs/react/
- **TypeORM**: https://typeorm.io
- **BullMQ**: https://docs.bullmq.io
- **Stripe**: https://stripe.com/docs/api

### Support
- **Questions**: Ouvrir une issue GitHub
- **Bugs**: Créer un bug report avec reproduction steps
- **Features**: Proposer dans Discussions

---

**Bonne implémentation! 🚀**

Si vous avez besoin d'aide pour implémenter un module spécifique, demandez et je fournirai le code complet avec tests.
