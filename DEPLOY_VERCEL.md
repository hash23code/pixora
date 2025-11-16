# 🚀 Déploiement Pixora sur Vercel + Supabase

## Guide Complet de Déploiement

Ce guide vous permet de déployer Pixora en production en **moins de 30 minutes**.

---

## 📋 Prérequis

- Compte Vercel (gratuit): https://vercel.com
- Compte Supabase (gratuit): https://supabase.com
- Compte Stripe (test mode gratuit): https://stripe.com
- Compte Anthropic (API key): https://anthropic.com
- Compte Replicate (optionnel): https://replicate.com

---

## PARTIE 1: Configuration Supabase (10 min)

### 1.1 Créer un Projet Supabase

1. Allez sur https://supabase.com/dashboard
2. Cliquez "New Project"
3. Nom: `pixora-production`
4. Région: Choisissez la plus proche de vos utilisateurs (ex: `eu-west-1`)
5. Database Password: Générez un mot de passe fort (sauvegardez-le!)
6. Cliquez "Create new project"
7. Attendez ~2 minutes que le projet soit prêt

### 1.2 Récupérer les Credentials

Une fois le projet créé:

1. Allez dans **Settings** → **API**
2. Copiez ces valeurs (vous en aurez besoin):
   ```
   Project URL: https://xxxxx.supabase.co
   anon public key: eyJhbGc...
   service_role key: eyJhbGc... (GARDEZ SECRET!)
   ```

### 1.3 Exécuter les Migrations SQL

1. Dans Supabase Dashboard, allez dans **SQL Editor**
2. Cliquez "New query"
3. Copiez-collez le contenu de `supabase/migrations/20250116_initial_schema.sql`
4. Cliquez "Run" (en bas à droite)
5. Vérifiez qu'il n'y a pas d'erreurs (devrait afficher "Success")

Vérification:
- Allez dans **Database** → **Tables**
- Vous devriez voir: `profiles`, `projects`, `boards`, `assets`, etc.

### 1.4 Configurer Storage (Buckets)

1. Allez dans **Storage**
2. Créez 2 buckets:

**Bucket 1: `assets`**
- Nom: `assets`
- Public: ✅ Oui
- File size limit: 50 MB
- Allowed MIME types: `image/*,video/*,audio/*`

**Bucket 2: `ai-outputs`**
- Nom: `ai-outputs`
- Public: ✅ Oui
- File size limit: 100 MB
- Allowed MIME types: `image/*,video/*,audio/*`

### 1.5 Activer Authentication Providers

1. Allez dans **Authentication** → **Providers**
2. Activez:
   - [x] **Email** (déjà activé)
   - [x] **Google** (optionnel, pour OAuth)
   - [x] **GitHub** (optionnel)

**Pour Google OAuth** (optionnel):
1. Créez un projet sur https://console.cloud.google.com
2. Activez "Google+ API"
3. Créez des credentials OAuth 2.0
4. Authorized redirect URIs:
   ```
   https://xxxxx.supabase.co/auth/v1/callback
   ```
5. Copiez Client ID et Client Secret dans Supabase

---

## PARTIE 2: Configuration Stripe (5 min)

### 2.1 Créer un Compte Stripe

1. Allez sur https://stripe.com
2. Créez un compte (gratuit en mode test)
3. Activez **Test Mode** (toggle en haut à droite)

### 2.2 Récupérer les API Keys

1. Allez dans **Developers** → **API keys**
2. Copiez:
   ```
   Publishable key: pk_test_...
   Secret key: sk_test_...
   ```

### 2.3 Créer les Products (Token Packages)

1. Allez dans **Products** → **Add product**

**Product 1: Starter Pack**
- Name: `Pixora Starter - 100 Tokens`
- Price: $9.99 (one-time)
- Metadata:
  - `tokens`: `100`
  - `package`: `starter`

**Product 2: Pro Pack**
- Name: `Pixora Pro - 500 Tokens`
- Price: $39.99
- Metadata:
  - `tokens`: `500`
  - `package`: `pro`

**Product 3: Business Pack**
- Name: `Pixora Business - 2000 Tokens`
- Price: $129.99
- Metadata:
  - `tokens`: `2000`
  - `package`: `business`

Copiez les Price IDs (commencent par `price_...`)

### 2.4 Configurer Webhooks

