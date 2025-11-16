# Supabase Configuration Guide

## 1. Create Supabase Project

1. Go to https://supabase.com
2. Create new project: `pixora-production`
3. Choose region (closest to your users)
4. Save these credentials:
   ```
   NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key (PRIVATE!)
   ```

## 2. Enable Authentication Providers

**Supabase Dashboard → Authentication → Providers**

Enable:
- [x] Email (default)
- [x] Google OAuth
- [x] GitHub OAuth
- [x] Magic Link

**Google OAuth Setup**:
```
Authorized redirect URIs:
https://your-project.supabase.co/auth/v1/callback
http://localhost:3000/auth/callback
```

## 3. Enable Storage

**Supabase Dashboard → Storage → Create bucket**

Create buckets:
- `assets` (public) - User-generated assets
- `ai-outputs` (public) - AI-generated content
- `temp-uploads` (private, auto-delete after 24h)

**Storage Policies** (RLS):
```sql
-- Allow authenticated users to upload to their folder
CREATE POLICY "Users can upload to own folder"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'assets' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow public read access
CREATE POLICY "Public read access"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id IN ('assets', 'ai-outputs'));
```

## 4. Run Migrations

Copy SQL from `supabase/migrations/` folder and execute in Supabase SQL Editor.

## 5. Setup Environment Variables

**Frontend (.env.local)**:
```bash
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

**Backend (.env)**:
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

## 6. Supabase vs PostgreSQL Differences

**Key Changes**:
- ✅ Use `uuid_generate_v4()` instead of `uuid-ossp` extension (already enabled)
- ✅ Use `auth.users` table (managed by Supabase) for authentication
- ✅ Use Row Level Security (RLS) policies for access control
- ✅ Use Storage API instead of S3 (simpler, included)
- ✅ Use Realtime subscriptions instead of custom WebSocket server

## 7. Database Schema Adaptations

**Link to Supabase Auth**:
```sql
-- Instead of storing password_hash in users table,
-- reference auth.users table
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT,
  last_name TEXT,
  avatar TEXT,
  role TEXT DEFAULT 'user',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

## 8. Testing Connection

```bash
# Install Supabase CLI
npm install -g supabase

# Link to your project
supabase link --project-ref your-project-ref

# Pull schema
supabase db pull

# Run migrations locally
supabase db reset
```

## 9. Monitoring

**Supabase Dashboard**:
- Database: Monitor queries, table sizes
- Auth: Track signups, sessions
- Storage: Check usage, bandwidth
- Logs: Real-time logs for debugging

## 10. Costs

**Free Tier Limits**:
- 500 MB database
- 1 GB file storage
- 2 GB bandwidth
- 50k monthly active users

**Upgrade when**:
- > 500 users → Pro ($25/mo)
- > 5k users → Team ($599/mo)
- Enterprise → Custom pricing
