--
-- PostgreSQL database dump
--

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

-- Started on 2025-11-05 09:44:03

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Set search path
SET search_path = public, pg_catalog;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

-- CREATE SCHEMA public;

-- ALTER SCHEMA public OWNER TO pg_database_owner;

-- COMMENT ON SCHEMA public IS 'standard public schema';

SET default_tablespace = '';
SET default_table_access_method = heap;

-- ============================================
-- EXTENSIONS (HARUS DI AWAL!)
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "vector" WITH SCHEMA public;

-- ============================================
-- ENUM TYPES
-- ============================================

CREATE TYPE public.user_role AS ENUM ('admin', 'user');
CREATE TYPE public.user_status AS ENUM ('active', 'inactive', 'suspended', 'deleted');
CREATE TYPE public.subscription_tier AS ENUM ('free', 'pro', 'enterprise');
CREATE TYPE public.subscription_status AS ENUM ('active', 'cancelled', 'expired', 'pending');
CREATE TYPE public.payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE public.payment_method AS ENUM ('credit_card', 'debit_card', 'paypal', 'bank_transfer', 'other');
CREATE TYPE public.log_level AS ENUM ('info', 'warning', 'error', 'critical', 'debug');
CREATE TYPE public.search_type AS ENUM ('regular', 'semantic');

-- ============================================
-- MVP TABLES (ORIGINAL - TIDAK DIUBAH)
-- ============================================

--
-- Name: chat_message; Type: TABLE; Schema: public; Owner: postgres
--

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

ALTER TABLE public.chat_message OWNER TO postgres;

--
-- Name: chat_message_raw; Type: TABLE; Schema: public; Owner: postgres
--

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

ALTER TABLE public.chat_message_raw OWNER TO postgres;

--
-- Name: chat_session; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_session (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    is_deleted boolean DEFAULT false NOT NULL
);

ALTER TABLE public.chat_session OWNER TO postgres;

--
-- Name: note; Type: TABLE; Schema: public; Owner: postgres
--

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

ALTER TABLE public.note OWNER TO postgres;

--
-- Name: note_embedding; Type: TABLE; Schema: public; Owner: postgres
--

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

ALTER TABLE public.note_embedding OWNER TO postgres;

--
-- Name: notebook; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notebook (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    parent_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    is_deleted boolean DEFAULT false NOT NULL
);

ALTER TABLE public.notebook OWNER TO postgres;

-- ============================================
-- NEW TABLES FOR SAAS FEATURES
-- ============================================

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    full_name character varying(255) NOT NULL,
    role public.user_role DEFAULT 'user'::public.user_role NOT NULL,
    status public.user_status DEFAULT 'active'::public.user_status NOT NULL,
    avatar_url character varying(500),
    phone_number character varying(20),
    email_verified boolean DEFAULT false NOT NULL,
    email_verified_at timestamp with time zone,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    is_deleted boolean DEFAULT false NOT NULL
);

ALTER TABLE public.users OWNER TO postgres;

--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    bio text,
    company character varying(255),
    job_title character varying(255),
    location character varying(255),
    website character varying(500),
    timezone character varying(100) DEFAULT 'UTC'::character varying,
    language character varying(10) DEFAULT 'en'::character varying,
    theme character varying(20) DEFAULT 'light'::character varying,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);

ALTER TABLE public.user_profiles OWNER TO postgres;

--
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.password_reset_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token character varying(255) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    used boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.password_reset_tokens OWNER TO postgres;

--
-- Name: email_verification_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_verification_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token character varying(255) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    used boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.email_verification_tokens OWNER TO postgres;

--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token character varying(500) NOT NULL,
    ip_address inet,
    user_agent text,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.user_sessions OWNER TO postgres;

--
-- Name: subscription_plans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscription_plans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    tier public.subscription_tier NOT NULL,
    description text,
    price numeric(10,2) NOT NULL,
    currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
    billing_period character varying(20) NOT NULL,
    features jsonb,
    max_notes integer,
    max_notebooks integer,
    semantic_search_enabled boolean DEFAULT false NOT NULL,
    ai_chat_enabled boolean DEFAULT false NOT NULL,
    max_ai_queries_per_month integer,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);

ALTER TABLE public.subscription_plans OWNER TO postgres;

--
-- Name: user_subscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    plan_id uuid NOT NULL,
    status public.subscription_status DEFAULT 'active'::public.subscription_status NOT NULL,
    start_date timestamp with time zone DEFAULT now() NOT NULL,
    end_date timestamp with time zone,
    auto_renew boolean DEFAULT true NOT NULL,
    cancelled_at timestamp with time zone,
    cancellation_reason text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);

ALTER TABLE public.user_subscriptions OWNER TO postgres;

