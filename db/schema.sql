--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: robotstxt; Type: TABLE; Schema: public; Owner: leo; Tablespace: 
--

CREATE TABLE robotstxt (
    domain character varying(128) NOT NULL,
    data text,
    valid_until timestamp with time zone
);


ALTER TABLE public.robotstxt OWNER TO leo;

--
-- Name: tasklist; Type: TABLE; Schema: public; Owner: leo; Tablespace: 
--

CREATE TABLE tasklist (
    url character varying(512) NOT NULL,
    state integer,
    done_at timestamp with time zone
);


ALTER TABLE public.tasklist OWNER TO leo;

--
-- Name: robotstxt_pkey; Type: CONSTRAINT; Schema: public; Owner: leo; Tablespace: 
--

ALTER TABLE ONLY robotstxt
    ADD CONSTRAINT robotstxt_pkey PRIMARY KEY (domain);


--
-- Name: tasklist_pkey; Type: CONSTRAINT; Schema: public; Owner: leo; Tablespace: 
--

ALTER TABLE ONLY tasklist
    ADD CONSTRAINT tasklist_pkey PRIMARY KEY (url);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

