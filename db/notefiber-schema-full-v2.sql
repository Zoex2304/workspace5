--
-- PostgreSQL Database Schema for NoteFiber (Full Version - FIXED & COMPATIBLE)
--
-- TUJUAN: Extend dari MVP NoteFiber V1 yang STABIL tanpa mengubah struktur core
-- PRINSIP: Tidak mengubah nama kolom, tipe data, atau constraint yang sudah ada di MVP
-- STRATEGI: Hanya menambahkan tabel baru untuk fitur SaaS (users, subscriptions, relationships)
--
-- KOMPATIBILITAS: 100% dengan notefiberv1.sql (MVP stabil)
--

-- ============================================
-- EXTENSIONS (HARUS DI AWAL!)
-- ============================================

-- Untuk UUIDs unik
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;
-- Untuk hashing password dan enkripsi
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA public;
-- Untuk Semantic Search (Vector Embeddings)
CREATE EXTENSION IF NOT EXISTS "vector" WITH SCHEMA public;

-- ============================================
-- BASE UTILITY FUNCTION
-- ============================================

-- Fungsi untuk update kolom 'updated_at' secara otomatis
CREATE OR REPLACE FUNCTION public.set_current_timestamp_updated_at()
RETURNS TRIGGER AS $$
DECLARE
  _new_value TIMESTAMP WITH TIME ZONE;
BEGIN
  _new_value := now();
  IF NEW.updated_at IS DISTINCT FROM _new_value THEN
    NEW.updated_at = _new_value;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ENUM TYPES (UNTUK FITUR SAAS BARU)
-- ============================================

CREATE TYPE public.user_role AS ENUM ('user', 'admin');
CREATE TYPE public.user_status AS ENUM ('pending', 'active', 'suspended', 'deleted');
CREATE TYPE public.billing_period AS ENUM ('monthly', 'yearly');
CREATE TYPE public.subscription_status AS ENUM ('active', 'inactive', 'canceled', 'trial');
CREATE TYPE public.payment_status AS ENUM ('pending', 'success', 'failed', 'refunded');

-- ============================================
-- 1. CORE MVP TABLES (TIDAK DIUBAH SAMA SEKALI!)
-- ============================================

-- Tabel Chat Session (PERSIS SEPERTI MVP)
CREATE TABLE public.chat_session (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    is_deleted boolean DEFAULT false NOT NULL
);
ALTER TABLE public.chat_session ADD CONSTRAINT chat_session_pkey PRIMARY KEY (id);
CREATE TRIGGER set_public_chat_session_updated_at BEFORE UPDATE ON public.chat_session FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();

-- Tabel Chat Message (PERSIS SEPERTI MVP)
CREATE TABLE public.chat_message (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    role character varying NOT NULL,
    chat character varying NOT NULL,
    chat_session_id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    is_deleted boolean DEFAULT false NOT NULL
);
ALTER TABLE public.chat_message ADD CONSTRAINT chat_message_pkey PRIMARY KEY (id);
ALTER TABLE public.chat_message ADD CONSTRAINT chat_message_chat_session_id_fkey FOREIGN KEY (chat_session_id) REFERENCES public.chat_session(id);

-- Tabel Chat Message Raw (PERSIS SEPERTI MVP)
CREATE TABLE public.chat_message_raw (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    role character varying NOT NULL,
    chat character varying NOT NULL,
    chat_session_id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    is_deleted boolean DEFAULT false NOT NULL
);
ALTER TABLE public.chat_message_raw ADD CONSTRAINT chat_message_raw_pkey PRIMARY KEY (id);
ALTER TABLE public.chat_message_raw ADD CONSTRAINT chat_message_raw_chat_session_id_fkey FOREIGN KEY (chat_session_id) REFERENCES public.chat_session(id);

-- Tabel Notebook (PERSIS SEPERTI MVP)
CREATE TABLE public.notebook (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    parent_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    is_deleted boolean DEFAULT false NOT NULL
);
ALTER TABLE public.notebook ADD CONSTRAINT notebook_pkey PRIMARY KEY (id);
ALTER TABLE public.notebook ADD CONSTRAINT notebook_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.notebook(id);
CREATE TRIGGER set_public_notebook_updated_at BEFORE UPDATE ON public.notebook FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();

-- Tabel Note (PERSIS SEPERTI MVP)
CREATE TABLE public.note (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying NOT NULL,
    content character varying NOT NULL,
    notebook_id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    is_deleted boolean DEFAULT false NOT NULL
);
ALTER TABLE public.note ADD CONSTRAINT note_pkey PRIMARY KEY (id);
ALTER TABLE public.note ADD CONSTRAINT note_notebook_id_fkey FOREIGN KEY (notebook_id) REFERENCES public.notebook(id);
CREATE TRIGGER set_public_note_updated_at BEFORE UPDATE ON public.note FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();