--
-- Name: payment_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment_transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    subscription_id uuid,
    amount numeric(10,2) NOT NULL,
    currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
    status public.payment_status DEFAULT 'pending'::public.payment_status NOT NULL,
    payment_method public.payment_method NOT NULL,
    payment_gateway character varying(50),
    gateway_transaction_id character varying(255),
    gateway_response jsonb,
    description text,
    processed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);

ALTER TABLE public.payment_transactions OWNER TO postgres;

--
-- Name: user_notebooks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_notebooks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    notebook_id uuid NOT NULL,
    is_owner boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.user_notebooks OWNER TO postgres;

--
-- Name: user_notes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_notes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    note_id uuid NOT NULL,
    is_owner boolean DEFAULT true NOT NULL,
    is_favorite boolean DEFAULT false NOT NULL,
    tags character varying(255)[],
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.user_notes OWNER TO postgres;

--
-- Name: user_chat_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_chat_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    chat_session_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.user_chat_sessions OWNER TO postgres;

--
-- Name: ai_usage_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ai_usage_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    search_type public.search_type NOT NULL,
    query text NOT NULL,
    tokens_used integer,
    response_time_ms integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.ai_usage_log OWNER TO postgres;

--
-- Name: search_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.search_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    query text NOT NULL,
    search_type public.search_type NOT NULL,
    results_count integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.search_history OWNER TO postgres;

--
-- Name: system_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.system_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    level public.log_level NOT NULL,
    message text NOT NULL,
    source character varying(255),
    user_id uuid,
    ip_address inet,
    user_agent text,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.system_logs OWNER TO postgres;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    action character varying(255) NOT NULL,
    entity_type character varying(100) NOT NULL,
    entity_id uuid,
    old_values jsonb,
    new_values jsonb,
    ip_address inet,
    user_agent text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- Name: admin_dashboard_stats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_dashboard_stats (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    total_users integer DEFAULT 0,
    active_users integer DEFAULT 0,
    total_subscriptions integer DEFAULT 0,
    active_subscriptions integer DEFAULT 0,
    total_revenue numeric(15,2) DEFAULT 0,
    total_notes integer DEFAULT 0,
    total_notebooks integer DEFAULT 0,
    total_ai_queries integer DEFAULT 0,
    stats_date date NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone
);

ALTER TABLE public.admin_dashboard_stats OWNER TO postgres;