1. Allez dans **Developers** → **Webhooks**
2. Cliquez "Add endpoint"
3. Endpoint URL: `https://votre-domaine.vercel.app/api/webhooks/stripe` (on configurera après déploiement)
4. Events à écouter:
   - `checkout.session.completed`
   - `invoice.paid`
   - `invoice.payment_failed`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
5. Sauvegardez le **Signing secret** (commence par `whsec_...`)

---

## PARTIE 3: API Keys Externes (5 min)

### 3.1 Anthropic Claude

1. Allez sur https://console.anthropic.com
2. Créez une API key
3. Copiez: `sk-ant-api03-...`

### 3.2 Replicate (pour AI models)

1. Allez sur https://replicate.com
2. Sign up
3. **Account** → **API tokens**
4. Créez un token
5. Copiez: `r8_...`

### 3.3 ElevenLabs (pour voix-off)

1. Allez sur https://elevenlabs.io
2. Sign up (plan gratuit: 10k chars/mois)
3. **Profile** → **API Key**
4. Copiez votre API key

### 3.4 (Optionnel) Autres Providers

- **Stability AI**: https://platform.stability.ai
- **OpenAI**: https://platform.openai.com
- **Runway**: https://runwayml.com

---

## PARTIE 4: Déploiement sur Vercel (10 min)

### 4.1 Préparer le Repository

1. Assurez-vous que votre code est sur GitHub
2. Commitez tous les changements:
   ```bash
   git add .
   git commit -m "feat: ready for production deployment"
   git push origin main
   ```

### 4.2 Importer sur Vercel

1. Allez sur https://vercel.com/dashboard
2. Cliquez "Add New..." → "Project"
3. Sélectionnez votre repo GitHub `pixora`
4. Framework Preset: **Next.js** (auto-détecté)
5. Root Directory: `frontend`
6. **NE CLIQUEZ PAS ENCORE SUR DEPLOY!**

### 4.3 Configurer les Environment Variables

Dans Vercel, section "Environment Variables", ajoutez:

**Frontend (Publiques)**:
```
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
NEXT_PUBLIC_APP_URL=https://votre-projet.vercel.app
```

**Backend (Privées)**:
```
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc... (service_role key!)
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_... (on ajoutera après)
ANTHROPIC_API_KEY=sk-ant-api03-...
REPLICATE_API_TOKEN=r8_...
ELEVEN_LABS_API_KEY=votre-key
STABILITY_API_KEY=sk-... (optionnel)
OPENAI_API_KEY=sk-... (optionnel)
```

### 4.4 Déployer!

1. Cliquez "Deploy"
2. Attendez 2-3 minutes
3. Une fois terminé, notez votre URL: `https://votre-projet.vercel.app`

### 4.5 Configurer le Webhook Stripe

Maintenant que vous avez votre URL Vercel:

1. Retournez sur Stripe Dashboard → **Webhooks**
2. Modifiez l'endpoint créé plus tôt
3. URL: `https://votre-projet.vercel.app/api/webhooks/stripe`
4. Sauvegardez

Puis dans Vercel:
1. **Settings** → **Environment Variables**
2. Ajoutez `STRIPE_WEBHOOK_SECRET=whsec_...`
3. Redéployez: **Deployments** → **...** → **Redeploy**

---

## PARTIE 5: Vérification & Tests (5 min)

### 5.1 Vérifier le Déploiement

1. Visitez `https://votre-projet.vercel.app`
2. Vous devriez voir la landing page

### 5.2 Tester Signup/Login

1. Cliquez "Sign Up"
2. Créez un compte avec votre email
3. Vérifiez que vous recevez l'email de confirmation Supabase
4. Confirmez votre email
5. Connectez-vous

### 5.3 Tester la Création de Projet

1. Une fois connecté, allez sur `/dashboard`
2. Créez un nouveau projet
3. Vérifiez qu'il apparaît dans Supabase:
   - Dashboard → **Table Editor** → `projects`

### 5.4 Tester le Token System

1. Dans le dashboard, vérifiez votre balance de tokens (devrait être 100)
2. Vérifiez dans Supabase → `tokens_balance`

### 5.5 Tester une Génération AI (optionnel)

**ATTENTION**: Cela consommera des crédits API!

1. Créez un projet
2. Essayez de générer un logo
3. Vérifiez les logs Vercel: **Deployments** → **Function Logs**

---

## PARTIE 6: Configuration Post-Déploiement

