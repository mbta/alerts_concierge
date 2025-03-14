--
-- PostgreSQL database dump
--

-- Dumped from database version 14.9 (Homebrew)
-- Dumped by pg_dump version 14.9 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alerts (
    id uuid NOT NULL,
    alert_id character varying(255),
    last_modified timestamp without time zone,
    data jsonb,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    image_url character varying(255),
    image_alternative_text character varying(255)
);


--
-- Name: guardian_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.guardian_tokens (
    jti character varying(255) NOT NULL,
    aud character varying(255) NOT NULL,
    typ character varying(255),
    iss character varying(255),
    sub character varying(255),
    exp bigint,
    jwt text,
    claims jsonb,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: informed_entities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.informed_entities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subscription_id uuid,
    direction_id integer,
    facility_type character varying(255),
    route character varying(255),
    route_type integer,
    stop character varying(255),
    trip character varying(255),
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    activities character varying(255)[] DEFAULT ARRAY[]::character varying[] NOT NULL
);


--
-- Name: metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.metadata (
    id character varying(255) NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: notification_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_subscriptions (
    id integer NOT NULL,
    notification_id uuid NOT NULL,
    subscription_id uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: notification_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_subscriptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_subscriptions_id_seq OWNED BY public.notification_subscriptions.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid NOT NULL,
    user_id uuid,
    alert_id character varying(255) NOT NULL,
    email character varying(255),
    phone_number character varying(255),
    header text,
    send_after timestamp without time zone,
    status character varying(255) NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_push_notification timestamp without time zone,
    service_effect character varying(255),
    description text,
    url character varying(255),
    closed_timestamp timestamp without time zone,
    type character varying(255),
    image_url character varying(255),
    image_alternative_text character varying(255)
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp without time zone
);


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    relevant_days character varying(255)[] DEFAULT ARRAY[]::character varying[] NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    origin character varying(255),
    destination character varying(255),
    type character varying(255),
    route character varying(255),
    direction_id smallint,
    origin_lat double precision,
    origin_long double precision,
    destination_lat double precision,
    destination_long double precision,
    trip_id uuid,
    rank smallint,
    return_trip boolean DEFAULT false,
    route_type integer,
    facility_types character varying(255)[] DEFAULT ARRAY[]::character varying[] NOT NULL,
    travel_start_time time without time zone,
    travel_end_time time without time zone,
    paused boolean DEFAULT false,
    parent_id uuid,
    is_admin boolean DEFAULT false NOT NULL
);


--
-- Name: trips; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trips (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    relevant_days character varying(255)[] DEFAULT ARRAY[]::character varying[] NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    roundtrip boolean DEFAULT false NOT NULL,
    return_start_time time without time zone,
    return_end_time time without time zone,
    facility_types character varying(255)[] DEFAULT ARRAY[]::character varying[] NOT NULL,
    trip_type character varying(255) DEFAULT 'commute'::character varying NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(255) NOT NULL,
    phone_number character varying(255),
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    role character varying(255) DEFAULT 'user'::character varying NOT NULL,
    digest_opt_in boolean DEFAULT true NOT NULL,
    sms_opted_out_at timestamp without time zone,
    communication_mode character varying(255) DEFAULT 'email'::character varying NOT NULL,
    email_rejection_status character varying(255)
);


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id integer NOT NULL,
    event character varying(10) NOT NULL,
    item_type character varying(255) NOT NULL,
    item_id uuid,
    item_changes jsonb NOT NULL,
    originator_id uuid,
    origin character varying(50),
    meta jsonb,
    inserted_at timestamp without time zone NOT NULL
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: notification_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.notification_subscriptions_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: guardian_tokens guardian_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guardian_tokens
    ADD CONSTRAINT guardian_tokens_pkey PRIMARY KEY (jti, aud);


--
-- Name: informed_entities informed_entities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.informed_entities
    ADD CONSTRAINT informed_entities_pkey PRIMARY KEY (id);


--
-- Name: metadata metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metadata
    ADD CONSTRAINT metadata_pkey PRIMARY KEY (id);


--
-- Name: notification_subscriptions notification_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_subscriptions
    ADD CONSTRAINT notification_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: trips trips_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: alerts_alert_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX alerts_alert_id_index ON public.alerts USING btree (alert_id);


--
-- Name: alerts_last_modified_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX alerts_last_modified_index ON public.alerts USING btree (last_modified);


--
-- Name: informed_entities_subscription_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX informed_entities_subscription_id_index ON public.informed_entities USING btree (subscription_id);


--
-- Name: notification_subscriptions_notification_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notification_subscriptions_notification_id_index ON public.notification_subscriptions USING btree (notification_id);


--
-- Name: notifications_alert_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_alert_id_index ON public.notifications USING btree (alert_id);


--
-- Name: notifications_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_user_id_index ON public.notifications USING btree (user_id);


--
-- Name: subscriptions_destination_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX subscriptions_destination_ix ON public.subscriptions USING btree (destination) WHERE (paused = false);


--
-- Name: subscriptions_origin_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX subscriptions_origin_ix ON public.subscriptions USING btree (origin) WHERE (paused = false);


--
-- Name: subscriptions_route_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX subscriptions_route_ix ON public.subscriptions USING btree (route) WHERE (paused = false);


--
-- Name: subscriptions_route_type_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX subscriptions_route_type_ix ON public.subscriptions USING btree (route_type) WHERE (paused = false);


--
-- Name: subscriptions_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX subscriptions_user_id_index ON public.subscriptions USING btree (user_id);


--
-- Name: trips_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trips_user_id_index ON public.trips USING btree (user_id);


--
-- Name: users_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_index ON public.users USING btree (email);