--
-- Name: user_growth_stats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_growth_stats (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    date date NOT NULL,
    new_users integer DEFAULT 0,
    deleted_users integer DEFAULT 0,
    active_users integer DEFAULT 0,
    total_users integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.user_growth_stats OWNER TO postgres;

-- ============================================
-- PRIMARY KEYS (MVP)
-- ============================================

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.chat_message_raw
    ADD CONSTRAINT chat_message_raw_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.chat_session
    ADD CONSTRAINT chat_session_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.note_embedding
    ADD CONSTRAINT note_embedding_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.note
    ADD CONSTRAINT note_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.notebook
    ADD CONSTRAINT notebook_pkey PRIMARY KEY (id);

-- ============================================
-- PRIMARY KEYS (NEW TABLES)
-- ============================================

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_user_id_key UNIQUE (user_id);

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_token_key UNIQUE (token);

ALTER TABLE ONLY public.email_verification_tokens
    ADD CONSTRAINT email_verification_tokens_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.email_verification_tokens
    ADD CONSTRAINT email_verification_tokens_token_key UNIQUE (token);

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_token_key UNIQUE (token);

ALTER TABLE ONLY public.subscription_plans
    ADD CONSTRAINT subscription_plans_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.user_subscriptions
    ADD CONSTRAINT user_subscriptions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.payment_transactions
    ADD CONSTRAINT payment_transactions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.user_notebooks
    ADD CONSTRAINT user_notebooks_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.user_notebooks
    ADD CONSTRAINT user_notebooks_user_id_notebook_id_key UNIQUE (user_id, notebook_id);

ALTER TABLE ONLY public.user_notes
    ADD CONSTRAINT user_notes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.user_notes
    ADD CONSTRAINT user_notes_user_id_note_id_key UNIQUE (user_id, note_id);

ALTER TABLE ONLY public.user_chat_sessions
    ADD CONSTRAINT user_chat_sessions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.user_chat_sessions
    ADD CONSTRAINT user_chat_sessions_user_id_chat_session_id_key UNIQUE (user_id, chat_session_id);

ALTER TABLE ONLY public.ai_usage_log
    ADD CONSTRAINT ai_usage_log_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.search_history
    ADD CONSTRAINT search_history_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.system_logs
    ADD CONSTRAINT system_logs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.admin_dashboard_stats
    ADD CONSTRAINT admin_dashboard_stats_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.admin_dashboard_stats
    ADD CONSTRAINT admin_dashboard_stats_stats_date_key UNIQUE (stats_date);

ALTER TABLE ONLY public.user_growth_stats
    ADD CONSTRAINT user_growth_stats_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.user_growth_stats
    ADD CONSTRAINT user_growth_stats_date_key UNIQUE (date);

-- ============================================
-- INDEXES (NEW TABLES)
-- ============================================

CREATE INDEX idx_users_email ON public.users USING btree (email);
CREATE INDEX idx_users_role ON public.users USING btree (role);
CREATE INDEX idx_users_status ON public.users USING btree (status);
CREATE INDEX idx_users_created_at ON public.users USING btree (created_at);

CREATE INDEX idx_user_profiles_user_id ON public.user_profiles USING btree (user_id);

CREATE INDEX idx_password_reset_tokens_token ON public.password_reset_tokens USING btree (token);
CREATE INDEX idx_password_reset_tokens_user_id ON public.password_reset_tokens USING btree (user_id);

CREATE INDEX idx_email_verification_tokens_token ON public.email_verification_tokens USING btree (token);
CREATE INDEX idx_email_verification_tokens_user_id ON public.email_verification_tokens USING btree (user_id);

CREATE INDEX idx_user_sessions_user_id ON public.user_sessions USING btree (user_id);
CREATE INDEX idx_user_sessions_token ON public.user_sessions USING btree (token);
CREATE INDEX idx_user_sessions_expires_at ON public.user_sessions USING btree (expires_at);

CREATE INDEX idx_subscription_plans_tier ON public.subscription_plans USING btree (tier);
CREATE INDEX idx_subscription_plans_is_active ON public.subscription_plans USING btree (is_active);

CREATE INDEX idx_user_subscriptions_user_id ON public.user_subscriptions USING btree (user_id);
CREATE INDEX idx_user_subscriptions_status ON public.user_subscriptions USING btree (status);
CREATE INDEX idx_user_subscriptions_end_date ON public.user_subscriptions USING btree (end_date);

CREATE INDEX idx_payment_transactions_user_id ON public.payment_transactions USING btree (user_id);
CREATE INDEX idx_payment_transactions_subscription_id ON public.payment_transactions USING btree (subscription_id);
CREATE INDEX idx_payment_transactions_status ON public.payment_transactions USING btree (status);
CREATE INDEX idx_payment_transactions_created_at ON public.payment_transactions USING btree (created_at);
CREATE INDEX idx_payment_transactions_gateway_transaction_id ON public.payment_transactions USING btree (gateway_transaction_id);

CREATE INDEX idx_user_notebooks_user_id ON public.user_notebooks USING btree (user_id);
CREATE INDEX idx_user_notebooks_notebook_id ON public.user_notebooks USING btree (notebook_id);

CREATE INDEX idx_user_notes_user_id ON public.user_notes USING btree (user_id);
CREATE INDEX idx_user_notes_note_id ON public.user_notes USING btree (note_id);
CREATE INDEX idx_user_notes_is_favorite ON public.user_notes USING btree (is_favorite);
CREATE INDEX idx_user_notes_tags ON public.user_notes USING gin (tags);

CREATE INDEX idx_user_chat_sessions_user_id ON public.user_chat_sessions USING btree (user_id);
CREATE INDEX idx_user_chat_sessions_chat_session_id ON public.user_chat_sessions USING btree (chat_session_id);

CREATE INDEX idx_ai_usage_log_user_id ON public.ai_usage_log USING btree (user_id);
CREATE INDEX idx_ai_usage_log_created_at ON public.ai_usage_log USING btree (created_at);
CREATE INDEX idx_ai_usage_log_search_type ON public.ai_usage_log USING btree (search_type);

CREATE INDEX idx_search_history_user_id ON public.search_history USING btree (user_id);
CREATE INDEX idx_search_history_created_at ON public.search_history USING btree (created_at);

CREATE INDEX idx_system_logs_level ON public.system_logs USING btree (level);
CREATE INDEX idx_system_logs_created_at ON public.system_logs USING btree (created_at);
CREATE INDEX idx_system_logs_user_id ON public.system_logs USING btree (user_id);
CREATE INDEX idx_system_logs_source ON public.system_logs USING btree (source);

CREATE INDEX idx_audit_logs_user_id ON public.audit_logs USING btree (user_id);
CREATE INDEX idx_audit_logs_action ON public.audit_logs USING btree (action);
CREATE INDEX idx_audit_logs_entity_type ON public.audit_logs USING btree (entity_type);
CREATE INDEX idx_audit_logs_created_at ON public.audit_logs USING btree (created_at);

CREATE INDEX idx_admin_dashboard_stats_date ON public.admin_dashboard_stats USING btree (stats_date);

CREATE INDEX idx_user_growth_stats_date ON public.user_growth_stats USING btree (date);

-- ============================================
-- FOREIGN KEYS (MVP)
-- ============================================

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_chat_session_id_fkey FOREIGN KEY (chat_session_id) REFERENCES public.chat_session(id);

ALTER TABLE ONLY public.chat_message_raw
    ADD CONSTRAINT chat_message_raw_chat_session_id_fkey FOREIGN KEY (chat_session_id) REFERENCES public.chat_session(id);

ALTER TABLE ONLY public.note_embedding
    ADD CONSTRAINT note_embedding_note_id_fkey FOREIGN KEY (note_id) REFERENCES public.note(id);

ALTER TABLE ONLY public.note
    ADD CONSTRAINT note_notebook_id_fkey FOREIGN KEY (notebook_id) REFERENCES public.notebook(id);

ALTER TABLE ONLY public.notebook
    ADD CONSTRAINT notebook_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.notebook(id);

-- ============================================
-- FOREIGN KEYS (NEW TABLES)
-- ============================================

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.email_verification_tokens
    ADD CONSTRAINT email_verification_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_subscriptions
    ADD CONSTRAINT user_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_subscriptions
    ADD CONSTRAINT user_subscriptions_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.subscription_plans(id);

ALTER TABLE ONLY public.payment_transactions
    ADD CONSTRAINT payment_transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.payment_transactions
    ADD CONSTRAINT payment_transactions_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.user_subscriptions(id);

ALTER TABLE ONLY public.user_notebooks
    ADD CONSTRAINT user_notebooks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_notebooks
    ADD CONSTRAINT user_notebooks_notebook_id_fkey FOREIGN KEY (notebook_id) REFERENCES public.notebook(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_notes
    ADD CONSTRAINT user_notes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_notes
    ADD CONSTRAINT user_notes_note_id_fkey FOREIGN KEY (note_id) REFERENCES public.note(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_chat_sessions
    ADD CONSTRAINT user_chat_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_chat_sessions
    ADD CONSTRAINT user_chat_sessions_chat_session_id_fkey FOREIGN KEY (chat_session_id) REFERENCES public.chat_session(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ai_usage_log
    ADD CONSTRAINT ai_usage_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.search_history
    ADD CONSTRAINT search_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.system_logs
    ADD CONSTRAINT system_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;

-- ============================================
-- ROW LEVEL SECURITY (MVP)
-- ============================================

ALTER TABLE public.chat_message ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.chat_message_raw ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.chat_session ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.note ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.notebook ENABLE ROW LEVEL SECURITY;

-- ============================================
-- ROW LEVEL SECURITY (NEW TABLES)
-- ============================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notebooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.search_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_usage_log ENABLE ROW LEVEL SECURITY;

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$function$;

CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at 
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_subscriptions_updated_at 
    BEFORE UPDATE ON public.user_subscriptions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_subscription_plans_updated_at 
    BEFORE UPDATE ON public.subscription_plans
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_payment_transactions_updated_at 
    BEFORE UPDATE ON public.payment_transactions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_admin_dashboard_stats_updated_at 
    BEFORE UPDATE ON public.admin_dashboard_stats
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- INITIAL DATA
-- ============================================

INSERT INTO public.subscription_plans (name, tier, description, price, billing_period, features, max_notes, max_notebooks, semantic_search_enabled, ai_chat_enabled, max_ai_queries_per_month) VALUES
('Free Plan', 'free', 'Basic note-taking features with regular keyword search', 0.00, 'monthly', 
 '{"features": ["Basic note taking", "Up to 100 notes", "Up to 10 notebooks", "Regular keyword search only", "No AI chat"]}', 
 100, 10, false, false, 0),
('Pro Plan Monthly', 'pro', 'Advanced features with semantic search and AI assistant', 9.99, 'monthly', 
 '{"features": ["Unlimited notes", "Unlimited notebooks", "Semantic search (RAG)", "AI chat assistant", "1000 AI queries/month", "Priority support"]}', 
 NULL, NULL, true, true, 1000),
('Pro Plan Yearly', 'pro', 'Advanced features with semantic search and AI assistant (Annual)', 99.99, 'yearly', 
 '{"features": ["Unlimited notes", "Unlimited notebooks", "Semantic search (RAG)", "AI chat assistant", "1000 AI queries/month", "Priority support", "2 months free"]}', 
 NULL, NULL, true, true, 1000);

INSERT INTO public.users (email, password_hash, full_name, role, status, email_verified, email_verified_at)
VALUES ('admin@notefiber.com', crypt('Admin123!', gen_salt('bf')), 'System Administrator', 'admin', 'active', true, now());

INSERT INTO public.user_profiles (user_id, bio, timezone, language)
SELECT id, 'System Administrator', 'UTC', 'en' 
FROM public.users 
WHERE email = 'admin@notefiber.com';

-- Completed on 2025-11-05 09:44:03

--
-- PostgreSQL database dump complete
--