-- Tabel Note Embedding (PERSIS SEPERTI MVP - Vector 3072!)
CREATE TABLE public.note_embedding (
    id uuid NOT NULL,
    document character varying NOT NULL,
    embedding_value public.vector(3072) NOT NULL,
    note_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    is_deleted boolean DEFAULT false
);
ALTER TABLE public.note_embedding ADD CONSTRAINT note_embedding_pkey PRIMARY KEY (id);
ALTER TABLE public.note_embedding ADD CONSTRAINT note_embedding_note_id_fkey FOREIGN KEY (note_id) REFERENCES public.note(id);

-- ============================================
-- 2. NEW TABLES FOR SAAS FEATURES
-- ============================================

-- Tabel Users (TAMBAHAN BARU untuk multi-tenant)
CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email text NOT NULL,
    password_hash text,
    full_name text NOT NULL,
    role public.user_role DEFAULT 'user'::public.user_role NOT NULL,
    status public.user_status DEFAULT 'pending'::public.user_status NOT NULL,
    email_verified boolean DEFAULT false NOT NULL,
    email_verified_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.users ADD CONSTRAINT users_pkey PRIMARY KEY (id);
ALTER TABLE public.users ADD CONSTRAINT users_email_key UNIQUE (email);
CREATE TRIGGER set_public_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();

-- Tabel User Providers (OAuth)
CREATE TABLE public.user_providers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    provider_name text NOT NULL,
    provider_user_id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.user_providers ADD CONSTRAINT user_providers_pkey PRIMARY KEY (id);
ALTER TABLE public.user_providers ADD CONSTRAINT user_providers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE public.user_providers ADD CONSTRAINT user_providers_unique_provider UNIQUE (provider_name, provider_user_id);