### 6.1 Custom Domain (optionnel)

1. Achetez un domaine (ex: `pixora.com`)
2. Dans Vercel: **Settings** → **Domains**
3. Ajoutez votre domaine
4. Configurez les DNS selon les instructions Vercel

### 6.2 Monitoring

**Vercel Analytics**:
- Activez dans **Analytics** (gratuit pour usage basique)

**Supabase Monitoring**:
- Dashboard → **Database** → **Reports**
- Surveillez: Queries, Connections, Storage usage

**Stripe Dashboard**:
- Surveillez les transactions dans **Payments**

### 6.3 Rate Limits & Quotas

**Supabase Free Tier**:
- 500 MB Database
- 1 GB File Storage
- 2 GB Bandwidth/mois
- 50k MAU (monthly active users)

**Vercel Free Tier (Hobby)**:
- 100 GB Bandwidth/mois
- Serverless Functions: 100 GB-hours
- Unlimited Deployments

**Upgrade si nécessaire**:
- Supabase Pro: $25/mois
- Vercel Pro: $20/mois/utilisateur

---

## PARTIE 7: Rollback & Debugging

### 7.1 Rollback Deployment

Si un déploiement casse quelque chose:

1. Vercel Dashboard → **Deployments**
2. Trouvez le dernier déploiement qui marchait
3. Cliquez **...** → **Promote to Production**

### 7.2 Voir les Logs

**Vercel Function Logs**:
```bash
vercel logs votre-projet-url
```

Ou dans Dashboard → **Deployments** → Select deployment → **Function Logs**

**Supabase Logs**:
- Dashboard → **Logs** → **Postgres Logs**

### 7.3 Erreurs Communes

**"Supabase connection failed"**:
- Vérifiez `NEXT_PUBLIC_SUPABASE_URL` et `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- Vérifiez que RLS policies sont correctes

**"Stripe webhook signature invalid"**:
- Vérifiez `STRIPE_WEBHOOK_SECRET`
- Vérifiez que l'endpoint URL est correct

**"AI generation failed"**:
- Vérifiez les API keys (Anthropic, Replicate, etc.)
- Vérifiez les quotas API (peut-être dépassés)

---

## PARTIE 8: Aller en Production (Checklist)

Avant de lancer publiquement:

- [ ] Passer Stripe en **Live Mode** (désactiver Test Mode)
- [ ] Créer les products Stripe en live mode
- [ ] Mettre à jour `STRIPE_SECRET_KEY` et `STRIPE_PUBLISHABLE_KEY` (live keys)
- [ ] Configurer un domaine custom
- [ ] Activer HTTPS (auto avec Vercel)
- [ ] Ajouter Privacy Policy & Terms of Service
- [ ] Configurer Google Analytics (optionnel)
- [ ] Tester tous les flows critiques:
  - [ ] Signup/Login
  - [ ] Create project
  - [ ] Generate AI asset
  - [ ] Purchase tokens
  - [ ] Collaboration (invite user)
- [ ] Setup alerting (Vercel Alerts, Sentry)
- [ ] Backup Supabase:
  - Settings → **Backups** → Enable daily backups

---

## 🎉 Vous êtes Live!

Votre plateforme Pixora est maintenant en production sur:
- **Frontend**: https://votre-projet.vercel.app
- **Database**: Supabase (managed)
- **Storage**: Supabase Storage
- **Payments**: Stripe

### Prochaines Étapes

1. **Marketing**: Créez une landing page attractive
2. **Analytics**: Surveillez les métriques (signups, conversions)
3. **Feedback**: Collectez feedback utilisateurs
4. **Iterate**: Ajoutez features basées sur demande

### Support

- **Docs Vercel**: https://vercel.com/docs
- **Docs Supabase**: https://supabase.com/docs
- **Docs Stripe**: https://stripe.com/docs

### Coûts Estimés (Production)

**0-100 users**:
- Supabase Free: $0
- Vercel Hobby: $0
- Stripe: 2.9% + $0.30/transaction
- AI APIs: ~$50-100/mois
- **Total: $50-100/mois**

**100-1000 users**:
- Supabase Pro: $25
- Vercel Pro: $20
- AI APIs: ~$200-500/mois
- **Total: $245-545/mois**

**1000+ users**: Upgrade to Team/Enterprise plans

---

**Questions? Problèmes? Créez une issue sur GitHub!**
