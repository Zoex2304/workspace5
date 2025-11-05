--
-- PostgreSQL database dump
--

\restrict bd62enWDbHpqrHejF7YVYGP5ms7VeCscgWLVH3mMa4bh04oAsf4H8xzbxhIMM0h

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

-- Started on 2025-11-05 09:44:03

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 8 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 5396 (class 0 OID 0)
-- Dependencies: 8
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 251 (class 1259 OID 18064)
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
-- TOC entry 252 (class 1259 OID 18073)
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
-- TOC entry 253 (class 1259 OID 18082)
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
-- TOC entry 254 (class 1259 OID 18090)
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
-- TOC entry 255 (class 1259 OID 18099)
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
-- TOC entry 256 (class 1259 OID 18105)
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

--
-- TOC entry 5222 (class 2606 OID 18216)
-- Name: chat_message chat_message_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_pkey PRIMARY KEY (id);


--
-- TOC entry 5224 (class 2606 OID 18204)
-- Name: chat_message_raw chat_message_raw_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message_raw
    ADD CONSTRAINT chat_message_raw_pkey PRIMARY KEY (id);


--
-- TOC entry 5226 (class 2606 OID 18274)
-- Name: chat_session chat_session_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_session
    ADD CONSTRAINT chat_session_pkey PRIMARY KEY (id);


--
-- TOC entry 5230 (class 2606 OID 18278)
-- Name: note_embedding note_embedding_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.note_embedding
    ADD CONSTRAINT note_embedding_pkey PRIMARY KEY (id);


--
-- TOC entry 5228 (class 2606 OID 18203)
-- Name: note note_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.note
    ADD CONSTRAINT note_pkey PRIMARY KEY (id);


--
-- TOC entry 5232 (class 2606 OID 18244)
-- Name: notebook notebook_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notebook
    ADD CONSTRAINT notebook_pkey PRIMARY KEY (id);


--
-- TOC entry 5233 (class 2606 OID 18294)
-- Name: chat_message chat_message_chat_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_chat_session_id_fkey FOREIGN KEY (chat_session_id) REFERENCES public.chat_session(id);


--
-- TOC entry 5234 (class 2606 OID 18281)
-- Name: chat_message_raw chat_message_raw_chat_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_message_raw
    ADD CONSTRAINT chat_message_raw_chat_session_id_fkey FOREIGN KEY (chat_session_id) REFERENCES public.chat_session(id);


--
-- TOC entry 5236 (class 2606 OID 18287)
-- Name: note_embedding note_embedding_note_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.note_embedding
    ADD CONSTRAINT note_embedding_note_id_fkey FOREIGN KEY (note_id) REFERENCES public.note(id);


--
-- TOC entry 5235 (class 2606 OID 18248)
-- Name: note note_notebook_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.note
    ADD CONSTRAINT note_notebook_id_fkey FOREIGN KEY (notebook_id) REFERENCES public.notebook(id);


--
-- TOC entry 5237 (class 2606 OID 18265)
-- Name: notebook notebook_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notebook
    ADD CONSTRAINT notebook_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.notebook(id);


--
-- TOC entry 5385 (class 0 OID 18064)
-- Dependencies: 251
-- Name: chat_message; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.chat_message ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5386 (class 0 OID 18073)
-- Dependencies: 252
-- Name: chat_message_raw; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.chat_message_raw ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5387 (class 0 OID 18082)
-- Dependencies: 253
-- Name: chat_session; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.chat_session ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5388 (class 0 OID 18090)
-- Dependencies: 254
-- Name: note; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.note ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 5389 (class 0 OID 18105)
-- Dependencies: 256
-- Name: notebook; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.notebook ENABLE ROW LEVEL SECURITY;

-- Completed on 2025-11-05 09:44:03

--
-- PostgreSQL database dump complete
--

\unrestrict bd62enWDbHpqrHejF7YVYGP5ms7VeCscgWLVH3mMa4bh04oAsf4H8xzbxhIMM0h