--
-- Name: versions_event_item_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX versions_event_item_type_index ON public.versions USING btree (event, item_type);


--
-- Name: versions_item_id_item_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX versions_item_id_item_type_index ON public.versions USING btree (item_id, item_type);


--
-- Name: versions_item_type_inserted_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX versions_item_type_inserted_at_index ON public.versions USING btree (item_type, inserted_at);


--
-- Name: versions_originator_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX versions_originator_id_index ON public.versions USING btree (originator_id);


--
-- Name: informed_entities informed_entities_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.informed_entities
    ADD CONSTRAINT informed_entities_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: subscriptions subscriptions_trip_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.trips(id) ON DELETE CASCADE;


--
-- Name: subscriptions subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: trips trips_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: versions versions_originator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_originator_id_fkey FOREIGN KEY (originator_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20170323160837);
INSERT INTO public."schema_migrations" (version) VALUES (20170324164902);
INSERT INTO public."schema_migrations" (version) VALUES (20170411193142);
INSERT INTO public."schema_migrations" (version) VALUES (20170413164902);
INSERT INTO public."schema_migrations" (version) VALUES (20170413164922);
INSERT INTO public."schema_migrations" (version) VALUES (20170419201204);
INSERT INTO public."schema_migrations" (version) VALUES (20170420134049);
INSERT INTO public."schema_migrations" (version) VALUES (20170426151933);
INSERT INTO public."schema_migrations" (version) VALUES (20170504192335);
INSERT INTO public."schema_migrations" (version) VALUES (20170509151223);
INSERT INTO public."schema_migrations" (version) VALUES (20170511131803);
INSERT INTO public."schema_migrations" (version) VALUES (20170511141849);
INSERT INTO public."schema_migrations" (version) VALUES (20170601111510);
INSERT INTO public."schema_migrations" (version) VALUES (20170605184024);
INSERT INTO public."schema_migrations" (version) VALUES (20170606192717);
INSERT INTO public."schema_migrations" (version) VALUES (20170622144910);
INSERT INTO public."schema_migrations" (version) VALUES (20170706203147);
INSERT INTO public."schema_migrations" (version) VALUES (20170711152200);
INSERT INTO public."schema_migrations" (version) VALUES (20170717151734);
INSERT INTO public."schema_migrations" (version) VALUES (20170726172307);
INSERT INTO public."schema_migrations" (version) VALUES (20170822155325);
INSERT INTO public."schema_migrations" (version) VALUES (20170925154917);
INSERT INTO public."schema_migrations" (version) VALUES (20170928134753);
INSERT INTO public."schema_migrations" (version) VALUES (20171124210022);
INSERT INTO public."schema_migrations" (version) VALUES (20180115200621);
INSERT INTO public."schema_migrations" (version) VALUES (20180126151708);
INSERT INTO public."schema_migrations" (version) VALUES (20180220220709);
INSERT INTO public."schema_migrations" (version) VALUES (20180220221033);
INSERT INTO public."schema_migrations" (version) VALUES (20180220223228);
INSERT INTO public."schema_migrations" (version) VALUES (20180221160945);
INSERT INTO public."schema_migrations" (version) VALUES (20180221163334);
INSERT INTO public."schema_migrations" (version) VALUES (20180302174444);
INSERT INTO public."schema_migrations" (version) VALUES (20180302175419);
INSERT INTO public."schema_migrations" (version) VALUES (20180305194714);
INSERT INTO public."schema_migrations" (version) VALUES (20180314150509);
INSERT INTO public."schema_migrations" (version) VALUES (20180314174157);
INSERT INTO public."schema_migrations" (version) VALUES (20180320154509);
INSERT INTO public."schema_migrations" (version) VALUES (20180320212519);
INSERT INTO public."schema_migrations" (version) VALUES (20180322200228);
INSERT INTO public."schema_migrations" (version) VALUES (20180328192337);
INSERT INTO public."schema_migrations" (version) VALUES (20180402201746);
INSERT INTO public."schema_migrations" (version) VALUES (20180427180310);
INSERT INTO public."schema_migrations" (version) VALUES (20180626183609);
INSERT INTO public."schema_migrations" (version) VALUES (20180627190847);
INSERT INTO public."schema_migrations" (version) VALUES (20180627212459);
INSERT INTO public."schema_migrations" (version) VALUES (20180628144348);
INSERT INTO public."schema_migrations" (version) VALUES (20180628145148);
INSERT INTO public."schema_migrations" (version) VALUES (20180730164440);
INSERT INTO public."schema_migrations" (version) VALUES (20180803152303);
INSERT INTO public."schema_migrations" (version) VALUES (20180809234726);
INSERT INTO public."schema_migrations" (version) VALUES (20180827184355);
INSERT INTO public."schema_migrations" (version) VALUES (20180827190044);
INSERT INTO public."schema_migrations" (version) VALUES (20180827191017);
INSERT INTO public."schema_migrations" (version) VALUES (20180914150352);
INSERT INTO public."schema_migrations" (version) VALUES (20181129190220);
INSERT INTO public."schema_migrations" (version) VALUES (20190607150001);
INSERT INTO public."schema_migrations" (version) VALUES (20190610143559);
INSERT INTO public."schema_migrations" (version) VALUES (20200430210043);
INSERT INTO public."schema_migrations" (version) VALUES (20210421143058);
INSERT INTO public."schema_migrations" (version) VALUES (20210528144213);
INSERT INTO public."schema_migrations" (version) VALUES (20230208195021);
INSERT INTO public."schema_migrations" (version) VALUES (20230823214704);
INSERT INTO public."schema_migrations" (version) VALUES (20230824175754);
INSERT INTO public."schema_migrations" (version) VALUES (20230830193726);