-- Tabel Password Reset Tokens
CREATE TABLE public.password_reset_tokens (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    token text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    used boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.password_reset_tokens ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (id);
ALTER TABLE public.password_reset_tokens ADD CONSTRAINT password_reset_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;

-- Tabel Subscription Plans
CREATE TABLE public.subscription_plans (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    description text,
    price numeric(10, 2) NOT NULL,
    billing_period public.billing_period,
    max_notes integer,
    semantic_search_enabled boolean DEFAULT false NOT NULL,
    ai_chat_enabled boolean DEFAULT false NOT NULL
);
ALTER TABLE public.subscription_plans ADD CONSTRAINT subscription_plans_pkey PRIMARY KEY (id);
ALTER TABLE public.subscription_plans ADD CONSTRAINT subscription_plans_slug_key UNIQUE (slug);

-- Tabel User Subscriptions
CREATE TABLE public.user_subscriptions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    plan_id uuid NOT NULL,
    status public.subscription_status DEFAULT 'inactive'::public.subscription_status NOT NULL,
    current_period_start timestamp with time zone NOT NULL,
    current_period_end timestamp with time zone NOT NULL,
    payment_status public.payment_status DEFAULT 'pending'::public.payment_status NOT NULL,
    midtrans_transaction_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.user_subscriptions ADD CONSTRAINT user_subscriptions_pkey PRIMARY KEY (id);
ALTER TABLE public.user_subscriptions ADD CONSTRAINT user_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE public.user_subscriptions ADD CONSTRAINT user_subscriptions_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.subscription_plans(id) ON UPDATE CASCADE ON DELETE RESTRICT;
CREATE TRIGGER set_public_user_subscriptions_updated_at BEFORE UPDATE ON public.user_subscriptions FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();

-- ============================================
-- 3. RELATIONSHIP TABLES (USER OWNERSHIP)
-- ============================================

-- Relasi: User memiliki Notebook
CREATE TABLE public.user_notebooks (
    user_id uuid NOT NULL,
    notebook_id uuid NOT NULL,
    is_owner boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.user_notebooks ADD CONSTRAINT user_notebooks_pkey PRIMARY KEY (user_id, notebook_id);
ALTER TABLE public.user_notebooks ADD CONSTRAINT user_notebooks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE public.user_notebooks ADD CONSTRAINT user_notebooks_notebook_id_fkey FOREIGN KEY (notebook_id) REFERENCES public.notebook(id) ON UPDATE CASCADE ON DELETE CASCADE;

-- Relasi: User memiliki Notes
CREATE TABLE public.user_notes (
    user_id uuid NOT NULL,
    note_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.user_notes ADD CONSTRAINT user_notes_pkey PRIMARY KEY (user_id, note_id);
ALTER TABLE public.user_notes ADD CONSTRAINT user_notes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE public.user_notes ADD CONSTRAINT user_notes_note_id_fkey FOREIGN KEY (note_id) REFERENCES public.note(id) ON UPDATE CASCADE ON DELETE CASCADE;

-- Relasi: User memiliki Chat Sessions
CREATE TABLE public.user_chat_sessions (
    user_id uuid NOT NULL,
    chat_session_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE public.user_chat_sessions ADD CONSTRAINT user_chat_sessions_pkey PRIMARY KEY (user_id, chat_session_id);
ALTER TABLE public.user_chat_sessions ADD CONSTRAINT user_chat_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE public.user_chat_sessions ADD CONSTRAINT user_chat_sessions_chat_session_id_fkey FOREIGN KEY (chat_session_id) REFERENCES public.chat_session(id) ON UPDATE CASCADE ON DELETE CASCADE;

-- ============================================
-- 4. RLS HELPER FUNCTIONS
-- ============================================

-- Fungsi untuk mendapatkan user_id dari context (JWT/Session)
-- DUMMY untuk testing - di production akan membaca dari auth context
CREATE OR REPLACE FUNCTION public.get_current_user_id()
RETURNS uuid AS $$
BEGIN
    -- TODO: Ganti dengan logic membaca JWT/Session di production
    -- Untuk testing, return ID admin
    RETURN '00000000-0000-0000-0000-000000000001'::uuid;
END;
$$ LANGUAGE plpgsql STABLE;

-- Fungsi untuk mendapatkan role user dari context
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS public.user_role AS $$
BEGIN
    -- TODO: Ganti dengan logic membaca JWT/Session di production
    RETURN 'admin'::public.user_role;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- 5. ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS pada tabel core MVP
ALTER TABLE public.notebook ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.note ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.note_embedding ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_session ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_message ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_message_raw ENABLE ROW LEVEL SECURITY;

-- RLS Policy untuk Notebook
CREATE POLICY "Users can manage their notebooks"
ON public.notebook
FOR ALL
USING (EXISTS (
    SELECT 1 FROM public.user_notebooks un 
    WHERE un.notebook_id = notebook.id 
    AND un.user_id = public.get_current_user_id()
))
WITH CHECK (EXISTS (
    SELECT 1 FROM public.user_notebooks un 
    WHERE un.notebook_id = notebook.id 
    AND un.user_id = public.get_current_user_id()
));

-- RLS Policy untuk Note
CREATE POLICY "Users can manage their notes"
ON public.note
FOR ALL
USING (EXISTS (
    SELECT 1 FROM public.user_notes un 
    WHERE un.note_id = note.id 
    AND un.user_id = public.get_current_user_id()
))
WITH CHECK (EXISTS (
    SELECT 1 FROM public.user_notes un 
    WHERE un.note_id = note.id 
    AND un.user_id = public.get_current_user_id()
));

-- RLS Policy untuk Chat Session
CREATE POLICY "Users can manage their chat sessions"
ON public.chat_session
FOR ALL
USING (EXISTS (
    SELECT 1 FROM public.user_chat_sessions ucs 
    WHERE ucs.chat_session_id = chat_session.id 
    AND ucs.user_id = public.get_current_user_id()
))
WITH CHECK (EXISTS (
    SELECT 1 FROM public.user_chat_sessions ucs 
    WHERE ucs.chat_session_id = chat_session.id 
    AND ucs.user_id = public.get_current_user_id()
));

-- RLS Policy untuk Chat Message
CREATE POLICY "Users can read/write their chat messages"
ON public.chat_message
FOR ALL
USING (EXISTS (
    SELECT 1 FROM public.user_chat_sessions ucs 
    WHERE ucs.chat_session_id = chat_message.chat_session_id 
    AND ucs.user_id = public.get_current_user_id()
))
WITH CHECK (EXISTS (
    SELECT 1 FROM public.user_chat_sessions ucs 
    WHERE ucs.chat_session_id = chat_message.chat_session_id 
    AND ucs.user_id = public.get_current_user_id()
));

-- RLS Policy untuk Note Embedding
CREATE POLICY "Users can manage their note embeddings"
ON public.note_embedding
FOR ALL
USING (EXISTS (
    SELECT 1 FROM public.user_notes un
    JOIN public.note n ON un.note_id = n.id
    WHERE n.id = note_embedding.note_id 
    AND un.user_id = public.get_current_user_id()
));

-- ============================================
-- 6. INITIAL DATA & SEEDING
-- ============================================

-- Insert Subscription Plans
INSERT INTO public.subscription_plans (name, slug, description, price, billing_period, max_notes, semantic_search_enabled, ai_chat_enabled) VALUES
('Free Plan', 'free', 'Akses dasar untuk membuat catatan dan pencarian kata kunci.', 0.00, 'monthly', 50, false, false),
('Pro Plan Monthly', 'pro_monthly', 'Fitur penuh dengan Semantic Search dan Chatbot AI.', 9.99, 'monthly', NULL, true, true),
('Pro Plan Yearly', 'pro_yearly', 'Fitur penuh dengan diskon tahunan.', 99.99, 'yearly', NULL, true, true);

-- Insert Admin User
INSERT INTO public.users (id, email, password_hash, full_name, role, status, email_verified, email_verified_at)
VALUES ('00000000-0000-0000-0000-000000000001', 'admin@notefiber.com', crypt('Admin123!', gen_salt('bf')), 'System Administrator', 'admin', 'active', true, now());

-- Insert Demo User
INSERT INTO public.users (id, email, password_hash, full_name, role, status, email_verified, email_verified_at)
VALUES ('00000000-0000-0000-0000-000000000002', 'user@notefiber.com', crypt('User123!', gen_salt('bf')), 'Demo User', 'user', 'active', true, now());

-- ============================================
-- 7. VIEWS FOR CONVENIENCE
-- ============================================

-- View untuk Semantic Search (compatible dengan MVP structure)
CREATE VIEW public.semantic_searchable_notes AS
SELECT
    n.id AS note_id,
    n.title,
    n.content,
    ne.embedding_value AS embedding,
    un.user_id
FROM
    public.note n
JOIN
    public.note_embedding ne ON n.id = ne.note_id
JOIN
    public.user_notes un ON n.id = un.note_id
WHERE
    n.is_deleted = false;

-- View untuk Payment History
CREATE VIEW public.user_payment_history AS
SELECT
    us.user_id,
    u.full_name,
    sp.name AS plan_name,
    sp.price,
    us.payment_status,
    us.midtrans_transaction_id,
    us.created_at AS payment_date
FROM
    public.user_subscriptions us
JOIN
    public.users u ON us.user_id = u.id
JOIN
    public.subscription_plans sp ON us.plan_id = sp.id
ORDER BY
    payment_date DESC;

-- ============================================
-- 8. MATERIALIZED VIEWS (ADMIN DASHBOARD)
-- ============================================

-- MV untuk User Performance Summary
CREATE MATERIALIZED VIEW public.admin_user_performance_summary AS
SELECT
    u.id AS user_id,
    u.email,
    u.full_name,
    u.status,
    u.created_at AS join_date,
    (SELECT COUNT(un.note_id) FROM public.user_notes un WHERE un.user_id = u.id) AS total_notes,
    (SELECT COUNT(ucs.chat_session_id) FROM public.user_chat_sessions ucs WHERE ucs.user_id = u.id) AS total_chats,
    COALESCE(sub.status, 'inactive'::public.subscription_status) AS subscription_status,
    COALESCE(sp.name, 'N/A') AS current_plan_name
FROM
    public.users u
LEFT JOIN
    public.user_subscriptions sub ON u.id = sub.user_id AND sub.status = 'active'
LEFT JOIN
    public.subscription_plans sp ON sub.plan_id = sp.id
WHERE
    u.role = 'user'
ORDER BY
    u.created_at DESC;

CREATE UNIQUE INDEX ON public.admin_user_performance_summary (user_id);
CREATE INDEX ON public.admin_user_performance_summary (subscription_status);
CREATE INDEX ON public.admin_user_performance_summary (full_name);

-- MV untuk Payment Audit
CREATE MATERIALIZED VIEW public.admin_payment_audit_view AS
SELECT
    us.id AS subscription_id,
    us.midtrans_transaction_id,
    u.full_name AS user_name,
    u.email AS user_email,
    sp.name AS plan_name,
    us.payment_status,
    sp.price,
    us.current_period_start,
    us.current_period_end,
    us.created_at AS transaction_date
FROM
    public.user_subscriptions us
JOIN
    public.users u ON us.user_id = u.id
JOIN
    public.subscription_plans sp ON us.plan_id = sp.id
ORDER BY
    us.created_at DESC;

CREATE UNIQUE INDEX ON public.admin_payment_audit_view (subscription_id);
CREATE INDEX ON public.admin_payment_audit_view (midtrans_transaction_id);
CREATE INDEX ON public.admin_payment_audit_view (payment_status);

-- ============================================
-- SELESAI - SCHEMA READY TO USE
-- ============================================