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

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

-- COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: ltree; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;


--
-- Name: EXTENSION ltree; Type: COMMENT; Schema: -; Owner: -
--

-- COMMENT ON EXTENSION ltree IS 'data type for hierarchical tree-like structures';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

-- COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: gender_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.gender_enum AS ENUM (
    'female',
    'male',
    'transgender'
);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: accesses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accesses (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    resource_type character varying,
    resource_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.addresses (
    id uuid NOT NULL,
    street_address character varying,
    village_or_colony character varying,
    district character varying,
    state character varying,
    country character varying,
    pin character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    device_created_at timestamp without time zone NOT NULL,
    device_updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    zone character varying
);


--
-- Name: appointments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.appointments (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    patient_id uuid NOT NULL,
    facility_id uuid NOT NULL,
    scheduled_date date NOT NULL,
    status character varying,
    cancel_reason character varying,
    device_created_at timestamp without time zone NOT NULL,
    device_updated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    remind_on date,
    agreed_to_visit boolean,
    deleted_at timestamp without time zone,
    appointment_type character varying NOT NULL,
    user_id uuid,
    creation_facility_id uuid
);


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: blood_pressures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blood_pressures (
    id uuid NOT NULL,
    systolic integer NOT NULL,
    diastolic integer NOT NULL,
    patient_id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    device_created_at timestamp without time zone NOT NULL,
    device_updated_at timestamp without time zone NOT NULL,
    facility_id uuid NOT NULL,
    user_id uuid,
    deleted_at timestamp without time zone,
    recorded_at timestamp without time zone
);


--
-- Name: facilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.facilities (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name character varying,
    street_address character varying,
    village_or_colony character varying,
    district character varying,
    state character varying,
    country character varying,
    pin character varying,
    facility_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    latitude double precision,
    longitude double precision,
    deleted_at timestamp without time zone,
    facility_group_id uuid,
    slug character varying,
    zone character varying,
    enable_diabetes_management boolean DEFAULT false NOT NULL,
    facility_size character varying NOT NULL,
    monthly_estimated_opd_load integer,
    enable_teleconsultation boolean DEFAULT false NOT NULL
);


--
-- Name: medical_histories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.medical_histories (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    patient_id uuid NOT NULL,
    prior_heart_attack_boolean boolean,
    prior_stroke_boolean boolean,
    chronic_kidney_disease_boolean boolean,
    receiving_treatment_for_hypertension_boolean boolean,
    diabetes_boolean boolean,
    device_created_at timestamp without time zone NOT NULL,
    device_updated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    diagnosed_with_hypertension_boolean boolean,
    prior_heart_attack text,
    prior_stroke text,
    chronic_kidney_disease text,
    receiving_treatment_for_hypertension text,
    diabetes text,
    diagnosed_with_hypertension text,
    deleted_at timestamp without time zone,
    user_id uuid,
    hypertension text,
    receiving_treatment_for_diabetes text
);


--
-- Name: blood_pressures_per_facility_per_days; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.blood_pressures_per_facility_per_days AS
 WITH latest_bp_per_patient_per_day AS (
         SELECT DISTINCT ON (blood_pressures.facility_id, blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text) blood_pressures.id AS bp_id,
            blood_pressures.facility_id,
            (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS day,
            (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS month,
            (date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS quarter,
            (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS year
           FROM (public.blood_pressures
             JOIN public.medical_histories ON (((blood_pressures.patient_id = medical_histories.patient_id) AND (medical_histories.hypertension = 'yes'::text))))
          WHERE (blood_pressures.deleted_at IS NULL)
          ORDER BY blood_pressures.facility_id, blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, blood_pressures.recorded_at DESC, blood_pressures.id
        )
 SELECT count(latest_bp_per_patient_per_day.bp_id) AS bp_count,
    facilities.id AS facility_id,
    timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, facilities.deleted_at)) AS deleted_at,
    latest_bp_per_patient_per_day.day,
    latest_bp_per_patient_per_day.month,
    latest_bp_per_patient_per_day.quarter,
    latest_bp_per_patient_per_day.year
   FROM (latest_bp_per_patient_per_day
     JOIN public.facilities ON ((facilities.id = latest_bp_per_patient_per_day.facility_id)))
  GROUP BY latest_bp_per_patient_per_day.day, latest_bp_per_patient_per_day.month, latest_bp_per_patient_per_day.quarter, latest_bp_per_patient_per_day.year, facilities.deleted_at, facilities.id
  WITH NO DATA;


--
-- Name: blood_sugars; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blood_sugars (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    blood_sugar_type character varying NOT NULL,
    blood_sugar_value numeric NOT NULL,
    patient_id uuid NOT NULL,
    user_id uuid NOT NULL,
    facility_id uuid NOT NULL,
    device_created_at timestamp without time zone NOT NULL,
    device_updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    recorded_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: call_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.call_logs (
    id bigint NOT NULL,
    session_id character varying,
    result character varying,
    duration integer,
    callee_phone_number character varying NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    caller_phone_number character varying NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: call_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.call_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: call_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.call_logs_id_seq OWNED BY public.call_logs.id;


--
-- Name: call_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.call_results (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    appointment_id uuid NOT NULL,
    remove_reason character varying,
    result_type character varying NOT NULL,
    device_created_at timestamp without time zone NOT NULL,
    device_updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: clean_medicine_to_dosages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clean_medicine_to_dosages (
    rxcui bigint NOT NULL,
    medicine character varying NOT NULL,
    dosage double precision NOT NULL
);


--
-- Name: communications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.communications (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    appointment_id uuid,
    user_id uuid,
    communication_type character varying,
    device_created_at timestamp without time zone NOT NULL,
    device_updated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    detailable_type character varying,
    detailable_id bigint,
    notification_id uuid
);


--
-- Name: data_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_migrations (
    version character varying NOT NULL
);


--
-- Name: deduplication_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deduplication_logs (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    user_id uuid,
    record_type character varying NOT NULL,
    deleted_record_id character varying NOT NULL,
    deduped_record_id character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: drug_stocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.drug_stocks (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    facility_id uuid,
    user_id uuid NOT NULL,
    protocol_drug_id uuid NOT NULL,
    in_stock integer,
    received integer,
    for_end_of_month date NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    region_id uuid NOT NULL,
    redistributed integer
);


--
-- Name: email_authentications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_authentications (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp without time zone,
    invitation_token character varying,
    invitation_created_at timestamp without time zone,
    invitation_sent_at timestamp without time zone,
    invitation_accepted_at timestamp without time zone,
    invitation_limit integer,
    invited_by_id uuid,
    invited_by_type character varying,
    invitations_count integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    session_token character varying
);


--
-- Name: encounters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.encounters (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    facility_id uuid NOT NULL,
    patient_id uuid NOT NULL,
    encountered_on date NOT NULL,
    timezone_offset integer NOT NULL,
    notes text,
    metadata jsonb,
    device_created_at timestamp without time zone NOT NULL,
    device_updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: estimated_populations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.estimated_populations (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    region_id uuid NOT NULL,
    population integer,
    diagnosis character varying DEFAULT 'HTN'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: exotel_phone_number_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exotel_phone_number_details (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    patient_phone_number_id uuid NOT NULL,
    whitelist_status character varying,
    whitelist_requested_at timestamp without time zone,
    whitelist_status_valid_until timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: experiments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.experiments (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    experiment_type character varying NOT NULL,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    max_patients_per_day integer DEFAULT 0
);


--
-- Name: facilities_teleconsultation_medical_officers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.facilities_teleconsultation_medical_officers (
    facility_id uuid NOT NULL,
    user_id uuid NOT NULL
);


--
-- Name: facility_business_identifiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.facility_business_identifiers (
    id bigint NOT NULL,
    identifier character varying NOT NULL,
    identifier_type character varying NOT NULL,
    facility_id uuid NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: facility_business_identifiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.facility_business_identifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: facility_business_identifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.facility_business_identifiers_id_seq OWNED BY public.facility_business_identifiers.id;


--
-- Name: facility_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.facility_groups (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name character varying,
    description text,
    organization_id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    protocol_id uuid,
    slug character varying
);


--
-- Name: flipper_features; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flipper_features (
    id bigint NOT NULL,
    key character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: flipper_features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flipper_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipper_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flipper_features_id_seq OWNED BY public.flipper_features.id;


--
-- Name: flipper_gates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flipper_gates (
    id bigint NOT NULL,
    feature_key character varying NOT NULL,
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: flipper_gates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flipper_gates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flipper_gates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flipper_gates_id_seq OWNED BY public.flipper_gates.id;


--
-- Name: patients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.patients (
    id uuid NOT NULL,
    full_name character varying,
    age integer,
    gender character varying,
    date_of_birth date,
    status character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    address_id uuid,
    age_updated_at timestamp without time zone,
    device_created_at timestamp without time zone NOT NULL,
    device_updated_at timestamp without time zone NOT NULL,
    test_data boolean DEFAULT false NOT NULL,
    registration_facility_id uuid,
    registration_user_id uuid,
    deleted_at timestamp without time zone,
    contacted_by_counsellor boolean DEFAULT false,
    could_not_contact_reason character varying,
    recorded_at timestamp without time zone,
    reminder_consent character varying DEFAULT 'denied'::character varying NOT NULL,
    deleted_by_user_id uuid,
    deleted_reason character varying,
    assigned_facility_id uuid
);


--
-- Name: latest_blood_pressures_per_patient_per_months; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.latest_blood_pressures_per_patient_per_months AS
 SELECT DISTINCT ON (blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at))))::text, (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at))))::text) blood_pressures.id AS bp_id,
    blood_pressures.patient_id,
    patients.registration_facility_id,
    patients.assigned_facility_id,
    patients.status AS patient_status,
    blood_pressures.facility_id AS bp_facility_id,
    timezone('UTC'::text, timezone('UTC'::text, blood_pressures.recorded_at)) AS bp_recorded_at,
    timezone('UTC'::text, timezone('UTC'::text, patients.recorded_at)) AS patient_recorded_at,
    blood_pressures.systolic,
    blood_pressures.diastolic,
    timezone('UTC'::text, timezone('UTC'::text, blood_pressures.deleted_at)) AS deleted_at,
    medical_histories.hypertension AS medical_history_hypertension,
    (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at))))::text AS month,
    (date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at))))::text AS quarter,
    (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at))))::text AS year
   FROM ((public.blood_pressures
     JOIN public.patients ON ((patients.id = blood_pressures.patient_id)))
     LEFT JOIN public.medical_histories ON ((medical_histories.patient_id = blood_pressures.patient_id)))
  WHERE ((blood_pressures.deleted_at IS NULL) AND (patients.deleted_at IS NULL))
  ORDER BY blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at))))::text, (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at))))::text, blood_pressures.recorded_at DESC, blood_pressures.id
  WITH NO DATA;


--
-- Name: latest_blood_pressures_per_patient_per_quarters; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.latest_blood_pressures_per_patient_per_quarters AS
 SELECT DISTINCT ON (latest_blood_pressures_per_patient_per_months.patient_id, latest_blood_pressures_per_patient_per_months.year, latest_blood_pressures_per_patient_per_months.quarter) latest_blood_pressures_per_patient_per_months.bp_id,
    latest_blood_pressures_per_patient_per_months.patient_id,
    latest_blood_pressures_per_patient_per_months.registration_facility_id,
    latest_blood_pressures_per_patient_per_months.assigned_facility_id,
    latest_blood_pressures_per_patient_per_months.patient_status,
    latest_blood_pressures_per_patient_per_months.bp_facility_id,
    latest_blood_pressures_per_patient_per_months.bp_recorded_at,
    latest_blood_pressures_per_patient_per_months.patient_recorded_at,
    latest_blood_pressures_per_patient_per_months.systolic,
    latest_blood_pressures_per_patient_per_months.diastolic,
    latest_blood_pressures_per_patient_per_months.deleted_at,
    latest_blood_pressures_per_patient_per_months.medical_history_hypertension,
    latest_blood_pressures_per_patient_per_months.month,
    latest_blood_pressures_per_patient_per_months.quarter,
    latest_blood_pressures_per_patient_per_months.year
   FROM public.latest_blood_pressures_per_patient_per_months
  ORDER BY latest_blood_pressures_per_patient_per_months.patient_id, latest_blood_pressures_per_patient_per_months.year, latest_blood_pressures_per_patient_per_months.quarter, latest_blood_pressures_per_patient_per_months.bp_recorded_at DESC, latest_blood_pressures_per_patient_per_months.bp_id
  WITH NO DATA;


--
-- Name: latest_blood_pressures_per_patients; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.latest_blood_pressures_per_patients AS
 SELECT DISTINCT ON (latest_blood_pressures_per_patient_per_months.patient_id) latest_blood_pressures_per_patient_per_months.bp_id,
    latest_blood_pressures_per_patient_per_months.patient_id,
    latest_blood_pressures_per_patient_per_months.registration_facility_id,
    latest_blood_pressures_per_patient_per_months.assigned_facility_id,
    latest_blood_pressures_per_patient_per_months.patient_status,
    latest_blood_pressures_per_patient_per_months.bp_facility_id,
    latest_blood_pressures_per_patient_per_months.bp_recorded_at,
    latest_blood_pressures_per_patient_per_months.patient_recorded_at,
    latest_blood_pressures_per_patient_per_months.systolic,
    latest_blood_pressures_per_patient_per_months.diastolic,
    latest_blood_pressures_per_patient_per_months.deleted_at,
    latest_blood_pressures_per_patient_per_months.medical_history_hypertension,
    latest_blood_pressures_per_patient_per_months.month,
    latest_blood_pressures_per_patient_per_months.quarter,
    latest_blood_pressures_per_patient_per_months.year
   FROM public.latest_blood_pressures_per_patient_per_months
  ORDER BY latest_blood_pressures_per_patient_per_months.patient_id, latest_blood_pressures_per_patient_per_months.bp_recorded_at DESC, latest_blood_pressures_per_patient_per_months.bp_id
  WITH NO DATA;


--
-- Name: patient_business_identifiers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.patient_business_identifiers (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    identifier character varying NOT NULL,
    identifier_type character varying NOT NULL,
    patient_id uuid NOT NULL,
    metadata_version character varying,
    metadata json,
    device_created_at timestamp without time zone NOT NULL,
    device_updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: patient_phone_numbers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.patient_phone_numbers (
    id uuid NOT NULL,
    number character varying,
    phone_type character varying,
    active boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    patient_id uuid,
    device_created_at timestamp without time zone NOT NULL,
    device_updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    dnd_status boolean DEFAULT true NOT NULL
);


--
-- Name: materialized_patient_summaries; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.materialized_patient_summaries AS
 SELECT p.recorded_at,
    concat(date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at))), ' Q', date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))) AS registration_quarter,
    p.full_name,
        CASE
            WHEN (p.date_of_birth IS NOT NULL) THEN date_part('year'::text, age((p.date_of_birth)::timestamp with time zone))
            ELSE floor(((p.age)::double precision + date_part('year'::text, age(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.age_updated_at))))))
        END AS current_age,
    p.gender,
    p.status,
    latest_phone_number.number AS latest_phone_number,
    addresses.village_or_colony,
    addresses.street_address,
    addresses.district,
    addresses.state,
    addresses.zone AS block,
    reg_facility.name AS registration_facility_name,
    reg_facility.facility_type AS registration_facility_type,
    reg_facility.district AS registration_district,
    reg_facility.state AS registration_state,
    p.assigned_facility_id,
    assigned_facility.name AS assigned_facility_name,
    assigned_facility.facility_type AS assigned_facility_type,
    assigned_facility.district AS assigned_facility_district,
    assigned_facility.state AS assigned_facility_state,
    latest_blood_pressure.systolic AS latest_blood_pressure_systolic,
    latest_blood_pressure.diastolic AS latest_blood_pressure_diastolic,
    latest_blood_pressure.recorded_at AS latest_blood_pressure_recorded_at,
    concat(date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, latest_blood_pressure.recorded_at))), ' Q', date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, latest_blood_pressure.recorded_at)))) AS latest_blood_pressure_quarter,
    latest_blood_pressure_facility.name AS latest_blood_pressure_facility_name,
    latest_blood_pressure_facility.facility_type AS latest_blood_pressure_facility_type,
    latest_blood_pressure_facility.district AS latest_blood_pressure_district,
    latest_blood_pressure_facility.state AS latest_blood_pressure_state,
    latest_blood_sugar.id AS latest_blood_sugar_id,
    latest_blood_sugar.blood_sugar_type AS latest_blood_sugar_type,
    latest_blood_sugar.blood_sugar_value AS latest_blood_sugar_value,
    latest_blood_sugar.recorded_at AS latest_blood_sugar_recorded_at,
    concat(date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, latest_blood_sugar.recorded_at))), ' Q', date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, latest_blood_sugar.recorded_at)))) AS latest_blood_sugar_quarter,
    latest_blood_sugar_facility.name AS latest_blood_sugar_facility_name,
    latest_blood_sugar_facility.facility_type AS latest_blood_sugar_facility_type,
    latest_blood_sugar_facility.district AS latest_blood_sugar_district,
    latest_blood_sugar_facility.state AS latest_blood_sugar_state,
    GREATEST((0)::double precision, date_part('day'::text, (now() - (next_scheduled_appointment.scheduled_date)::timestamp with time zone))) AS days_overdue,
    next_scheduled_appointment.id AS next_scheduled_appointment_id,
    next_scheduled_appointment.scheduled_date AS next_scheduled_appointment_scheduled_date,
    next_scheduled_appointment.status AS next_scheduled_appointment_status,
    next_scheduled_appointment.remind_on AS next_scheduled_appointment_remind_on,
    next_scheduled_appointment_facility.id AS next_scheduled_appointment_facility_id,
    next_scheduled_appointment_facility.name AS next_scheduled_appointment_facility_name,
    next_scheduled_appointment_facility.facility_type AS next_scheduled_appointment_facility_type,
    next_scheduled_appointment_facility.district AS next_scheduled_appointment_district,
    next_scheduled_appointment_facility.state AS next_scheduled_appointment_state,
        CASE
            WHEN (next_scheduled_appointment.scheduled_date IS NULL) THEN 0
            WHEN (next_scheduled_appointment.scheduled_date > date_trunc('day'::text, (now() - '30 days'::interval))) THEN 0
            WHEN ((latest_blood_pressure.systolic >= 180) OR (latest_blood_pressure.diastolic >= 110)) THEN 1
            WHEN (((mh.prior_heart_attack = 'yes'::text) OR (mh.prior_stroke = 'yes'::text)) AND ((latest_blood_pressure.systolic >= 140) OR (latest_blood_pressure.diastolic >= 90))) THEN 1
            WHEN ((((latest_blood_sugar.blood_sugar_type)::text = 'random'::text) AND (latest_blood_sugar.blood_sugar_value >= (300)::numeric)) OR (((latest_blood_sugar.blood_sugar_type)::text = 'post_prandial'::text) AND (latest_blood_sugar.blood_sugar_value >= (300)::numeric)) OR (((latest_blood_sugar.blood_sugar_type)::text = 'fasting'::text) AND (latest_blood_sugar.blood_sugar_value >= (200)::numeric)) OR (((latest_blood_sugar.blood_sugar_type)::text = 'hba1c'::text) AND (latest_blood_sugar.blood_sugar_value >= 9.0))) THEN 1
            ELSE 0
        END AS risk_level,
    latest_bp_passport.id AS latest_bp_passport_id,
    latest_bp_passport.identifier AS latest_bp_passport_identifier,
    mh.hypertension,
    mh.diabetes,
    p.id
   FROM ((((((((((((public.patients p
     LEFT JOIN public.addresses ON ((addresses.id = p.address_id)))
     LEFT JOIN public.facilities reg_facility ON ((reg_facility.id = p.registration_facility_id)))
     LEFT JOIN public.facilities assigned_facility ON ((assigned_facility.id = p.assigned_facility_id)))
     LEFT JOIN ( SELECT DISTINCT ON (medical_histories.patient_id) medical_histories.id,
            medical_histories.patient_id,
            medical_histories.prior_heart_attack_boolean,
            medical_histories.prior_stroke_boolean,
            medical_histories.chronic_kidney_disease_boolean,
            medical_histories.receiving_treatment_for_hypertension_boolean,
            medical_histories.diabetes_boolean,
            medical_histories.device_created_at,
            medical_histories.device_updated_at,
            medical_histories.created_at,
            medical_histories.updated_at,
            medical_histories.diagnosed_with_hypertension_boolean,
            medical_histories.prior_heart_attack,
            medical_histories.prior_stroke,
            medical_histories.chronic_kidney_disease,
            medical_histories.receiving_treatment_for_hypertension,
            medical_histories.diabetes,
            medical_histories.diagnosed_with_hypertension,
            medical_histories.deleted_at,
            medical_histories.user_id,
            medical_histories.hypertension
           FROM public.medical_histories
          WHERE (medical_histories.deleted_at IS NULL)) mh ON ((mh.patient_id = p.id)))
     LEFT JOIN ( SELECT DISTINCT ON (patient_phone_numbers.patient_id) patient_phone_numbers.id,
            patient_phone_numbers.number,
            patient_phone_numbers.phone_type,
            patient_phone_numbers.active,
            patient_phone_numbers.created_at,
            patient_phone_numbers.updated_at,
            patient_phone_numbers.patient_id,
            patient_phone_numbers.device_created_at,
            patient_phone_numbers.device_updated_at,
            patient_phone_numbers.deleted_at,
            patient_phone_numbers.dnd_status
           FROM public.patient_phone_numbers
          WHERE (patient_phone_numbers.deleted_at IS NULL)
          ORDER BY patient_phone_numbers.patient_id, patient_phone_numbers.device_created_at DESC) latest_phone_number ON ((latest_phone_number.patient_id = p.id)))
     LEFT JOIN ( SELECT DISTINCT ON (blood_pressures.patient_id) blood_pressures.id,
            blood_pressures.systolic,
            blood_pressures.diastolic,
            blood_pressures.patient_id,
            blood_pressures.created_at,
            blood_pressures.updated_at,
            blood_pressures.device_created_at,
            blood_pressures.device_updated_at,
            blood_pressures.facility_id,
            blood_pressures.user_id,
            blood_pressures.deleted_at,
            blood_pressures.recorded_at
           FROM public.blood_pressures
          WHERE (blood_pressures.deleted_at IS NULL)
          ORDER BY blood_pressures.patient_id, blood_pressures.recorded_at DESC) latest_blood_pressure ON ((latest_blood_pressure.patient_id = p.id)))
     LEFT JOIN public.facilities latest_blood_pressure_facility ON ((latest_blood_pressure_facility.id = latest_blood_pressure.facility_id)))
     LEFT JOIN ( SELECT DISTINCT ON (blood_sugars.patient_id) blood_sugars.id,
            blood_sugars.blood_sugar_type,
            blood_sugars.blood_sugar_value,
            blood_sugars.patient_id,
            blood_sugars.user_id,
            blood_sugars.facility_id,
            blood_sugars.device_created_at,
            blood_sugars.device_updated_at,
            blood_sugars.deleted_at,
            blood_sugars.recorded_at,
            blood_sugars.created_at,
            blood_sugars.updated_at
           FROM public.blood_sugars
          WHERE (blood_sugars.deleted_at IS NULL)
          ORDER BY blood_sugars.patient_id, blood_sugars.recorded_at DESC) latest_blood_sugar ON ((latest_blood_sugar.patient_id = p.id)))
     LEFT JOIN public.facilities latest_blood_sugar_facility ON ((latest_blood_sugar_facility.id = latest_blood_sugar.facility_id)))
     LEFT JOIN ( SELECT DISTINCT ON (patient_business_identifiers.patient_id) patient_business_identifiers.id,
            patient_business_identifiers.identifier,
            patient_business_identifiers.identifier_type,
            patient_business_identifiers.patient_id,
            patient_business_identifiers.metadata_version,
            patient_business_identifiers.metadata,
            patient_business_identifiers.device_created_at,
            patient_business_identifiers.device_updated_at,
            patient_business_identifiers.deleted_at,
            patient_business_identifiers.created_at,
            patient_business_identifiers.updated_at
           FROM public.patient_business_identifiers
          WHERE (((patient_business_identifiers.identifier_type)::text = 'simple_bp_passport'::text) AND (patient_business_identifiers.deleted_at IS NULL))
          ORDER BY patient_business_identifiers.patient_id, patient_business_identifiers.device_created_at DESC) latest_bp_passport ON ((latest_bp_passport.patient_id = p.id)))
     LEFT JOIN ( SELECT DISTINCT ON (appointments.patient_id) appointments.id,
            appointments.patient_id,
            appointments.facility_id,
            appointments.scheduled_date,
            appointments.status,
            appointments.cancel_reason,
            appointments.device_created_at,
            appointments.device_updated_at,
            appointments.created_at,
            appointments.updated_at,
            appointments.remind_on,
            appointments.agreed_to_visit,
            appointments.deleted_at,
            appointments.appointment_type,
            appointments.user_id,
            appointments.creation_facility_id
           FROM public.appointments
          WHERE (((appointments.status)::text = 'scheduled'::text) AND (appointments.deleted_at IS NULL))
          ORDER BY appointments.patient_id, appointments.scheduled_date DESC) next_scheduled_appointment ON ((next_scheduled_appointment.patient_id = p.id)))
     LEFT JOIN public.facilities next_scheduled_appointment_facility ON ((next_scheduled_appointment_facility.id = next_scheduled_appointment.facility_id)))
  WHERE (p.deleted_at IS NULL)
  WITH NO DATA;


--
-- Name: medicine_purposes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.medicine_purposes (
    name character varying NOT NULL,
    hypertension boolean NOT NULL,
    diabetes boolean NOT NULL
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    remind_on date NOT NULL,
    status character varying NOT NULL,
    message character varying NOT NULL,
    experiment_id uuid,
    reminder_template_id uuid,
    patient_id uuid NOT NULL,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    subject_type character varying,
    subject_id uuid,
    purpose character varying NOT NULL
);


--
-- Name: observations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.observations (
    id bigint NOT NULL,
    encounter_id uuid NOT NULL,
    user_id uuid NOT NULL,
    observable_type character varying,
    observable_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: observations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.observations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: observations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.observations_id_seq OWNED BY public.observations.id;


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizations (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    slug character varying
);


--
-- Name: passport_authentications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.passport_authentications (
    id bigint NOT NULL,
    access_token character varying NOT NULL,
    otp character varying NOT NULL,
    otp_expires_at timestamp without time zone NOT NULL,
    patient_business_identifier_id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: passport_authentications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.passport_authentications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: passport_authentications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.passport_authentications_id_seq OWNED BY public.passport_authentications.id;


--
-- Name: patient_registrations_per_day_per_facilities; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.patient_registrations_per_day_per_facilities AS
 SELECT count(patients.id) AS registration_count,
    patients.registration_facility_id AS facility_id,
    timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, facilities.deleted_at)) AS deleted_at,
    (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text AS day,
    (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text AS month,
    (date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text AS quarter,
    (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text AS year
   FROM ((public.patients
     JOIN public.facilities ON ((patients.registration_facility_id = facilities.id)))
     JOIN public.medical_histories ON (((patients.id = medical_histories.patient_id) AND (medical_histories.hypertension = 'yes'::text))))
  WHERE (patients.deleted_at IS NULL)
  GROUP BY (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text, (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text, (date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, patients.recorded_at))))::text, patients.registration_facility_id, facilities.deleted_at
  WITH NO DATA;


--
-- Name: patient_summaries; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.patient_summaries AS
 SELECT p.recorded_at,
    concat(date_part('year'::text, p.recorded_at), ' Q', date_part('quarter'::text, p.recorded_at)) AS registration_quarter,
    p.full_name,
        CASE
            WHEN (p.date_of_birth IS NOT NULL) THEN date_part('year'::text, age((p.date_of_birth)::timestamp with time zone))
            ELSE ((p.age)::double precision + date_part('years'::text, age(now(), (p.age_updated_at)::timestamp with time zone)))
        END AS current_age,
    p.gender,
    p.status,
    p.assigned_facility_id,
    latest_phone_number.number AS latest_phone_number,
    addresses.village_or_colony,
    addresses.street_address,
    addresses.district,
    addresses.state,
    reg_facility.name AS registration_facility_name,
    reg_facility.facility_type AS registration_facility_type,
    reg_facility.district AS registration_district,
    reg_facility.state AS registration_state,
    latest_blood_pressure.systolic AS latest_blood_pressure_systolic,
    latest_blood_pressure.diastolic AS latest_blood_pressure_diastolic,
    latest_blood_pressure.recorded_at AS latest_blood_pressure_recorded_at,
    concat(date_part('year'::text, latest_blood_pressure.recorded_at), ' Q', date_part('quarter'::text, latest_blood_pressure.recorded_at)) AS latest_blood_pressure_quarter,
    latest_blood_pressure_facility.name AS latest_blood_pressure_facility_name,
    latest_blood_pressure_facility.facility_type AS latest_blood_pressure_facility_type,
    latest_blood_pressure_facility.district AS latest_blood_pressure_district,
    latest_blood_pressure_facility.state AS latest_blood_pressure_state,
    latest_blood_sugar.blood_sugar_type AS latest_blood_sugar_type,
    latest_blood_sugar.blood_sugar_value AS latest_blood_sugar_value,
    latest_blood_sugar.recorded_at AS latest_blood_sugar_recorded_at,
    concat(date_part('year'::text, latest_blood_sugar.recorded_at), ' Q', date_part('quarter'::text, latest_blood_sugar.recorded_at)) AS latest_blood_sugar_quarter,
    latest_blood_sugar_facility.name AS latest_blood_sugar_facility_name,
    latest_blood_sugar_facility.facility_type AS latest_blood_sugar_facility_type,
    latest_blood_sugar_facility.district AS latest_blood_sugar_district,
    latest_blood_sugar_facility.state AS latest_blood_sugar_state,
    GREATEST((0)::double precision, date_part('day'::text, (now() - (next_appointment.scheduled_date)::timestamp with time zone))) AS days_overdue,
    next_appointment.id AS next_appointment_id,
    next_appointment.scheduled_date AS next_appointment_scheduled_date,
    next_appointment.status AS next_appointment_status,
    next_appointment.cancel_reason AS next_appointment_cancel_reason,
    next_appointment.remind_on AS next_appointment_remind_on,
    next_appointment_facility.id AS next_appointment_facility_id,
    next_appointment_facility.name AS next_appointment_facility_name,
    next_appointment_facility.facility_type AS next_appointment_facility_type,
    next_appointment_facility.district AS next_appointment_district,
    next_appointment_facility.state AS next_appointment_state,
        CASE
            WHEN (next_appointment.scheduled_date IS NULL) THEN 0
            WHEN (next_appointment.scheduled_date > date_trunc('day'::text, (now() - '30 days'::interval))) THEN 0
            WHEN ((latest_blood_pressure.systolic >= 180) OR (latest_blood_pressure.diastolic >= 110)) THEN 1
            WHEN (((mh.prior_heart_attack = 'yes'::text) OR (mh.prior_stroke = 'yes'::text)) AND ((latest_blood_pressure.systolic >= 140) OR (latest_blood_pressure.diastolic >= 90))) THEN 1
            WHEN ((((latest_blood_sugar.blood_sugar_type)::text = 'random'::text) AND (latest_blood_sugar.blood_sugar_value >= (300)::numeric)) OR (((latest_blood_sugar.blood_sugar_type)::text = 'post_prandial'::text) AND (latest_blood_sugar.blood_sugar_value >= (300)::numeric)) OR (((latest_blood_sugar.blood_sugar_type)::text = 'fasting'::text) AND (latest_blood_sugar.blood_sugar_value >= (200)::numeric)) OR (((latest_blood_sugar.blood_sugar_type)::text = 'hba1c'::text) AND (latest_blood_sugar.blood_sugar_value >= 9.0))) THEN 1
            ELSE 0
        END AS risk_level,
    latest_bp_passport.id AS latest_bp_passport_id,
    latest_bp_passport.identifier AS latest_bp_passport_identifier,
    p.id
   FROM (((((((((((public.patients p
     LEFT JOIN public.addresses ON ((addresses.id = p.address_id)))
     LEFT JOIN public.facilities reg_facility ON ((reg_facility.id = p.registration_facility_id)))
     LEFT JOIN public.medical_histories mh ON ((mh.patient_id = p.id)))
     LEFT JOIN LATERAL ( SELECT ppn.id,
            ppn.number,
            ppn.phone_type,
            ppn.active,
            ppn.created_at,
            ppn.updated_at,
            ppn.patient_id,
            ppn.device_created_at,
            ppn.device_updated_at,
            ppn.deleted_at,
            ppn.dnd_status
           FROM public.patient_phone_numbers ppn
          WHERE (ppn.patient_id = p.id)
          ORDER BY ppn.device_created_at DESC
         LIMIT 1) latest_phone_number ON (true))
     LEFT JOIN LATERAL ( SELECT bp.id,
            bp.systolic,
            bp.diastolic,
            bp.patient_id,
            bp.created_at,
            bp.updated_at,
            bp.device_created_at,
            bp.device_updated_at,
            bp.facility_id,
            bp.user_id,
            bp.deleted_at,
            bp.recorded_at
           FROM public.blood_pressures bp
          WHERE (bp.patient_id = p.id)
          ORDER BY bp.recorded_at DESC
         LIMIT 1) latest_blood_pressure ON (true))
     LEFT JOIN public.facilities latest_blood_pressure_facility ON ((latest_blood_pressure_facility.id = latest_blood_pressure.facility_id)))
     LEFT JOIN LATERAL ( SELECT bs.id,
            bs.blood_sugar_type,
            bs.blood_sugar_value,
            bs.patient_id,
            bs.user_id,
            bs.facility_id,
            bs.device_created_at,
            bs.device_updated_at,
            bs.deleted_at,
            bs.recorded_at,
            bs.created_at,
            bs.updated_at
           FROM public.blood_sugars bs
          WHERE (bs.patient_id = p.id)
          ORDER BY bs.recorded_at DESC
         LIMIT 1) latest_blood_sugar ON (true))
     LEFT JOIN public.facilities latest_blood_sugar_facility ON ((latest_blood_sugar_facility.id = latest_blood_sugar.facility_id)))
     LEFT JOIN LATERAL ( SELECT bp_passport.id,
            bp_passport.identifier,
            bp_passport.identifier_type,
            bp_passport.patient_id,
            bp_passport.metadata_version,
            bp_passport.metadata,
            bp_passport.device_created_at,
            bp_passport.device_updated_at,
            bp_passport.deleted_at,
            bp_passport.created_at,
            bp_passport.updated_at
           FROM public.patient_business_identifiers bp_passport
          WHERE (((bp_passport.identifier_type)::text = 'simple_bp_passport'::text) AND (bp_passport.patient_id = p.id))
          ORDER BY bp_passport.device_created_at DESC
         LIMIT 1) latest_bp_passport ON (true))
     LEFT JOIN LATERAL ( SELECT a.id,
            a.patient_id,
            a.facility_id,
            a.scheduled_date,
            a.status,
            a.cancel_reason,
            a.device_created_at,
            a.device_updated_at,
            a.created_at,
            a.updated_at,
            a.remind_on,
            a.agreed_to_visit,
            a.deleted_at,
            a.appointment_type,
            a.user_id,
            a.creation_facility_id
           FROM public.appointments a
          WHERE (a.patient_id = p.id)
          ORDER BY a.scheduled_date DESC
         LIMIT 1) next_appointment ON (true))
     LEFT JOIN public.facilities next_appointment_facility ON ((next_appointment_facility.id = next_appointment.facility_id)))
  WHERE (p.deleted_at IS NULL);


--
-- Name: phone_number_authentications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.phone_number_authentications (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    phone_number character varying NOT NULL,
    password_digest character varying NOT NULL,
    otp character varying NOT NULL,
    otp_expires_at timestamp without time zone NOT NULL,
    logged_in_at timestamp without time zone,
    access_token character varying NOT NULL,
    registration_facility_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    failed_attempts integer DEFAULT 0 NOT NULL,
    locked_at timestamp without time zone
);


--
-- Name: prescription_drugs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prescription_drugs (
    id uuid NOT NULL,
    name character varying NOT NULL,
    rxnorm_code character varying,
    dosage character varying,
    device_created_at timestamp without time zone NOT NULL,
    device_updated_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    patient_id uuid NOT NULL,
    facility_id uuid NOT NULL,
    is_protocol_drug boolean NOT NULL,
    is_deleted boolean NOT NULL,
    deleted_at timestamp without time zone,
    user_id uuid,
    frequency character varying,
    duration_in_days integer,
    teleconsultation_id uuid
);


--
-- Name: protocol_drugs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.protocol_drugs (
    id uuid NOT NULL,
    name character varying NOT NULL,
    dosage character varying NOT NULL,
    rxnorm_code character varying,
    protocol_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    drug_category character varying,
    stock_tracked boolean DEFAULT false NOT NULL
);


--
-- Name: protocols; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.protocols (
    id uuid NOT NULL,
    name character varying NOT NULL,
    follow_up_days integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: raw_to_clean_medicines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.raw_to_clean_medicines (
    raw_name character varying NOT NULL,
    raw_dosage character varying NOT NULL,
    rxcui bigint NOT NULL
);


--
-- Name: regions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regions (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    description character varying,
    source_type character varying,
    source_id uuid,
    path public.ltree,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    region_type character varying NOT NULL
);


--
-- Name: reminder_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reminder_templates (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    message character varying NOT NULL,
    remind_on_in_days integer NOT NULL,
    treatment_group_id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: reporting_daily_follow_ups; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.reporting_daily_follow_ups AS
 WITH follow_up_blood_pressures AS (
         SELECT DISTINCT ON (p.id, bp.facility_id, ((date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at))))::integer)) p.id AS patient_id,
            (p.gender)::public.gender_enum AS patient_gender,
            bp.id AS visit_id,
            'BloodPressure'::text AS visit_type,
            bp.facility_id,
            bp.user_id,
            bp.recorded_at AS visited_at,
            (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at))))::integer AS day_of_year
           FROM (public.patients p
             JOIN public.blood_pressures bp ON (((p.id = bp.patient_id) AND (date_trunc('day'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at))) > date_trunc('day'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))))))
          WHERE ((p.deleted_at IS NULL) AND (bp.recorded_at > (CURRENT_TIMESTAMP - '30 days'::interval)))
        ), follow_up_blood_sugars AS (
         SELECT DISTINCT ON (p.id, bs.facility_id, ((date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bs.recorded_at))))::integer)) p.id AS patient_id,
            (p.gender)::public.gender_enum AS patient_gender,
            bs.id AS visit_id,
            'BloodSugar'::text AS visit_type,
            bs.facility_id,
            bs.user_id,
            bs.recorded_at AS visited_at,
            (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bs.recorded_at))))::integer AS day_of_year
           FROM (public.patients p
             JOIN public.blood_sugars bs ON (((p.id = bs.patient_id) AND (date_trunc('day'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bs.recorded_at))) > date_trunc('day'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))))))
          WHERE ((p.deleted_at IS NULL) AND (bs.recorded_at > (CURRENT_TIMESTAMP - '30 days'::interval)))
        ), follow_up_prescription_drugs AS (
         SELECT DISTINCT ON (p.id, pd.facility_id, ((date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, pd.device_created_at))))::integer)) p.id AS patient_id,
            (p.gender)::public.gender_enum AS patient_gender,
            pd.id AS visit_id,
            'PrescriptionDrug'::text AS visit_type,
            pd.facility_id,
            pd.user_id,
            pd.device_created_at AS visited_at,
            (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, pd.device_created_at))))::integer AS day_of_year
           FROM (public.patients p
             JOIN public.prescription_drugs pd ON (((p.id = pd.patient_id) AND (date_trunc('day'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, pd.device_created_at))) > date_trunc('day'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))))))
          WHERE ((p.deleted_at IS NULL) AND (pd.device_created_at > (CURRENT_TIMESTAMP - '30 days'::interval)))
        ), follow_up_appointments AS (
         SELECT DISTINCT ON (p.id, app.creation_facility_id, ((date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, app.device_created_at))))::integer)) p.id AS patient_id,
            (p.gender)::public.gender_enum AS patient_gender,
            app.id AS visit_id,
            'Appointment'::text AS visit_type,
            app.creation_facility_id AS facility_id,
            app.user_id,
            app.device_created_at AS visited_at,
            (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, app.device_created_at))))::integer AS day_of_year
           FROM (public.patients p
             JOIN public.appointments app ON (((p.id = app.patient_id) AND (date_trunc('day'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, app.device_created_at))) > date_trunc('day'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))))))
          WHERE ((p.deleted_at IS NULL) AND (app.device_created_at > (CURRENT_TIMESTAMP - '30 days'::interval)))
        ), all_follow_ups AS (
         SELECT follow_up_blood_pressures.patient_id,
            follow_up_blood_pressures.patient_gender,
            follow_up_blood_pressures.visit_id,
            follow_up_blood_pressures.visit_type,
            follow_up_blood_pressures.facility_id,
            follow_up_blood_pressures.user_id,
            follow_up_blood_pressures.visited_at,
            follow_up_blood_pressures.day_of_year
           FROM follow_up_blood_pressures
        UNION
         SELECT follow_up_blood_sugars.patient_id,
            follow_up_blood_sugars.patient_gender,
            follow_up_blood_sugars.visit_id,
            follow_up_blood_sugars.visit_type,
            follow_up_blood_sugars.facility_id,
            follow_up_blood_sugars.user_id,
            follow_up_blood_sugars.visited_at,
            follow_up_blood_sugars.day_of_year
           FROM follow_up_blood_sugars
        UNION
         SELECT follow_up_prescription_drugs.patient_id,
            follow_up_prescription_drugs.patient_gender,
            follow_up_prescription_drugs.visit_id,
            follow_up_prescription_drugs.visit_type,
            follow_up_prescription_drugs.facility_id,
            follow_up_prescription_drugs.user_id,
            follow_up_prescription_drugs.visited_at,
            follow_up_prescription_drugs.day_of_year
           FROM follow_up_prescription_drugs
        UNION
         SELECT follow_up_appointments.patient_id,
            follow_up_appointments.patient_gender,
            follow_up_appointments.visit_id,
            follow_up_appointments.visit_type,
            follow_up_appointments.facility_id,
            follow_up_appointments.user_id,
            follow_up_appointments.visited_at,
            follow_up_appointments.day_of_year
           FROM follow_up_appointments
        )
 SELECT DISTINCT ON (all_follow_ups.day_of_year, all_follow_ups.facility_id, all_follow_ups.patient_id) all_follow_ups.patient_id,
    all_follow_ups.patient_gender,
    all_follow_ups.facility_id,
    mh.diabetes,
    mh.hypertension,
    all_follow_ups.user_id,
    all_follow_ups.visit_id,
    all_follow_ups.visit_type,
    all_follow_ups.visited_at,
    all_follow_ups.day_of_year
   FROM (all_follow_ups
     JOIN public.medical_histories mh ON ((all_follow_ups.patient_id = mh.patient_id)))
  WITH NO DATA;


--
-- Name: reporting_facilities; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.reporting_facilities AS
 SELECT facilities.id AS facility_id,
    facilities.name AS facility_name,
    facilities.facility_type,
    facilities.facility_size,
    facility_regions.id AS facility_region_id,
    facility_regions.name AS facility_region_name,
    facility_regions.slug AS facility_region_slug,
    block_regions.id AS block_region_id,
    block_regions.name AS block_name,
    block_regions.slug AS block_slug,
    district_regions.source_id AS district_id,
    district_regions.id AS district_region_id,
    district_regions.name AS district_name,
    district_regions.slug AS district_slug,
    state_regions.id AS state_region_id,
    state_regions.name AS state_name,
    state_regions.slug AS state_slug,
    org_regions.source_id AS organization_id,
    org_regions.id AS organization_region_id,
    org_regions.name AS organization_name,
    org_regions.slug AS organization_slug
   FROM (((((public.regions facility_regions
     JOIN public.facilities ON ((facilities.id = facility_regions.source_id)))
     JOIN public.regions block_regions ON ((block_regions.path OPERATOR(public.=) public.subpath(facility_regions.path, 0, '-1'::integer))))
     JOIN public.regions district_regions ON ((district_regions.path OPERATOR(public.=) public.subpath(block_regions.path, 0, '-1'::integer))))
     JOIN public.regions state_regions ON ((state_regions.path OPERATOR(public.=) public.subpath(district_regions.path, 0, '-1'::integer))))
     JOIN public.regions org_regions ON ((org_regions.path OPERATOR(public.=) public.subpath(state_regions.path, 0, '-1'::integer))))
  WHERE ((facility_regions.region_type)::text = 'facility'::text);


--
-- Name: VIEW reporting_facilities; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.reporting_facilities IS 'List of Simple facililities with size, type, and geographical information. These facilities are used to segment reports by region.';


--
-- Name: COLUMN reporting_facilities.facility_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.facility_id IS 'ID of the facility';


--
-- Name: COLUMN reporting_facilities.facility_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.facility_name IS 'Name of the facility';


--
-- Name: COLUMN reporting_facilities.facility_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.facility_type IS 'Type of the facility (eg. ''District Hospital'')';


--
-- Name: COLUMN reporting_facilities.facility_size; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.facility_size IS 'Size of the facility (community, small, medium, large)';


--
-- Name: COLUMN reporting_facilities.facility_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.facility_region_id IS 'ID of the facility region';


--
-- Name: COLUMN reporting_facilities.facility_region_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.facility_region_name IS 'Name of the facility region. Usually the same as the facility name';


--
-- Name: COLUMN reporting_facilities.facility_region_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.facility_region_slug IS 'Human readable ID of the facility region';


--
-- Name: COLUMN reporting_facilities.block_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.block_region_id IS 'ID of the block region that the facility is in';


--
-- Name: COLUMN reporting_facilities.block_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.block_name IS 'Name of the block region that the facility is in';


--
-- Name: COLUMN reporting_facilities.block_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.block_slug IS 'Human readable ID of the block region that the facility is in';


--
-- Name: COLUMN reporting_facilities.district_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.district_id IS 'ID of the facility group that the facility is in';


--
-- Name: COLUMN reporting_facilities.district_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.district_region_id IS 'ID of the district region that the facility is in';


--
-- Name: COLUMN reporting_facilities.district_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.district_name IS 'Name of the district region that the facility is in';


--
-- Name: COLUMN reporting_facilities.district_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.district_slug IS 'Human readable ID of the district region that the facility is in';


--
-- Name: COLUMN reporting_facilities.state_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.state_region_id IS 'ID of the state region that the facility is in';


--
-- Name: COLUMN reporting_facilities.state_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.state_name IS 'Name of the state region that the facility is in';


--
-- Name: COLUMN reporting_facilities.state_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.state_slug IS 'Human readable ID of the state region that the facility is in';


--
-- Name: COLUMN reporting_facilities.organization_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.organization_id IS 'ID of the organization that the facility is in';


--
-- Name: COLUMN reporting_facilities.organization_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.organization_region_id IS 'ID of the organization region that the facility is in';


--
-- Name: COLUMN reporting_facilities.organization_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.organization_name IS 'Name of the organization region that the facility is in';


--
-- Name: COLUMN reporting_facilities.organization_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facilities.organization_slug IS 'Human readable ID of the organization region that the facility is in';


--
-- Name: reporting_facility_appointment_scheduled_days; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.reporting_facility_appointment_scheduled_days AS
 WITH latest_appointments_per_patient_per_month AS (
         SELECT DISTINCT ON (a.patient_id, (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, a.device_created_at)), 'YYYY-MM-01'::text))::date) a.id,
            a.patient_id,
            a.facility_id,
            a.scheduled_date,
            a.status,
            a.cancel_reason,
            a.device_created_at,
            a.device_updated_at,
            a.created_at,
            a.updated_at,
            a.remind_on,
            a.agreed_to_visit,
            a.deleted_at,
            a.appointment_type,
            a.user_id,
            a.creation_facility_id,
            (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, a.device_created_at)), 'YYYY-MM-01'::text))::date AS month_date
           FROM ((public.appointments a
             JOIN public.patients p ON ((p.id = a.patient_id)))
             JOIN public.medical_histories mh ON ((mh.patient_id = a.patient_id)))
          WHERE ((a.scheduled_date >= date_trunc('day'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, a.device_created_at)))) AND (a.device_created_at >= date_trunc('month'::text, (timezone('UTC'::text, now()) - '6 mons'::interval))) AND (date_trunc('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, a.device_created_at))) > date_trunc('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))) AND (p.deleted_at IS NULL) AND (a.deleted_at IS NULL) AND (mh.hypertension = 'yes'::text))
          ORDER BY a.patient_id, (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, a.device_created_at)), 'YYYY-MM-01'::text))::date, a.device_created_at DESC
        ), scheduled_days_distribution AS (
         SELECT latest_appointments_per_patient_per_month.month_date,
            width_bucket((date_part('days'::text, ((latest_appointments_per_patient_per_month.scheduled_date)::timestamp without time zone - date_trunc('day'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, latest_appointments_per_patient_per_month.device_created_at))))))::integer, ARRAY[0, 15, 32, 63]) AS bucket,
            count(*) AS number_of_appointments,
            latest_appointments_per_patient_per_month.creation_facility_id AS facility_id
           FROM latest_appointments_per_patient_per_month
          GROUP BY (width_bucket((date_part('days'::text, ((latest_appointments_per_patient_per_month.scheduled_date)::timestamp without time zone - date_trunc('day'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, latest_appointments_per_patient_per_month.device_created_at))))))::integer, ARRAY[0, 15, 32, 63])), latest_appointments_per_patient_per_month.creation_facility_id, latest_appointments_per_patient_per_month.month_date
        )
 SELECT scheduled_days_distribution.facility_id,
    scheduled_days_distribution.month_date,
    (sum(scheduled_days_distribution.number_of_appointments) FILTER (WHERE (scheduled_days_distribution.bucket = 1)))::integer AS appts_scheduled_0_to_14_days,
    (sum(scheduled_days_distribution.number_of_appointments) FILTER (WHERE (scheduled_days_distribution.bucket = 2)))::integer AS appts_scheduled_15_to_31_days,
    (sum(scheduled_days_distribution.number_of_appointments) FILTER (WHERE (scheduled_days_distribution.bucket = 3)))::integer AS appts_scheduled_32_to_62_days,
    (sum(scheduled_days_distribution.number_of_appointments) FILTER (WHERE (scheduled_days_distribution.bucket = 4)))::integer AS appts_scheduled_more_than_62_days,
    (sum(scheduled_days_distribution.number_of_appointments))::integer AS total_appts_scheduled
   FROM scheduled_days_distribution
  GROUP BY scheduled_days_distribution.facility_id, scheduled_days_distribution.month_date
  WITH NO DATA;


--
-- Name: reporting_months; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.reporting_months AS
 WITH month_dates AS (
         SELECT date(generate_series.generate_series) AS month_date
           FROM generate_series(('2018-01-01'::date)::timestamp with time zone, (CURRENT_DATE)::timestamp with time zone, '1 mon'::interval) generate_series(generate_series)
        )
 SELECT month_dates.month_date,
    date_part('month'::text, month_dates.month_date) AS month,
    date_part('quarter'::text, month_dates.month_date) AS quarter,
    date_part('year'::text, month_dates.month_date) AS year,
    to_char((month_dates.month_date)::timestamp with time zone, 'YYYY-MM'::text) AS month_string,
    to_char((month_dates.month_date)::timestamp with time zone, 'YYYY-Q'::text) AS quarter_string
   FROM month_dates;


--
-- Name: VIEW reporting_months; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.reporting_months IS 'List of calendar months with relevant calendar information. These months are used to segment reports by time into monthly or quarterly reports.';


--
-- Name: COLUMN reporting_months.month_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_months.month_date IS 'A date representing the first day of the month';


--
-- Name: COLUMN reporting_months.month; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_months.month IS 'The ordinal number of the month in the year. Eg. January = 1, February = 2, March = 3, etc.';


--
-- Name: COLUMN reporting_months.quarter; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_months.quarter IS 'The quarter number that the month falls in. Jan-Mar = 1, Apr-June = 2, Jul-Sept = 3, Oct-Dec = 4';


--
-- Name: COLUMN reporting_months.year; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_months.year IS 'The calendar year';


--
-- Name: COLUMN reporting_months.month_string; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_months.month_string IS 'A human readable version of the month in YYYY-MM format';


--
-- Name: COLUMN reporting_months.quarter_string; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_months.quarter_string IS 'A human readable version of the quarter that the month is in, in YYYY-Q format';


--
-- Name: reporting_patient_blood_pressures; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.reporting_patient_blood_pressures AS
 SELECT DISTINCT ON (bp.patient_id, cal.month_date) cal.month_date,
    cal.month,
    cal.quarter,
    cal.year,
    cal.month_string,
    cal.quarter_string,
    timezone('UTC'::text, timezone('UTC'::text, bp.recorded_at)) AS blood_pressure_recorded_at,
    bp.id AS blood_pressure_id,
    bp.patient_id,
    bp.systolic,
    bp.diastolic,
    bp.facility_id AS blood_pressure_facility_id,
    timezone('UTC'::text, timezone('UTC'::text, p.recorded_at)) AS patient_registered_at,
    p.assigned_facility_id AS patient_assigned_facility_id,
    p.registration_facility_id AS patient_registration_facility_id,
    (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))) * (12)::double precision) + (cal.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at))))) AS months_since_registration,
    (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))) * (4)::double precision) + (cal.quarter - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at))))) AS quarters_since_registration,
    (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at)))) * (12)::double precision) + (cal.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at))))) AS months_since_bp,
    (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at)))) * (4)::double precision) + (cal.quarter - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at))))) AS quarters_since_bp
   FROM ((public.blood_pressures bp
     LEFT JOIN public.reporting_months cal ON ((to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at)), 'YYYY-MM'::text) <= to_char((cal.month_date)::timestamp with time zone, 'YYYY-MM'::text))))
     JOIN public.patients p ON (((bp.patient_id = p.id) AND (p.deleted_at IS NULL))))
  WHERE (bp.deleted_at IS NULL)
  ORDER BY bp.patient_id, cal.month_date, bp.recorded_at DESC
  WITH NO DATA;


--
-- Name: reporting_patient_follow_ups; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.reporting_patient_follow_ups AS
 WITH follow_up_blood_pressures AS (
         SELECT DISTINCT ON (p.id, bp.facility_id, bp.user_id, (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at)), 'YYYY-MM'::text))) p.id AS patient_id,
            (p.gender)::public.gender_enum AS patient_gender,
            bp.id AS visit_id,
            'BloodPressure'::text AS visit_type,
            bp.facility_id,
            bp.user_id,
            bp.recorded_at AS visited_at,
            to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at)), 'YYYY-MM'::text) AS month_string
           FROM (public.patients p
             JOIN public.blood_pressures bp ON (((p.id = bp.patient_id) AND (date_trunc('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at))) > date_trunc('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))))))
          WHERE (p.deleted_at IS NULL)
        ), follow_up_blood_sugars AS (
         SELECT DISTINCT ON (p.id, bs.facility_id, bs.user_id, (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bs.recorded_at)), 'YYYY-MM'::text))) p.id AS patient_id,
            (p.gender)::public.gender_enum AS patient_gender,
            bs.id AS visit_id,
            'BloodSugar'::text AS visit_type,
            bs.facility_id,
            bs.user_id,
            bs.recorded_at AS visited_at,
            to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bs.recorded_at)), 'YYYY-MM'::text) AS month_string
           FROM (public.patients p
             JOIN public.blood_sugars bs ON (((p.id = bs.patient_id) AND (date_trunc('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bs.recorded_at))) > date_trunc('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))))))
          WHERE (p.deleted_at IS NULL)
        ), follow_up_prescription_drugs AS (
         SELECT DISTINCT ON (p.id, pd.facility_id, pd.user_id, (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, pd.device_created_at)), 'YYYY-MM'::text))) p.id AS patient_id,
            (p.gender)::public.gender_enum AS patient_gender,
            pd.id AS visit_id,
            'PrescriptionDrug'::text AS visit_type,
            pd.facility_id,
            pd.user_id,
            pd.device_created_at AS visited_at,
            to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, pd.device_created_at)), 'YYYY-MM'::text) AS month_string
           FROM (public.patients p
             JOIN public.prescription_drugs pd ON (((p.id = pd.patient_id) AND (date_trunc('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, pd.device_created_at))) > date_trunc('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))))))
          WHERE (p.deleted_at IS NULL)
        ), follow_up_appointments AS (
         SELECT DISTINCT ON (p.id, app.creation_facility_id, app.user_id, (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, app.device_created_at)), 'YYYY-MM'::text))) p.id AS patient_id,
            (p.gender)::public.gender_enum AS patient_gender,
            app.id AS visit_id,
            'Appointment'::text AS visit_type,
            app.creation_facility_id AS facility_id,
            app.user_id,
            app.device_created_at AS visited_at,
            to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, app.device_created_at)), 'YYYY-MM'::text) AS month_string
           FROM (public.patients p
             JOIN public.appointments app ON (((p.id = app.patient_id) AND (date_trunc('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, app.device_created_at))) > date_trunc('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))))))
          WHERE (p.deleted_at IS NULL)
        ), all_follow_ups AS (
         SELECT follow_up_blood_pressures.patient_id,
            follow_up_blood_pressures.patient_gender,
            follow_up_blood_pressures.visit_id,
            follow_up_blood_pressures.visit_type,
            follow_up_blood_pressures.facility_id,
            follow_up_blood_pressures.user_id,
            follow_up_blood_pressures.visited_at,
            follow_up_blood_pressures.month_string
           FROM follow_up_blood_pressures
        UNION
         SELECT follow_up_blood_sugars.patient_id,
            follow_up_blood_sugars.patient_gender,
            follow_up_blood_sugars.visit_id,
            follow_up_blood_sugars.visit_type,
            follow_up_blood_sugars.facility_id,
            follow_up_blood_sugars.user_id,
            follow_up_blood_sugars.visited_at,
            follow_up_blood_sugars.month_string
           FROM follow_up_blood_sugars
        UNION
         SELECT follow_up_prescription_drugs.patient_id,
            follow_up_prescription_drugs.patient_gender,
            follow_up_prescription_drugs.visit_id,
            follow_up_prescription_drugs.visit_type,
            follow_up_prescription_drugs.facility_id,
            follow_up_prescription_drugs.user_id,
            follow_up_prescription_drugs.visited_at,
            follow_up_prescription_drugs.month_string
           FROM follow_up_prescription_drugs
        UNION
         SELECT follow_up_appointments.patient_id,
            follow_up_appointments.patient_gender,
            follow_up_appointments.visit_id,
            follow_up_appointments.visit_type,
            follow_up_appointments.facility_id,
            follow_up_appointments.user_id,
            follow_up_appointments.visited_at,
            follow_up_appointments.month_string
           FROM follow_up_appointments
        )
 SELECT DISTINCT ON (cal.month_string, all_follow_ups.facility_id, all_follow_ups.user_id, all_follow_ups.patient_id) all_follow_ups.patient_id,
    all_follow_ups.patient_gender,
    all_follow_ups.facility_id,
    mh.diabetes,
    mh.hypertension,
    all_follow_ups.user_id,
    all_follow_ups.visit_id,
    all_follow_ups.visit_type,
    all_follow_ups.visited_at,
    cal.month_date,
    cal.month,
    cal.quarter,
    cal.year,
    cal.month_string,
    cal.quarter_string
   FROM ((all_follow_ups
     JOIN public.medical_histories mh ON ((all_follow_ups.patient_id = mh.patient_id)))
     LEFT JOIN public.reporting_months cal ON ((all_follow_ups.month_string = cal.month_string)))
  ORDER BY cal.month_string DESC
  WITH NO DATA;


--
-- Name: reporting_patient_visits; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.reporting_patient_visits AS
 SELECT DISTINCT ON (p.id, p.month_date) p.id AS patient_id,
    p.month_date,
    p.month,
    p.quarter,
    p.year,
    p.month_string,
    p.quarter_string,
    p.assigned_facility_id,
    p.registration_facility_id,
    timezone('UTC'::text, timezone('UTC'::text, p.recorded_at)) AS patient_recorded_at,
    e.id AS encounter_id,
    e.facility_id AS encounter_facility_id,
    timezone('UTC'::text, timezone('UTC'::text, e.recorded_at)) AS encounter_recorded_at,
    pd.id AS prescription_drug_id,
    pd.facility_id AS prescription_drug_facility_id,
    timezone('UTC'::text, timezone('UTC'::text, pd.recorded_at)) AS prescription_drug_recorded_at,
    app.id AS appointment_id,
    app.creation_facility_id AS appointment_creation_facility_id,
    timezone('UTC'::text, timezone('UTC'::text, app.recorded_at)) AS appointment_recorded_at,
    array_remove(ARRAY[
        CASE
            WHEN (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, e.recorded_at)), 'YYYY-MM'::text) = p.month_string) THEN e.facility_id
            ELSE NULL::uuid
        END,
        CASE
            WHEN (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, pd.recorded_at)), 'YYYY-MM'::text) = p.month_string) THEN pd.facility_id
            ELSE NULL::uuid
        END,
        CASE
            WHEN (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, app.recorded_at)), 'YYYY-MM'::text) = p.month_string) THEN app.creation_facility_id
            ELSE NULL::uuid
        END], NULL::uuid) AS visited_facility_ids,
    timezone('UTC'::text, timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at))) AS visited_at,
    (((p.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p.recorded_at)))) * (12)::double precision) + (p.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p.recorded_at))))) AS months_since_registration,
    (((p.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p.recorded_at)))) * (4)::double precision) + (p.quarter - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p.recorded_at))))) AS quarters_since_registration,
    (((p.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at))))) * (12)::double precision) + (p.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at)))))) AS months_since_visit,
    (((p.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at))))) * (4)::double precision) + (p.quarter - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at)))))) AS quarters_since_visit
   FROM (((( SELECT p_1.id,
            p_1.full_name,
            p_1.age,
            p_1.gender,
            p_1.date_of_birth,
            p_1.status,
            p_1.created_at,
            p_1.updated_at,
            p_1.address_id,
            p_1.age_updated_at,
            p_1.device_created_at,
            p_1.device_updated_at,
            p_1.test_data,
            p_1.registration_facility_id,
            p_1.registration_user_id,
            p_1.deleted_at,
            p_1.contacted_by_counsellor,
            p_1.could_not_contact_reason,
            p_1.recorded_at,
            p_1.reminder_consent,
            p_1.deleted_by_user_id,
            p_1.deleted_reason,
            p_1.assigned_facility_id,
            cal.month_date,
            cal.month,
            cal.quarter,
            cal.year,
            cal.month_string,
            cal.quarter_string
           FROM (public.patients p_1
             LEFT JOIN public.reporting_months cal ON ((to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p_1.recorded_at)), 'YYYY-MM'::text) <= cal.month_string)))) p
     LEFT JOIN LATERAL ( SELECT timezone('UTC'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), (encounters.encountered_on)::timestamp without time zone)) AS recorded_at,
            encounters.id,
            encounters.facility_id,
            encounters.patient_id,
            encounters.encountered_on,
            encounters.timezone_offset,
            encounters.notes,
            encounters.metadata,
            encounters.device_created_at,
            encounters.device_updated_at,
            encounters.deleted_at,
            encounters.created_at,
            encounters.updated_at
           FROM public.encounters
          WHERE ((encounters.patient_id = p.id) AND (to_char((encounters.encountered_on)::timestamp with time zone, 'YYYY-MM'::text) <= p.month_string) AND (encounters.deleted_at IS NULL))
          ORDER BY encounters.encountered_on DESC
         LIMIT 1) e ON (true))
     LEFT JOIN LATERAL ( SELECT prescription_drugs.device_created_at AS recorded_at,
            prescription_drugs.id,
            prescription_drugs.name,
            prescription_drugs.rxnorm_code,
            prescription_drugs.dosage,
            prescription_drugs.device_created_at,
            prescription_drugs.device_updated_at,
            prescription_drugs.created_at,
            prescription_drugs.updated_at,
            prescription_drugs.patient_id,
            prescription_drugs.facility_id,
            prescription_drugs.is_protocol_drug,
            prescription_drugs.is_deleted,
            prescription_drugs.deleted_at,
            prescription_drugs.user_id,
            prescription_drugs.frequency,
            prescription_drugs.duration_in_days,
            prescription_drugs.teleconsultation_id
           FROM public.prescription_drugs
          WHERE ((prescription_drugs.patient_id = p.id) AND (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, prescription_drugs.device_created_at)), 'YYYY-MM'::text) <= p.month_string) AND (prescription_drugs.deleted_at IS NULL))
          ORDER BY prescription_drugs.device_created_at DESC
         LIMIT 1) pd ON (true))
     LEFT JOIN LATERAL ( SELECT appointments.device_created_at AS recorded_at,
            appointments.id,
            appointments.patient_id,
            appointments.facility_id,
            appointments.scheduled_date,
            appointments.status,
            appointments.cancel_reason,
            appointments.device_created_at,
            appointments.device_updated_at,
            appointments.created_at,
            appointments.updated_at,
            appointments.remind_on,
            appointments.agreed_to_visit,
            appointments.deleted_at,
            appointments.appointment_type,
            appointments.user_id,
            appointments.creation_facility_id
           FROM public.appointments
          WHERE ((appointments.patient_id = p.id) AND (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, appointments.device_created_at)), 'YYYY-MM'::text) <= p.month_string) AND (appointments.deleted_at IS NULL))
          ORDER BY appointments.device_created_at DESC
         LIMIT 1) app ON (true))
  WHERE (p.deleted_at IS NULL)
  ORDER BY p.id, p.month_date, (timezone('UTC'::text, timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at)))) DESC
  WITH NO DATA;


--
-- Name: reporting_prescriptions; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.reporting_prescriptions AS
 SELECT p.id AS patient_id,
    p.month_date,
    COALESCE(max(prescriptions.clean_dosage) FILTER (WHERE ((prescriptions.clean_name)::text = 'Amlodipine'::text)), (0)::double precision) AS amlodipine,
    COALESCE(max(prescriptions.clean_dosage) FILTER (WHERE ((prescriptions.clean_name)::text = 'Telmisartan'::text)), (0)::double precision) AS telmisartan,
    COALESCE(max(prescriptions.clean_dosage) FILTER (WHERE ((prescriptions.clean_name)::text = 'Losartan Potassium'::text)), (0)::double precision) AS losartan,
    COALESCE(max(prescriptions.clean_dosage) FILTER (WHERE ((prescriptions.clean_name)::text = 'Atenolol'::text)), (0)::double precision) AS atenolol,
    COALESCE(max(prescriptions.clean_dosage) FILTER (WHERE ((prescriptions.clean_name)::text = 'Enalapril'::text)), (0)::double precision) AS enalapril,
    COALESCE(max(prescriptions.clean_dosage) FILTER (WHERE ((prescriptions.clean_name)::text = 'Chlorthalidone'::text)), (0)::double precision) AS chlorthalidone,
    COALESCE(max(prescriptions.clean_dosage) FILTER (WHERE ((prescriptions.clean_name)::text = 'Hydrochlorothiazide'::text)), (0)::double precision) AS hydrochlorothiazide,
    COALESCE(max(prescriptions.clean_dosage) FILTER (WHERE (((prescriptions.clean_name)::text <> ALL (ARRAY[('Amlodipine'::character varying)::text, ('Telmisartan'::character varying)::text, ('Losartan'::character varying)::text, ('Atenolol'::character varying)::text, ('Enalapril'::character varying)::text, ('Chlorthalidone'::character varying)::text, ('Hydrochlorothiazide'::character varying)::text])) AND (prescriptions.medicine_purpose_hypertension = true))), (0)::double precision) AS other_bp_medications
   FROM (( SELECT p_1.id,
            p_1.full_name,
            p_1.age,
            p_1.gender,
            p_1.date_of_birth,
            p_1.status,
            p_1.created_at,
            p_1.updated_at,
            p_1.address_id,
            p_1.age_updated_at,
            p_1.device_created_at,
            p_1.device_updated_at,
            p_1.test_data,
            p_1.registration_facility_id,
            p_1.registration_user_id,
            p_1.deleted_at,
            p_1.contacted_by_counsellor,
            p_1.could_not_contact_reason,
            p_1.recorded_at,
            p_1.reminder_consent,
            p_1.deleted_by_user_id,
            p_1.deleted_reason,
            p_1.assigned_facility_id,
            cal.month_date,
            cal.month,
            cal.quarter,
            cal.year,
            cal.month_string,
            cal.quarter_string
           FROM (public.patients p_1
             LEFT JOIN public.reporting_months cal ON ((to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p_1.recorded_at)), 'YYYY-MM'::text) <= cal.month_string)))
          WHERE (p_1.deleted_at IS NULL)) p
     LEFT JOIN LATERAL ( SELECT DISTINCT ON (clean.medicine) actual.name AS actual_name,
            actual.dosage AS actual_dosage,
            clean.medicine AS clean_name,
            clean.dosage AS clean_dosage,
            purpose.hypertension AS medicine_purpose_hypertension,
            purpose.diabetes AS medicine_purpose_diabetes
           FROM (((public.prescription_drugs actual
             LEFT JOIN public.raw_to_clean_medicines raw ON (((lower(regexp_replace((raw.raw_name)::text, '\s+'::text, ''::text, 'g'::text)) = lower(regexp_replace((actual.name)::text, '\s+'::text, ''::text, 'g'::text))) AND (lower(regexp_replace((raw.raw_dosage)::text, '\s+'::text, ''::text, 'g'::text)) = lower(regexp_replace((actual.dosage)::text, '\s+'::text, ''::text, 'g'::text))))))
             LEFT JOIN public.clean_medicine_to_dosages clean ON ((clean.rxcui = raw.rxcui)))
             LEFT JOIN public.medicine_purposes purpose ON (((clean.medicine)::text = (purpose.name)::text)))
          WHERE ((actual.patient_id = p.id) AND (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, actual.device_created_at)), 'YYYY-MM'::text) <= p.month_string) AND (actual.deleted_at IS NULL) AND ((actual.is_deleted = false) OR ((actual.is_deleted = true) AND (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, actual.device_updated_at)), 'YYYY-MM'::text) > p.month_string))))
          ORDER BY clean.medicine, actual.device_created_at DESC) prescriptions ON (true))
  GROUP BY p.id, p.month_date
  WITH NO DATA;


--
-- Name: reporting_patient_states; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.reporting_patient_states AS
 SELECT DISTINCT ON (p.id, cal.month_date) p.id AS patient_id,
    timezone('UTC'::text, timezone('UTC'::text, p.recorded_at)) AS recorded_at,
    p.status,
    p.gender,
    p.age,
    timezone('UTC'::text, timezone('UTC'::text, p.age_updated_at)) AS age_updated_at,
    p.date_of_birth,
    date_part('year'::text, COALESCE(age((p.date_of_birth)::timestamp with time zone), (make_interval(years => p.age) + age(p.age_updated_at)))) AS current_age,
    cal.month_date,
    cal.month,
    cal.quarter,
    cal.year,
    cal.month_string,
    cal.quarter_string,
    mh.hypertension,
    mh.prior_heart_attack,
    mh.prior_stroke,
    mh.chronic_kidney_disease,
    mh.receiving_treatment_for_hypertension,
    mh.diabetes,
    p.assigned_facility_id,
    assigned_facility.facility_size AS assigned_facility_size,
    assigned_facility.facility_type AS assigned_facility_type,
    assigned_facility.facility_region_slug AS assigned_facility_slug,
    assigned_facility.facility_region_id AS assigned_facility_region_id,
    assigned_facility.block_slug AS assigned_block_slug,
    assigned_facility.block_region_id AS assigned_block_region_id,
    assigned_facility.district_slug AS assigned_district_slug,
    assigned_facility.district_region_id AS assigned_district_region_id,
    assigned_facility.state_slug AS assigned_state_slug,
    assigned_facility.state_region_id AS assigned_state_region_id,
    assigned_facility.organization_slug AS assigned_organization_slug,
    assigned_facility.organization_region_id AS assigned_organization_region_id,
    p.registration_facility_id,
    registration_facility.facility_size AS registration_facility_size,
    registration_facility.facility_type AS registration_facility_type,
    registration_facility.facility_region_slug AS registration_facility_slug,
    registration_facility.facility_region_id AS registration_facility_region_id,
    registration_facility.block_slug AS registration_block_slug,
    registration_facility.block_region_id AS registration_block_region_id,
    registration_facility.district_slug AS registration_district_slug,
    registration_facility.district_region_id AS registration_district_region_id,
    registration_facility.state_slug AS registration_state_slug,
    registration_facility.state_region_id AS registration_state_region_id,
    registration_facility.organization_slug AS registration_organization_slug,
    registration_facility.organization_region_id AS registration_organization_region_id,
    bps.blood_pressure_id,
    bps.blood_pressure_facility_id AS bp_facility_id,
    bps.blood_pressure_recorded_at AS bp_recorded_at,
    bps.systolic,
    bps.diastolic,
    visits.encounter_id,
    visits.encounter_recorded_at,
    visits.prescription_drug_id,
    visits.prescription_drug_recorded_at,
    visits.appointment_id,
    visits.appointment_recorded_at,
    visits.visited_facility_ids,
    (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))) * (12)::double precision) + (cal.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at))))) AS months_since_registration,
    (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))) * (4)::double precision) + (cal.quarter - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at))))) AS quarters_since_registration,
    visits.months_since_visit,
    visits.quarters_since_visit,
    bps.months_since_bp,
    bps.quarters_since_bp,
        CASE
            WHEN ((bps.systolic IS NULL) OR (bps.diastolic IS NULL)) THEN 'unknown'::text
            WHEN ((bps.systolic < 140) AND (bps.diastolic < 90)) THEN 'controlled'::text
            ELSE 'uncontrolled'::text
        END AS last_bp_state,
        CASE
            WHEN ((p.status)::text = 'dead'::text) THEN 'dead'::text
            WHEN (((((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))) * (12)::double precision) + (cal.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at))))) < (12)::double precision) OR (visits.months_since_visit < (12)::double precision)) THEN 'under_care'::text
            ELSE 'lost_to_follow_up'::text
        END AS htn_care_state,
        CASE
            WHEN ((visits.months_since_visit >= (3)::double precision) OR (visits.months_since_visit IS NULL)) THEN 'missed_visit'::text
            WHEN ((bps.months_since_bp >= (3)::double precision) OR (bps.months_since_bp IS NULL)) THEN 'visited_no_bp'::text
            WHEN ((bps.systolic < 140) AND (bps.diastolic < 90)) THEN 'controlled'::text
            ELSE 'uncontrolled'::text
        END AS htn_treatment_outcome_in_last_3_months,
        CASE
            WHEN ((visits.months_since_visit >= (2)::double precision) OR (visits.months_since_visit IS NULL)) THEN 'missed_visit'::text
            WHEN ((bps.months_since_bp >= (2)::double precision) OR (bps.months_since_bp IS NULL)) THEN 'visited_no_bp'::text
            WHEN ((bps.systolic < 140) AND (bps.diastolic < 90)) THEN 'controlled'::text
            ELSE 'uncontrolled'::text
        END AS htn_treatment_outcome_in_last_2_months,
        CASE
            WHEN ((visits.quarters_since_visit >= (1)::double precision) OR (visits.quarters_since_visit IS NULL)) THEN 'missed_visit'::text
            WHEN ((bps.quarters_since_bp >= (1)::double precision) OR (bps.quarters_since_bp IS NULL)) THEN 'visited_no_bp'::text
            WHEN ((bps.systolic < 140) AND (bps.diastolic < 90)) THEN 'controlled'::text
            ELSE 'uncontrolled'::text
        END AS htn_treatment_outcome_in_quarter,
    ((current_meds.amlodipine > past_meds.amlodipine) OR (current_meds.telmisartan > past_meds.telmisartan) OR (current_meds.losartan > past_meds.losartan) OR (current_meds.atenolol > past_meds.atenolol) OR (current_meds.enalapril > past_meds.enalapril) OR (current_meds.chlorthalidone > past_meds.chlorthalidone) OR (current_meds.hydrochlorothiazide > past_meds.hydrochlorothiazide)) AS titrated
   FROM ((((((((public.patients p
     LEFT JOIN public.reporting_months cal ON ((to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)), 'YYYY-MM'::text) <= to_char((cal.month_date)::timestamp with time zone, 'YYYY-MM'::text))))
     LEFT JOIN public.reporting_patient_blood_pressures bps ON (((p.id = bps.patient_id) AND (cal.month = bps.month) AND (cal.year = bps.year))))
     LEFT JOIN public.reporting_patient_visits visits ON (((p.id = visits.patient_id) AND (cal.month = visits.month) AND (cal.year = visits.year))))
     LEFT JOIN public.medical_histories mh ON (((p.id = mh.patient_id) AND (mh.deleted_at IS NULL))))
     LEFT JOIN public.reporting_prescriptions current_meds ON (((current_meds.patient_id = p.id) AND (cal.month_date = current_meds.month_date))))
     LEFT JOIN public.reporting_prescriptions past_meds ON (((past_meds.patient_id = p.id) AND (cal.month_date = (past_meds.month_date + '1 mon'::interval)))))
     JOIN public.reporting_facilities registration_facility ON ((registration_facility.facility_id = p.registration_facility_id)))
     JOIN public.reporting_facilities assigned_facility ON ((assigned_facility.facility_id = p.assigned_facility_id)))
  WHERE (p.deleted_at IS NULL)
  ORDER BY p.id, cal.month_date
  WITH NO DATA;


--
-- Name: MATERIALIZED VIEW reporting_patient_states; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON MATERIALIZED VIEW public.reporting_patient_states IS 'Monthly summary of a patient''s information and health indicators. This table has one row per patient, per month, from the month of the patient''s registration.';


--
-- Name: COLUMN reporting_patient_states.patient_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.patient_id IS 'ID of the patient';


--
-- Name: COLUMN reporting_patient_states.recorded_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.recorded_at IS 'Time (in UTC) at which the patient was registered';


--
-- Name: COLUMN reporting_patient_states.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.status IS 'active, dead, migrated, etc';


--
-- Name: COLUMN reporting_patient_states.gender; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.gender IS 'Gender of the patient';


--
-- Name: COLUMN reporting_patient_states.age; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.age IS 'Age of the patient as entered by a nurse';


--
-- Name: COLUMN reporting_patient_states.age_updated_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.age_updated_at IS 'Time (in UTC) at which the field ''age'' was last updated';


--
-- Name: COLUMN reporting_patient_states.date_of_birth; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.date_of_birth IS 'Date of birth of the patient';


--
-- Name: COLUMN reporting_patient_states.current_age; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.current_age IS 'Patient''s age as of today, based on ''age'', ''age_updated_at'' and ''date_of_birth''. This will have the same value for a patient across all rows.';


--
-- Name: COLUMN reporting_patient_states.month_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.month_date IS 'The reporting month for this row, represented as the date at the beginning of the month';


--
-- Name: COLUMN reporting_patient_states.month; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.month IS 'Month (1-12) of year';


--
-- Name: COLUMN reporting_patient_states.quarter; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.quarter IS 'Quarter (1-4) of year';


--
-- Name: COLUMN reporting_patient_states.year; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.year IS 'Year in YYYY format';


--
-- Name: COLUMN reporting_patient_states.month_string; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.month_string IS 'String that represents a month, in YYYY-MM format';


--
-- Name: COLUMN reporting_patient_states.quarter_string; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.quarter_string IS 'String that represents a quarter, in YYYY-Q format';


--
-- Name: COLUMN reporting_patient_states.hypertension; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.hypertension IS 'Has the patient been diagnosed with hypertension? Values can be yes, no, unknown, or null if the data is unavailable.';


--
-- Name: COLUMN reporting_patient_states.prior_heart_attack; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.prior_heart_attack IS 'Has the patient had a heart attack? Values can be yes, no, unknown, or null if the data is unavailable.';


--
-- Name: COLUMN reporting_patient_states.prior_stroke; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.prior_stroke IS 'Has the patient has had a stroke? Values can be yes, no, unknown, or null if the data is unavailable.';


--
-- Name: COLUMN reporting_patient_states.chronic_kidney_disease; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.chronic_kidney_disease IS 'Has the patient had a chronic kidney disease? Values can be yes, no, unknown, or null if the data is unavailable.';


--
-- Name: COLUMN reporting_patient_states.receiving_treatment_for_hypertension; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.receiving_treatment_for_hypertension IS 'Was the patient already receiving treatment for hypertension during registration? Values can be yes, no, unknown, or null if the data is unavailable.';


--
-- Name: COLUMN reporting_patient_states.diabetes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.diabetes IS 'Has the patient been diagnosed with diabetes? Values can be yes, no, unknown, or null if the data is unavailable.';


--
-- Name: COLUMN reporting_patient_states.assigned_facility_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.assigned_facility_id IS 'ID of the patient''s assigned facility';


--
-- Name: COLUMN reporting_patient_states.assigned_facility_size; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.assigned_facility_size IS 'Size of the patient''s assigned facility';


--
-- Name: COLUMN reporting_patient_states.assigned_facility_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.assigned_facility_type IS 'Type of the patient''s assigned facility';


--
-- Name: COLUMN reporting_patient_states.assigned_facility_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.assigned_facility_slug IS 'Human readable ID of the patient''s assigned facility';


--
-- Name: COLUMN reporting_patient_states.assigned_facility_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.assigned_facility_region_id IS 'Region ID of the patient''s assigned facility';


--
-- Name: COLUMN reporting_patient_states.assigned_block_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.assigned_block_slug IS 'Human readable ID of the patient''s assigned facility''s block';


--
-- Name: COLUMN reporting_patient_states.assigned_block_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.assigned_block_region_id IS 'ID of the patient''s assigned facility''s block';


--
-- Name: COLUMN reporting_patient_states.assigned_district_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.assigned_district_slug IS 'Human readable ID of the patient''s assigned facility''s district';


--
-- Name: COLUMN reporting_patient_states.assigned_district_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.assigned_district_region_id IS 'ID of the patient''s assigned facility''s district';


--
-- Name: COLUMN reporting_patient_states.assigned_state_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.assigned_state_slug IS 'Human readable ID of the patient''s assigned facility''s state';


--
-- Name: COLUMN reporting_patient_states.assigned_state_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.assigned_state_region_id IS 'ID of the patient''s assigned facility''s state';


--
-- Name: COLUMN reporting_patient_states.assigned_organization_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.assigned_organization_slug IS 'Human readable ID of the patient''s assigned facility''s organization';


--
-- Name: COLUMN reporting_patient_states.assigned_organization_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.assigned_organization_region_id IS 'ID of the patient''s assigned facility''s organization';


--
-- Name: COLUMN reporting_patient_states.registration_facility_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.registration_facility_id IS 'ID of the patient''s registration facility';


--
-- Name: COLUMN reporting_patient_states.registration_facility_size; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.registration_facility_size IS 'Size of the patient''s registration facility';


--
-- Name: COLUMN reporting_patient_states.registration_facility_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.registration_facility_type IS 'Type of the patient''s registration facility';


--
-- Name: COLUMN reporting_patient_states.registration_facility_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.registration_facility_slug IS 'Human readable ID of the patient''s registration facility';


--
-- Name: COLUMN reporting_patient_states.registration_facility_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.registration_facility_region_id IS 'Region ID of the patient''s registration facility';


--
-- Name: COLUMN reporting_patient_states.registration_block_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.registration_block_slug IS 'Human readable ID of the patient''s registration facility''s block';


--
-- Name: COLUMN reporting_patient_states.registration_block_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.registration_block_region_id IS 'ID of the patient''s registration facility''s block';


--
-- Name: COLUMN reporting_patient_states.registration_district_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.registration_district_slug IS 'Human readable ID of the patient''s registration facility''s district';


--
-- Name: COLUMN reporting_patient_states.registration_district_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.registration_district_region_id IS 'ID of the patient''s registration facility''s district';


--
-- Name: COLUMN reporting_patient_states.registration_state_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.registration_state_slug IS 'Human readable ID of the patient''s registration facility''s state';


--
-- Name: COLUMN reporting_patient_states.registration_state_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.registration_state_region_id IS 'ID of the patient''s registration facility''s state';


--
-- Name: COLUMN reporting_patient_states.registration_organization_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.registration_organization_slug IS 'Human readable ID of the patient''s registration facility''s organization';


--
-- Name: COLUMN reporting_patient_states.registration_organization_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.registration_organization_region_id IS 'ID of the patient''s registration facility''s organization';


--
-- Name: COLUMN reporting_patient_states.blood_pressure_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.blood_pressure_id IS 'ID of the latest BP as of this month. Use this to join with the blood_pressures table.';


--
-- Name: COLUMN reporting_patient_states.bp_facility_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.bp_facility_id IS 'ID of the facility at which the latest BP was recorded as of this month';


--
-- Name: COLUMN reporting_patient_states.bp_recorded_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.bp_recorded_at IS 'Time (in UTC) at which the latest BP as of this month was recorded';


--
-- Name: COLUMN reporting_patient_states.systolic; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.systolic IS 'Systolic of the latest BP as of this month';


--
-- Name: COLUMN reporting_patient_states.diastolic; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.diastolic IS 'Diastolic of the latest BP as of this month';


--
-- Name: COLUMN reporting_patient_states.encounter_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.encounter_id IS 'ID of the latest encounter as of this month. Use this to join with the encounters table.';


--
-- Name: COLUMN reporting_patient_states.encounter_recorded_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.encounter_recorded_at IS 'Time (in UTC) at which the latest encounter as of this month was recorded';


--
-- Name: COLUMN reporting_patient_states.prescription_drug_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.prescription_drug_id IS 'ID of the latest prescription drug as of this month. Use this to join with the prescription drugs table.';


--
-- Name: COLUMN reporting_patient_states.prescription_drug_recorded_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.prescription_drug_recorded_at IS 'Time (in UTC) at which the latest prescription drug as of this month was recorded';


--
-- Name: COLUMN reporting_patient_states.appointment_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.appointment_id IS 'ID of the latest appointment as of this month. Use this to join with the appointments table.';


--
-- Name: COLUMN reporting_patient_states.appointment_recorded_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.appointment_recorded_at IS 'Time (in UTC) at which the latest appointment as of this month was recorded';


--
-- Name: COLUMN reporting_patient_states.visited_facility_ids; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.visited_facility_ids IS 'IDs of the facilities visited this month';


--
-- Name: COLUMN reporting_patient_states.months_since_registration; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.months_since_registration IS 'Number of months since registration. If a patient was registered on 31st Jan, it would be 1 month since registration on 1st Feb.';


--
-- Name: COLUMN reporting_patient_states.quarters_since_registration; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.quarters_since_registration IS 'Number of quarters since registration. If a patient was registered on 31st Dec, it would be 1 quarter since registration on 1st Jan.';


--
-- Name: COLUMN reporting_patient_states.months_since_visit; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.months_since_visit IS 'Number of months since the patient''s last visit. If a patient visited on 31st Jan, it would be 1 month since the visit on 1st Feb.';


--
-- Name: COLUMN reporting_patient_states.quarters_since_visit; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.quarters_since_visit IS 'Number of quarters since the patient''s last visit. If a patient visited on 31st Jan, it would be 1 quarter since the visit on 1st Jan.';


--
-- Name: COLUMN reporting_patient_states.months_since_bp; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.months_since_bp IS 'Number of months since the patient''s last BP recording. If a patient had a BP reading on 31st Jan, it would be 1 month since BP on 1st Feb.';


--
-- Name: COLUMN reporting_patient_states.quarters_since_bp; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.quarters_since_bp IS 'Number of quarters since the patient''s last BP recording. If a patient had a BP reading on 31st Jan, it would be 1 quarter since BP on 1st Jan.';


--
-- Name: COLUMN reporting_patient_states.last_bp_state; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.last_bp_state IS 'The state of the last BP recorded: controlled, uncontrolled, or unknown';


--
-- Name: COLUMN reporting_patient_states.htn_care_state; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.htn_care_state IS 'Is the patient under_care, lost_to_follow_up, or dead as of this month?';


--
-- Name: COLUMN reporting_patient_states.htn_treatment_outcome_in_last_3_months; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.htn_treatment_outcome_in_last_3_months IS 'For the visiting period of the last 3 months, is this patient''s treatment outcome controlled, uncontrolled, missed_visit, or visited_no_bp?';


--
-- Name: COLUMN reporting_patient_states.htn_treatment_outcome_in_last_2_months; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.htn_treatment_outcome_in_last_2_months IS 'For the visiting period of the last 2 months, is this patient''s treatment outcome controlled, uncontrolled, missed_visit, or visited_no_bp?';


--
-- Name: COLUMN reporting_patient_states.htn_treatment_outcome_in_quarter; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.htn_treatment_outcome_in_quarter IS 'For the visiting period of the current quarter, is this patient''s treatment outcome controlled, uncontrolled, missed_visit, or visited_no_bp?';


--
-- Name: COLUMN reporting_patient_states.titrated; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_patient_states.titrated IS 'True, if the patient had an increase in dosage of any hypertension drug in a visit this month.';


--
-- Name: reporting_facility_state_dimensions; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.reporting_facility_state_dimensions AS
 WITH monthly_registration_patient_states AS (
         SELECT reporting_patient_states.registration_facility_id AS facility_id,
            reporting_patient_states.month_date,
            reporting_patient_states.gender,
            reporting_patient_states.hypertension,
            reporting_patient_states.diabetes
           FROM public.reporting_patient_states
          WHERE (reporting_patient_states.months_since_registration = (0)::double precision)
        ), registered_patients AS (
         SELECT monthly_registration_patient_states.facility_id,
            monthly_registration_patient_states.month_date,
            count(*) AS monthly_registrations_all,
            count(*) FILTER (WHERE (monthly_registration_patient_states.hypertension = 'yes'::text)) AS monthly_registrations_htn_all,
            count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'female'::text))) AS monthly_registrations_htn_female,
            count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'male'::text))) AS monthly_registrations_htn_male,
            count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'transgender'::text))) AS monthly_registrations_htn_transgender,
            count(*) FILTER (WHERE (monthly_registration_patient_states.diabetes = 'yes'::text)) AS monthly_registrations_dm_all,
            count(*) FILTER (WHERE ((monthly_registration_patient_states.diabetes = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'female'::text))) AS monthly_registrations_dm_female,
            count(*) FILTER (WHERE ((monthly_registration_patient_states.diabetes = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'male'::text))) AS monthly_registrations_dm_male,
            count(*) FILTER (WHERE ((monthly_registration_patient_states.diabetes = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'transgender'::text))) AS monthly_registrations_dm_transgender
           FROM monthly_registration_patient_states
          GROUP BY monthly_registration_patient_states.facility_id, monthly_registration_patient_states.month_date
        ), follow_ups AS (
         SELECT reporting_patient_follow_ups.facility_id,
            reporting_patient_follow_ups.month_date,
            count(DISTINCT reporting_patient_follow_ups.patient_id) AS monthly_follow_ups_all,
            count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE (reporting_patient_follow_ups.hypertension = 'yes'::text)) AS monthly_follow_ups_htn_all,
            count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'female'::public.gender_enum))) AS monthly_follow_ups_htn_female,
            count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'male'::public.gender_enum))) AS monthly_follow_ups_htn_male,
            count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'transgender'::public.gender_enum))) AS monthly_follow_ups_htn_transgender,
            count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE (reporting_patient_follow_ups.diabetes = 'yes'::text)) AS monthly_follow_ups_dm_all,
            count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.diabetes = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'female'::public.gender_enum))) AS monthly_follow_ups_dm_female,
            count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.diabetes = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'male'::public.gender_enum))) AS monthly_follow_ups_dm_male,
            count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.diabetes = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'transgender'::public.gender_enum))) AS monthly_follow_ups_dm_transgender
           FROM public.reporting_patient_follow_ups
          GROUP BY reporting_patient_follow_ups.facility_id, reporting_patient_follow_ups.month_date
        )
 SELECT rf.facility_region_slug,
    rf.facility_id,
    rf.facility_region_id,
    rf.block_region_id,
    rf.district_region_id,
    rf.state_region_id,
    cal.month_date,
    registered_patients.monthly_registrations_all,
    registered_patients.monthly_registrations_htn_all,
    registered_patients.monthly_registrations_htn_male,
    registered_patients.monthly_registrations_htn_female,
    registered_patients.monthly_registrations_htn_transgender,
    registered_patients.monthly_registrations_dm_all,
    registered_patients.monthly_registrations_dm_male,
    registered_patients.monthly_registrations_dm_female,
    registered_patients.monthly_registrations_dm_transgender,
    follow_ups.monthly_follow_ups_all,
    follow_ups.monthly_follow_ups_htn_all,
    follow_ups.monthly_follow_ups_htn_female,
    follow_ups.monthly_follow_ups_htn_male,
    follow_ups.monthly_follow_ups_htn_transgender,
    follow_ups.monthly_follow_ups_dm_all,
    follow_ups.monthly_follow_ups_dm_female,
    follow_ups.monthly_follow_ups_dm_male,
    follow_ups.monthly_follow_ups_dm_transgender
   FROM (((public.reporting_facilities rf
     JOIN public.reporting_months cal ON (true))
     LEFT JOIN registered_patients ON (((registered_patients.month_date = cal.month_date) AND (registered_patients.facility_id = rf.facility_id))))
     LEFT JOIN follow_ups ON (((follow_ups.month_date = cal.month_date) AND (follow_ups.facility_id = rf.facility_id))))
  ORDER BY cal.month_date DESC
  WITH NO DATA;


--
-- Name: reporting_overdue_calls; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.reporting_overdue_calls AS
 SELECT DISTINCT ON (a.patient_id, cal.month_date) cal.month_date,
    cal.month_string,
    cal.month,
    cal.quarter,
    cal.year,
    timezone('UTC'::text, timezone('UTC'::text, cr.device_created_at)) AS call_result_created_at,
    cr.id AS call_result_id,
    cr.user_id,
    a.id AS appointment_id,
    a.facility_id AS appointment_facility_id,
    a.patient_id,
    appointment_facility.facility_size AS appointment_facility_size,
    appointment_facility.facility_type AS appointment_facility_type,
    appointment_facility.facility_region_slug AS appointment_facility_slug,
    appointment_facility.facility_region_id AS appointment_facility_region_id,
    appointment_facility.block_slug AS appointment_block_slug,
    appointment_facility.block_region_id AS appointment_block_region_id,
    appointment_facility.district_slug AS appointment_district_slug,
    appointment_facility.district_region_id AS appointment_district_region_id,
    appointment_facility.state_slug AS appointment_state_slug,
    appointment_facility.state_region_id AS appointment_state_region_id,
    appointment_facility.organization_slug AS appointment_organization_slug,
    appointment_facility.organization_region_id AS appointment_organization_region_id
   FROM (((public.call_results cr
     JOIN public.reporting_months cal ON ((to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, cr.device_created_at)), 'YYYY-MM'::text) = to_char((cal.month_date)::timestamp with time zone, 'YYYY-MM'::text))))
     JOIN public.appointments a ON (((cr.appointment_id = a.id) AND (a.deleted_at IS NULL))))
     JOIN public.reporting_facilities appointment_facility ON ((a.facility_id = appointment_facility.facility_id)))
  WHERE (cr.deleted_at IS NULL)
  ORDER BY a.patient_id, cal.month_date, cr.device_created_at DESC
  WITH NO DATA;


--
-- Name: reporting_facility_states; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.reporting_facility_states AS
 WITH registered_patients AS (
         SELECT reporting_patient_states.registration_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(*) AS cumulative_registrations,
            count(*) FILTER (WHERE (reporting_patient_states.months_since_registration = (0)::double precision)) AS monthly_registrations
           FROM public.reporting_patient_states
          WHERE (reporting_patient_states.hypertension = 'yes'::text)
          GROUP BY reporting_patient_states.registration_facility_region_id, reporting_patient_states.month_date
        ), assigned_patients AS (
         SELECT reporting_patient_states.assigned_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'under_care'::text)) AS under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text)) AS lost_to_follow_up,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'dead'::text)) AS dead,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state <> 'dead'::text)) AS cumulative_assigned_patients
           FROM public.reporting_patient_states
          WHERE (reporting_patient_states.hypertension = 'yes'::text)
          GROUP BY reporting_patient_states.assigned_facility_region_id, reporting_patient_states.month_date
        ), adjusted_outcomes AS (
         SELECT reporting_patient_states.assigned_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'controlled'::text))) AS controlled_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'uncontrolled'::text))) AS uncontrolled_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'missed_visit'::text))) AS missed_visit_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'visited_no_bp'::text))) AS visited_no_bp_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text) AND (reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'missed_visit'::text))) AS missed_visit_lost_to_follow_up,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text) AND (reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'visited_no_bp'::text))) AS visited_no_bp_lost_to_follow_up,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'under_care'::text)) AS patients_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text)) AS patients_lost_to_follow_up
           FROM public.reporting_patient_states
          WHERE ((reporting_patient_states.hypertension = 'yes'::text) AND (reporting_patient_states.months_since_registration >= (3)::double precision))
          GROUP BY reporting_patient_states.assigned_facility_region_id, reporting_patient_states.month_date
        ), monthly_cohort_outcomes AS (
         SELECT reporting_patient_states.assigned_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_last_2_months = 'controlled'::text)) AS controlled,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_last_2_months = 'uncontrolled'::text)) AS uncontrolled,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_last_2_months = 'missed_visit'::text)) AS missed_visit,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_last_2_months = 'visited_no_bp'::text)) AS visited_no_bp,
            count(DISTINCT reporting_patient_states.patient_id) AS patients
           FROM public.reporting_patient_states
          WHERE ((reporting_patient_states.hypertension = 'yes'::text) AND (reporting_patient_states.months_since_registration = (2)::double precision))
          GROUP BY reporting_patient_states.assigned_facility_region_id, reporting_patient_states.month_date
        ), monthly_overdue_calls AS (
         SELECT reporting_overdue_calls.appointment_facility_region_id AS region_id,
            reporting_overdue_calls.month_date,
            count(DISTINCT reporting_overdue_calls.appointment_id) AS call_results
           FROM public.reporting_overdue_calls
          GROUP BY reporting_overdue_calls.appointment_facility_region_id, reporting_overdue_calls.month_date
        ), monthly_follow_ups AS (
         SELECT reporting_patient_follow_ups.facility_id,
            reporting_patient_follow_ups.month_date,
            count(DISTINCT reporting_patient_follow_ups.patient_id) AS follow_ups
           FROM public.reporting_patient_follow_ups
          WHERE (reporting_patient_follow_ups.hypertension = 'yes'::text)
          GROUP BY reporting_patient_follow_ups.facility_id, reporting_patient_follow_ups.month_date
        )
 SELECT cal.month_date,
    cal.month,
    cal.quarter,
    cal.year,
    cal.month_string,
    cal.quarter_string,
    rf.facility_id,
    rf.facility_name,
    rf.facility_type,
    rf.facility_size,
    rf.facility_region_id,
    rf.facility_region_name,
    rf.facility_region_slug,
    rf.block_region_id,
    rf.block_name,
    rf.block_slug,
    rf.district_id,
    rf.district_region_id,
    rf.district_name,
    rf.district_slug,
    rf.state_region_id,
    rf.state_name,
    rf.state_slug,
    rf.organization_id,
    rf.organization_region_id,
    rf.organization_name,
    rf.organization_slug,
    registered_patients.cumulative_registrations,
    registered_patients.monthly_registrations,
    assigned_patients.under_care,
    assigned_patients.lost_to_follow_up,
    assigned_patients.dead,
    assigned_patients.cumulative_assigned_patients,
    adjusted_outcomes.controlled_under_care AS adjusted_controlled_under_care,
    adjusted_outcomes.uncontrolled_under_care AS adjusted_uncontrolled_under_care,
    adjusted_outcomes.missed_visit_under_care AS adjusted_missed_visit_under_care,
    adjusted_outcomes.visited_no_bp_under_care AS adjusted_visited_no_bp_under_care,
    adjusted_outcomes.missed_visit_lost_to_follow_up AS adjusted_missed_visit_lost_to_follow_up,
    adjusted_outcomes.visited_no_bp_lost_to_follow_up AS adjusted_visited_no_bp_lost_to_follow_up,
    adjusted_outcomes.patients_under_care AS adjusted_patients_under_care,
    adjusted_outcomes.patients_lost_to_follow_up AS adjusted_patients_lost_to_follow_up,
    monthly_cohort_outcomes.controlled AS monthly_cohort_controlled,
    monthly_cohort_outcomes.uncontrolled AS monthly_cohort_uncontrolled,
    monthly_cohort_outcomes.missed_visit AS monthly_cohort_missed_visit,
    monthly_cohort_outcomes.visited_no_bp AS monthly_cohort_visited_no_bp,
    monthly_cohort_outcomes.patients AS monthly_cohort_patients,
    monthly_overdue_calls.call_results AS monthly_overdue_calls,
    monthly_follow_ups.follow_ups AS monthly_follow_ups,
    reporting_facility_appointment_scheduled_days.total_appts_scheduled,
    reporting_facility_appointment_scheduled_days.appts_scheduled_0_to_14_days,
    reporting_facility_appointment_scheduled_days.appts_scheduled_15_to_31_days,
    reporting_facility_appointment_scheduled_days.appts_scheduled_32_to_62_days,
    reporting_facility_appointment_scheduled_days.appts_scheduled_more_than_62_days
   FROM ((((((((public.reporting_facilities rf
     JOIN public.reporting_months cal ON (true))
     LEFT JOIN registered_patients ON (((registered_patients.month_date = cal.month_date) AND (registered_patients.region_id = rf.facility_region_id))))
     LEFT JOIN assigned_patients ON (((assigned_patients.month_date = cal.month_date) AND (assigned_patients.region_id = rf.facility_region_id))))
     LEFT JOIN adjusted_outcomes ON (((adjusted_outcomes.month_date = cal.month_date) AND (adjusted_outcomes.region_id = rf.facility_region_id))))
     LEFT JOIN monthly_cohort_outcomes ON (((monthly_cohort_outcomes.month_date = cal.month_date) AND (monthly_cohort_outcomes.region_id = rf.facility_region_id))))
     LEFT JOIN monthly_overdue_calls ON (((monthly_overdue_calls.month_date = cal.month_date) AND (monthly_overdue_calls.region_id = rf.facility_region_id))))
     LEFT JOIN monthly_follow_ups ON (((monthly_follow_ups.month_date = cal.month_date) AND (monthly_follow_ups.facility_id = rf.facility_id))))
     LEFT JOIN public.reporting_facility_appointment_scheduled_days ON (((reporting_facility_appointment_scheduled_days.month_date = cal.month_date) AND (reporting_facility_appointment_scheduled_days.facility_id = rf.facility_id))))
  WITH NO DATA;


--
-- Name: MATERIALIZED VIEW reporting_facility_states; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON MATERIALIZED VIEW public.reporting_facility_states IS 'Monthly summary of a facility''s indicators. This table has one row per facility, per month, from the month of the facility''s first registration.';


--
-- Name: COLUMN reporting_facility_states.month_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.month_date IS 'The reporting month for this row, represented as the date at the beginning of the month';


--
-- Name: COLUMN reporting_facility_states.month; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.month IS 'Month (1-12) of year';


--
-- Name: COLUMN reporting_facility_states.quarter; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.quarter IS 'Quarter (1-4) of year';


--
-- Name: COLUMN reporting_facility_states.year; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.year IS 'Year in YYYY format';


--
-- Name: COLUMN reporting_facility_states.month_string; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.month_string IS 'String that represents a month, in YYYY-MM format';


--
-- Name: COLUMN reporting_facility_states.quarter_string; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.quarter_string IS 'String that represents a quarter, in YYYY-Q format';


--
-- Name: COLUMN reporting_facility_states.facility_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.facility_id IS 'ID of the facility';


--
-- Name: COLUMN reporting_facility_states.facility_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.facility_name IS 'Name of the facility';


--
-- Name: COLUMN reporting_facility_states.facility_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.facility_type IS 'Type of the facility (eg. ''District Hospital'')';


--
-- Name: COLUMN reporting_facility_states.facility_size; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.facility_size IS 'Size of the facility (community, small, medium, large)';


--
-- Name: COLUMN reporting_facility_states.facility_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.facility_region_id IS 'ID of the facility region';


--
-- Name: COLUMN reporting_facility_states.facility_region_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.facility_region_name IS 'Name of the facility region. Usually the same as the facility name';


--
-- Name: COLUMN reporting_facility_states.facility_region_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.facility_region_slug IS 'Human readable ID of the facility region';


--
-- Name: COLUMN reporting_facility_states.block_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.block_region_id IS 'ID of the block region that the facility is in';


--
-- Name: COLUMN reporting_facility_states.block_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.block_name IS 'Name of the block region that the facility is in';


--
-- Name: COLUMN reporting_facility_states.block_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.block_slug IS 'Human readable ID of the block region that the facility is in';


--
-- Name: COLUMN reporting_facility_states.district_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.district_id IS 'ID of the facility group that the facility is in';


--
-- Name: COLUMN reporting_facility_states.district_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.district_region_id IS 'ID of the district region that the facility is in';


--
-- Name: COLUMN reporting_facility_states.district_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.district_name IS 'Name of the district region that the facility is in';


--
-- Name: COLUMN reporting_facility_states.district_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.district_slug IS 'Human readable ID of the district region that the facility is in';


--
-- Name: COLUMN reporting_facility_states.state_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.state_region_id IS 'ID of the state region that the facility is in';


--
-- Name: COLUMN reporting_facility_states.state_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.state_name IS 'Name of the state region that the facility is in';


--
-- Name: COLUMN reporting_facility_states.state_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.state_slug IS 'Human readable ID of the state region that the facility is in';


--
-- Name: COLUMN reporting_facility_states.organization_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.organization_id IS 'ID of the organization that the facility is in';


--
-- Name: COLUMN reporting_facility_states.organization_region_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.organization_region_id IS 'ID of the organization region that the facility is in';


--
-- Name: COLUMN reporting_facility_states.organization_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.organization_name IS 'Name of the organization region that the facility is in';


--
-- Name: COLUMN reporting_facility_states.organization_slug; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.organization_slug IS 'Human readable ID of the organization region that the facility is in';


--
-- Name: COLUMN reporting_facility_states.cumulative_registrations; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.cumulative_registrations IS 'The total number of hypertensive patients registered at the facility up to the end of the reporting month';


--
-- Name: COLUMN reporting_facility_states.monthly_registrations; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.monthly_registrations IS 'The number of hypertensive patients registered at the facility in the reporting month';


--
-- Name: COLUMN reporting_facility_states.under_care; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.under_care IS 'The number of patients assigned to the facility as of the reporting month where the patient had a BP recorded within the last year, and is not dead';


--
-- Name: COLUMN reporting_facility_states.lost_to_follow_up; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.lost_to_follow_up IS 'The number of patients assigned to the facility as of the reporting month where the patient did not have a BP recorded within the last year, and is not dead';


--
-- Name: COLUMN reporting_facility_states.dead; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.dead IS 'The number of patients assigned to the facility as of the reporting month who are dead';


--
-- Name: COLUMN reporting_facility_states.cumulative_assigned_patients; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.cumulative_assigned_patients IS 'The total number of hypertensive patients assigned to the facility up to the end of the reporting month';


--
-- Name: COLUMN reporting_facility_states.adjusted_controlled_under_care; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.adjusted_controlled_under_care IS 'The number of hypertensive patients registered before the last 3 months, with a BP < 140/90 at their last visit in the last 3 months. Dead and lost to follow-up patients are excluded.';


--
-- Name: COLUMN reporting_facility_states.adjusted_uncontrolled_under_care; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.adjusted_uncontrolled_under_care IS 'The number of hypertensive patients assigned to the facility that were registered before the last 3 months, with a BP >= 140/90 at their last visit in the last 3 months. Dead and lost to follow-up patients are excluded.';


--
-- Name: COLUMN reporting_facility_states.adjusted_missed_visit_under_care; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.adjusted_missed_visit_under_care IS 'The number of hypertensive patients assigned to the facility that were registered before the last 3 months, with no visit in the last 3 months. Dead and lost to follow-up patients are excluded.';


--
-- Name: COLUMN reporting_facility_states.adjusted_visited_no_bp_under_care; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.adjusted_visited_no_bp_under_care IS 'The number of hypertensive patients assigned to the facility that were registered before the last 3 months, with no BP taken at their last visit in the last 3 months. Dead and lost to follow-up patients are excluded.';


--
-- Name: COLUMN reporting_facility_states.adjusted_missed_visit_lost_to_follow_up; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.adjusted_missed_visit_lost_to_follow_up IS 'adjusted_missed_visit_lost_to_follow_up';


--
-- Name: COLUMN reporting_facility_states.adjusted_visited_no_bp_lost_to_follow_up; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.adjusted_visited_no_bp_lost_to_follow_up IS 'adjusted_visited_no_bp_lost_to_follow_up';


--
-- Name: COLUMN reporting_facility_states.adjusted_patients_under_care; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.adjusted_patients_under_care IS 'The number of hypertensive patients assigned to the facility that were registered before the last 3 months';


--
-- Name: COLUMN reporting_facility_states.adjusted_patients_lost_to_follow_up; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.adjusted_patients_lost_to_follow_up IS 'The number of hypertensive patients assigned to the facility that were registered before the last 3 months, with no visit in the last year';


--
-- Name: COLUMN reporting_facility_states.monthly_cohort_controlled; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.monthly_cohort_controlled IS 'The number of patients from `monthly_cohort_patients` with a BP <140/90 at their latest visit in the next two months. Eg. The number of patients registered in Jan 2020 with a controlled BP at their latest visit in Feb-Mar 2020';


--
-- Name: COLUMN reporting_facility_states.monthly_cohort_uncontrolled; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.monthly_cohort_uncontrolled IS 'The number of patients from `monthly_cohort_patients` with a BP >=140/90 at their latest visit in the next two months. Eg. The number of patients registered in Jan 2020 with an uncontrolled BP at their latest visit in Feb-Mar 2020';


--
-- Name: COLUMN reporting_facility_states.monthly_cohort_missed_visit; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.monthly_cohort_missed_visit IS 'The number of patients from `monthly_cohort_patients` with no visit in the next two months. Eg. The number of patients registered in Jan 2020 with no visit in Feb-Mar 2020';


--
-- Name: COLUMN reporting_facility_states.monthly_cohort_visited_no_bp; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.monthly_cohort_visited_no_bp IS 'The number of patients from `monthly_cohort_patients` with no BP recorded at their latest visit in the next two months. Eg. The number of patients registered in Jan 2020 with no BP recorded at their latest visit in Feb-Mar 2020';


--
-- Name: COLUMN reporting_facility_states.monthly_cohort_patients; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.monthly_cohort_patients IS 'The number of patients assigned to the facility that were registered two months before the reporting month, and have a . Eg. For a March 2020 report, the number of patients registered in Jan 2020';


--
-- Name: COLUMN reporting_facility_states.monthly_overdue_calls; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.monthly_overdue_calls IS 'The number of overdue calls made by healthcare workers at the facility in the reporting month';


--
-- Name: COLUMN reporting_facility_states.monthly_follow_ups; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.monthly_follow_ups IS 'The number of follow-up patient visits at the facility in the reporting month';


--
-- Name: COLUMN reporting_facility_states.total_appts_scheduled; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.total_appts_scheduled IS 'The total number of appointments scheduled by healthcare workers at the facility in the reporting month';


--
-- Name: COLUMN reporting_facility_states.appts_scheduled_0_to_14_days; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.appts_scheduled_0_to_14_days IS 'The total number of appointments scheduled by healthcare workers at the facility in the reporting month between 0 and 14 days from the visit date';


--
-- Name: COLUMN reporting_facility_states.appts_scheduled_15_to_31_days; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.appts_scheduled_15_to_31_days IS 'The total number of appointments scheduled by healthcare workers at the facility in the reporting month between 15 and 31 days from the visit date';


--
-- Name: COLUMN reporting_facility_states.appts_scheduled_32_to_62_days; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.appts_scheduled_32_to_62_days IS 'The total number of appointments scheduled by healthcare workers at the facility in the reporting month between 32 and 62 days from the visit date';


--
-- Name: COLUMN reporting_facility_states.appts_scheduled_more_than_62_days; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reporting_facility_states.appts_scheduled_more_than_62_days IS 'The total number of appointments scheduled by healthcare workers at the facility in the reporting month more than 62 days from the visit date';


--
-- Name: reporting_quarterly_facility_states; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.reporting_quarterly_facility_states AS
 WITH quarterly_cohort_outcomes AS (
         SELECT reporting_patient_states.assigned_facility_region_id AS region_id,
            reporting_patient_states.quarter_string,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_quarter = 'visited_no_bp'::text)) AS visited_no_bp,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_quarter = 'controlled'::text)) AS controlled,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_quarter = 'uncontrolled'::text)) AS uncontrolled,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_quarter = 'missed_visit'::text)) AS missed_visit,
            count(DISTINCT reporting_patient_states.patient_id) AS patients
           FROM public.reporting_patient_states
          WHERE ((reporting_patient_states.hypertension = 'yes'::text) AND ((((reporting_patient_states.month)::integer % 3) = 0) OR (reporting_patient_states.month_string = to_char(now(), 'YYYY-MM'::text))) AND (reporting_patient_states.quarters_since_registration = (1)::double precision))
          GROUP BY reporting_patient_states.assigned_facility_region_id, reporting_patient_states.quarter_string
        )
 SELECT cal.month_date,
    cal.month,
    cal.quarter,
    cal.year,
    cal.month_string,
    cal.quarter_string,
    rf.facility_id,
    rf.facility_name,
    rf.facility_type,
    rf.facility_size,
    rf.facility_region_id,
    rf.facility_region_name,
    rf.facility_region_slug,
    rf.block_region_id,
    rf.block_name,
    rf.block_slug,
    rf.district_id,
    rf.district_region_id,
    rf.district_name,
    rf.district_slug,
    rf.state_region_id,
    rf.state_name,
    rf.state_slug,
    rf.organization_id,
    rf.organization_region_id,
    rf.organization_name,
    rf.organization_slug,
    quarterly_cohort_outcomes.controlled AS quarterly_cohort_controlled,
    quarterly_cohort_outcomes.uncontrolled AS quarterly_cohort_uncontrolled,
    quarterly_cohort_outcomes.missed_visit AS quarterly_cohort_missed_visit,
    quarterly_cohort_outcomes.visited_no_bp AS quarterly_cohort_visited_no_bp,
    quarterly_cohort_outcomes.patients AS quarterly_cohort_patients
   FROM ((public.reporting_facilities rf
     JOIN public.reporting_months cal ON (((((cal.month)::integer % 3) = 0) OR (cal.month_string = to_char(now(), 'YYYY-MM'::text)))))
     LEFT JOIN quarterly_cohort_outcomes ON (((quarterly_cohort_outcomes.quarter_string = cal.quarter_string) AND (quarterly_cohort_outcomes.region_id = rf.facility_region_id))))
  WITH NO DATA;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: teleconsultations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teleconsultations (
    id uuid NOT NULL,
    patient_id uuid NOT NULL,
    medical_officer_id uuid NOT NULL,
    requested_medical_officer_id uuid,
    requester_id uuid,
    facility_id uuid,
    requester_completion_status character varying,
    requested_at timestamp without time zone,
    recorded_at timestamp without time zone,
    teleconsultation_type character varying,
    patient_took_medicines character varying,
    patient_consented character varying,
    medical_officer_number character varying,
    deleted_at timestamp without time zone,
    device_updated_at timestamp without time zone,
    device_created_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: treatment_group_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.treatment_group_memberships (
    id bigint NOT NULL,
    treatment_group_id uuid NOT NULL,
    patient_id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    experiment_id uuid NOT NULL,
    appointment_id uuid,
    experiment_name character varying NOT NULL,
    treatment_group_name character varying NOT NULL,
    experiment_inclusion_date timestamp without time zone,
    expected_return_date timestamp without time zone,
    expected_return_facility_id uuid,
    expected_return_facility_type character varying,
    expected_return_facility_name character varying,
    expected_return_facility_block character varying,
    expected_return_facility_district character varying,
    expected_return_facility_state character varying,
    appointment_creation_time timestamp without time zone,
    appointment_creation_facility_id uuid,
    appointment_creation_facility_type character varying,
    appointment_creation_facility_name character varying,
    appointment_creation_facility_block character varying,
    appointment_creation_facility_district character varying,
    appointment_creation_facility_state character varying,
    gender character varying,
    age integer,
    risk_level character varying,
    diagnosed_htn character varying,
    assigned_facility_id uuid,
    assigned_facility_name character varying,
    assigned_facility_type character varying,
    assigned_facility_block character varying,
    assigned_facility_district character varying,
    assigned_facility_state character varying,
    registration_facility_id uuid,
    registration_facility_name character varying,
    registration_facility_type character varying,
    registration_facility_block character varying,
    registration_facility_district character varying,
    registration_facility_state character varying,
    visited_at timestamp without time zone,
    visit_facility_id uuid,
    visit_facility_name character varying,
    visit_facility_type character varying,
    visit_facility_block character varying,
    visit_facility_district character varying,
    visit_facility_state character varying,
    visit_blood_pressure_id uuid,
    visit_blood_sugar_id uuid,
    visit_prescription_drug_created boolean,
    days_to_visit integer,
    messages jsonb,
    status character varying,
    status_reason character varying,
    status_updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


--
-- Name: treatment_group_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.treatment_group_memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: treatment_group_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.treatment_group_memberships_id_seq OWNED BY public.treatment_group_memberships.id;


--
-- Name: treatment_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.treatment_groups (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    description character varying NOT NULL,
    experiment_id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: twilio_sms_delivery_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.twilio_sms_delivery_details (
    id bigint NOT NULL,
    session_id character varying,
    result character varying,
    callee_phone_number character varying NOT NULL,
    delivered_on timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    read_at timestamp without time zone
);


--
-- Name: twilio_sms_delivery_details_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.twilio_sms_delivery_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: twilio_sms_delivery_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.twilio_sms_delivery_details_id_seq OWNED BY public.twilio_sms_delivery_details.id;


--
-- Name: user_authentications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_authentications (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    user_id uuid,
    authenticatable_type character varying,
    authenticatable_id uuid,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    full_name character varying,
    sync_approval_status character varying NOT NULL,
    sync_approval_status_reason character varying,
    device_updated_at timestamp without time zone NOT NULL,
    device_created_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    role character varying,
    organization_id uuid,
    access_level character varying,
    teleconsultation_phone_number character varying,
    teleconsultation_isd_code character varying,
    receive_approval_notifications boolean DEFAULT true NOT NULL
);


--
-- Name: call_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.call_logs ALTER COLUMN id SET DEFAULT nextval('public.call_logs_id_seq'::regclass);


--
-- Name: facility_business_identifiers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.facility_business_identifiers ALTER COLUMN id SET DEFAULT nextval('public.facility_business_identifiers_id_seq'::regclass);


--
-- Name: flipper_features id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_features ALTER COLUMN id SET DEFAULT nextval('public.flipper_features_id_seq'::regclass);


--
-- Name: flipper_gates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_gates ALTER COLUMN id SET DEFAULT nextval('public.flipper_gates_id_seq'::regclass);


--
-- Name: observations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observations ALTER COLUMN id SET DEFAULT nextval('public.observations_id_seq'::regclass);


--
-- Name: passport_authentications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.passport_authentications ALTER COLUMN id SET DEFAULT nextval('public.passport_authentications_id_seq'::regclass);


--
-- Name: treatment_group_memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.treatment_group_memberships ALTER COLUMN id SET DEFAULT nextval('public.treatment_group_memberships_id_seq'::regclass);


--
-- Name: twilio_sms_delivery_details id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.twilio_sms_delivery_details ALTER COLUMN id SET DEFAULT nextval('public.twilio_sms_delivery_details_id_seq'::regclass);


--
-- Name: accesses accesses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accesses
    ADD CONSTRAINT accesses_pkey PRIMARY KEY (id);


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: appointments appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: blood_pressures blood_pressures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blood_pressures
    ADD CONSTRAINT blood_pressures_pkey PRIMARY KEY (id);


--
-- Name: blood_sugars blood_sugars_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blood_sugars
    ADD CONSTRAINT blood_sugars_pkey PRIMARY KEY (id);


--
-- Name: call_logs call_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.call_logs
    ADD CONSTRAINT call_logs_pkey PRIMARY KEY (id);


--
-- Name: call_results call_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.call_results
    ADD CONSTRAINT call_results_pkey PRIMARY KEY (id);


--
-- Name: communications communications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.communications
    ADD CONSTRAINT communications_pkey PRIMARY KEY (id);


--
-- Name: data_migrations data_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_migrations
    ADD CONSTRAINT data_migrations_pkey PRIMARY KEY (version);


--
-- Name: deduplication_logs deduplication_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deduplication_logs
    ADD CONSTRAINT deduplication_logs_pkey PRIMARY KEY (id);


--
-- Name: drug_stocks drug_stocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drug_stocks
    ADD CONSTRAINT drug_stocks_pkey PRIMARY KEY (id);


--
-- Name: email_authentications email_authentications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_authentications
    ADD CONSTRAINT email_authentications_pkey PRIMARY KEY (id);


--
-- Name: encounters encounters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encounters
    ADD CONSTRAINT encounters_pkey PRIMARY KEY (id);


--
-- Name: estimated_populations estimated_populations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estimated_populations
    ADD CONSTRAINT estimated_populations_pkey PRIMARY KEY (id);


--
-- Name: exotel_phone_number_details exotel_phone_number_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exotel_phone_number_details
    ADD CONSTRAINT exotel_phone_number_details_pkey PRIMARY KEY (id);


--
-- Name: experiments experiments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.experiments
    ADD CONSTRAINT experiments_pkey PRIMARY KEY (id);


--
-- Name: facilities facilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.facilities
    ADD CONSTRAINT facilities_pkey PRIMARY KEY (id);


--
-- Name: facility_business_identifiers facility_business_identifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.facility_business_identifiers
    ADD CONSTRAINT facility_business_identifiers_pkey PRIMARY KEY (id);


--
-- Name: facility_groups facility_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.facility_groups
    ADD CONSTRAINT facility_groups_pkey PRIMARY KEY (id);


--
-- Name: flipper_features flipper_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_features
    ADD CONSTRAINT flipper_features_pkey PRIMARY KEY (id);


--
-- Name: flipper_gates flipper_gates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flipper_gates
    ADD CONSTRAINT flipper_gates_pkey PRIMARY KEY (id);


--
-- Name: medical_histories medical_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medical_histories
    ADD CONSTRAINT medical_histories_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: observations observations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observations
    ADD CONSTRAINT observations_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: passport_authentications passport_authentications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.passport_authentications
    ADD CONSTRAINT passport_authentications_pkey PRIMARY KEY (id);


--
-- Name: patient_business_identifiers patient_business_identifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_business_identifiers
    ADD CONSTRAINT patient_business_identifiers_pkey PRIMARY KEY (id);


--
-- Name: patient_phone_numbers patient_phone_numbers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_phone_numbers
    ADD CONSTRAINT patient_phone_numbers_pkey PRIMARY KEY (id);


--
-- Name: patients patients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_pkey PRIMARY KEY (id);


--
-- Name: phone_number_authentications phone_number_authentications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.phone_number_authentications
    ADD CONSTRAINT phone_number_authentications_pkey PRIMARY KEY (id);


--
-- Name: prescription_drugs prescription_drugs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prescription_drugs
    ADD CONSTRAINT prescription_drugs_pkey PRIMARY KEY (id);


--
-- Name: protocol_drugs protocol_drugs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocol_drugs
    ADD CONSTRAINT protocol_drugs_pkey PRIMARY KEY (id);


--
-- Name: protocols protocols_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocols
    ADD CONSTRAINT protocols_pkey PRIMARY KEY (id);


--
-- Name: regions regions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regions
    ADD CONSTRAINT regions_pkey PRIMARY KEY (id);


--
-- Name: reminder_templates reminder_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reminder_templates
    ADD CONSTRAINT reminder_templates_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: teleconsultations teleconsultations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teleconsultations
    ADD CONSTRAINT teleconsultations_pkey PRIMARY KEY (id);


--
-- Name: treatment_group_memberships treatment_group_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.treatment_group_memberships
    ADD CONSTRAINT treatment_group_memberships_pkey PRIMARY KEY (id);


--
-- Name: treatment_groups treatment_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.treatment_groups
    ADD CONSTRAINT treatment_groups_pkey PRIMARY KEY (id);


--
-- Name: twilio_sms_delivery_details twilio_sms_delivery_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.twilio_sms_delivery_details
    ADD CONSTRAINT twilio_sms_delivery_details_pkey PRIMARY KEY (id);


--
-- Name: user_authentications user_authentications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_authentications
    ADD CONSTRAINT user_authentications_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: clean_medicine_to_dosages__unique_name_and_dosage; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX clean_medicine_to_dosages__unique_name_and_dosage ON public.clean_medicine_to_dosages USING btree (medicine, dosage, rxcui);


--
-- Name: daily_follow_ups_day_patient_facility; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX daily_follow_ups_day_patient_facility ON public.reporting_daily_follow_ups USING btree (patient_id, facility_id, day_of_year);


--
-- Name: idx_deduplication_logs_lookup_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_deduplication_logs_lookup_deleted_at ON public.deduplication_logs USING btree (deleted_at, deleted_record_id);


--
-- Name: idx_deduplication_logs_lookup_deleted_record; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_deduplication_logs_lookup_deleted_record ON public.deduplication_logs USING btree (record_type, deleted_record_id);


--
-- Name: idx_observations_on_observable_type_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_observations_on_observable_type_and_id ON public.observations USING btree (observable_type, observable_id);


--
-- Name: index_accesses_on_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accesses_on_resource_id ON public.accesses USING btree (resource_id);


--
-- Name: index_accesses_on_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accesses_on_resource_type_and_resource_id ON public.accesses USING btree (resource_type, resource_id);


--
-- Name: index_accesses_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accesses_on_user_id ON public.accesses USING btree (user_id);


--
-- Name: index_accesses_on_user_id_and_resource_id_and_resource_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accesses_on_user_id_and_resource_id_and_resource_type ON public.accesses USING btree (user_id, resource_id, resource_type);


--
-- Name: index_addresses_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addresses_on_deleted_at ON public.addresses USING btree (deleted_at);


--
-- Name: index_addresses_on_zone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_addresses_on_zone ON public.addresses USING btree (zone);


--
-- Name: index_appointments_on_facility_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appointments_on_facility_id ON public.appointments USING btree (facility_id);


--
-- Name: index_appointments_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appointments_on_patient_id ON public.appointments USING btree (patient_id);


--
-- Name: index_appointments_on_patient_id_and_scheduled_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appointments_on_patient_id_and_scheduled_date ON public.appointments USING btree (patient_id, scheduled_date DESC);


--
-- Name: index_appointments_on_patient_id_and_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appointments_on_patient_id_and_updated_at ON public.appointments USING btree (patient_id, updated_at);


--
-- Name: index_appointments_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appointments_on_updated_at ON public.appointments USING btree (updated_at);


--
-- Name: index_appointments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appointments_on_user_id ON public.appointments USING btree (user_id);


--
-- Name: index_blood_pressures_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blood_pressures_on_deleted_at ON public.blood_pressures USING btree (deleted_at);


--
-- Name: index_blood_pressures_on_facility_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blood_pressures_on_facility_id ON public.blood_pressures USING btree (facility_id);


--
-- Name: index_blood_pressures_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blood_pressures_on_patient_id ON public.blood_pressures USING btree (patient_id);


--
-- Name: index_blood_pressures_on_patient_id_and_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blood_pressures_on_patient_id_and_recorded_at ON public.blood_pressures USING btree (patient_id, recorded_at DESC);


--
-- Name: index_blood_pressures_on_patient_id_and_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blood_pressures_on_patient_id_and_updated_at ON public.blood_pressures USING btree (patient_id, updated_at);


--
-- Name: index_blood_pressures_on_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blood_pressures_on_recorded_at ON public.blood_pressures USING btree (recorded_at);


--
-- Name: index_blood_pressures_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blood_pressures_on_updated_at ON public.blood_pressures USING btree (updated_at);


--
-- Name: index_blood_pressures_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blood_pressures_on_user_id ON public.blood_pressures USING btree (user_id);


--
-- Name: index_blood_pressures_per_facility_per_days; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_blood_pressures_per_facility_per_days ON public.blood_pressures_per_facility_per_days USING btree (facility_id, day, year);


--
-- Name: index_blood_sugars_on_blood_sugar_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blood_sugars_on_blood_sugar_type ON public.blood_sugars USING btree (blood_sugar_type);


--
-- Name: index_blood_sugars_on_facility_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blood_sugars_on_facility_id ON public.blood_sugars USING btree (facility_id);


--
-- Name: index_blood_sugars_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blood_sugars_on_patient_id ON public.blood_sugars USING btree (patient_id);


--
-- Name: index_blood_sugars_on_patient_id_and_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blood_sugars_on_patient_id_and_updated_at ON public.blood_sugars USING btree (patient_id, updated_at);


--
-- Name: index_blood_sugars_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blood_sugars_on_updated_at ON public.blood_sugars USING btree (updated_at);


--
-- Name: index_blood_sugars_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blood_sugars_on_user_id ON public.blood_sugars USING btree (user_id);


--
-- Name: index_bp_months_assigned_facility_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bp_months_assigned_facility_id ON public.latest_blood_pressures_per_patient_per_months USING btree (assigned_facility_id);


--
-- Name: index_bp_months_bp_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bp_months_bp_recorded_at ON public.latest_blood_pressures_per_patient_per_months USING btree (bp_recorded_at);


--
-- Name: index_bp_months_patient_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bp_months_patient_recorded_at ON public.latest_blood_pressures_per_patient_per_months USING btree (patient_recorded_at);


--
-- Name: index_communications_on_appointment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_communications_on_appointment_id ON public.communications USING btree (appointment_id);


--
-- Name: index_communications_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_communications_on_deleted_at ON public.communications USING btree (deleted_at);


--
-- Name: index_communications_on_detailable_type_and_detailable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_communications_on_detailable_type_and_detailable_id ON public.communications USING btree (detailable_type, detailable_id);


--
-- Name: index_communications_on_notification_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_communications_on_notification_id ON public.communications USING btree (notification_id);


--
-- Name: index_communications_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_communications_on_user_id ON public.communications USING btree (user_id);


--
-- Name: index_deduplication_logs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_deduplication_logs_on_user_id ON public.deduplication_logs USING btree (user_id);


--
-- Name: index_dfu_facility_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dfu_facility_id ON public.reporting_daily_follow_ups USING btree (facility_id);


--
-- Name: index_drug_stocks_on_facility_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_drug_stocks_on_facility_id ON public.drug_stocks USING btree (facility_id);


--
-- Name: index_email_authentications_invited_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_authentications_invited_by ON public.email_authentications USING btree (invited_by_type, invited_by_id);


--
-- Name: index_email_authentications_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_authentications_on_deleted_at ON public.email_authentications USING btree (deleted_at);


--
-- Name: index_email_authentications_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_email_authentications_on_email ON public.email_authentications USING btree (email);


--
-- Name: index_email_authentications_on_invitation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_email_authentications_on_invitation_token ON public.email_authentications USING btree (invitation_token);


--
-- Name: index_email_authentications_on_invitations_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_authentications_on_invitations_count ON public.email_authentications USING btree (invitations_count);


--
-- Name: index_email_authentications_on_invited_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_authentications_on_invited_by_id ON public.email_authentications USING btree (invited_by_id);


--
-- Name: index_email_authentications_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_email_authentications_on_reset_password_token ON public.email_authentications USING btree (reset_password_token);


--
-- Name: index_email_authentications_on_unlock_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_email_authentications_on_unlock_token ON public.email_authentications USING btree (unlock_token);


--
-- Name: index_encounters_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_encounters_on_deleted_at ON public.encounters USING btree (deleted_at);


--
-- Name: index_encounters_on_facility_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_encounters_on_facility_id ON public.encounters USING btree (facility_id);


--
-- Name: index_encounters_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_encounters_on_patient_id ON public.encounters USING btree (patient_id);


--
-- Name: index_encounters_on_patient_id_and_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_encounters_on_patient_id_and_updated_at ON public.encounters USING btree (patient_id, updated_at);


--
-- Name: index_estimated_populations_on_region_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_estimated_populations_on_region_id ON public.estimated_populations USING btree (region_id);


--
-- Name: index_experiments_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_experiments_on_name ON public.experiments USING btree (name);


--
-- Name: index_facilities_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_facilities_on_deleted_at ON public.facilities USING btree (deleted_at);


--
-- Name: index_facilities_on_enable_diabetes_management; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_facilities_on_enable_diabetes_management ON public.facilities USING btree (enable_diabetes_management);


--
-- Name: index_facilities_on_facility_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_facilities_on_facility_group_id ON public.facilities USING btree (facility_group_id);


--
-- Name: index_facilities_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_facilities_on_slug ON public.facilities USING btree (slug);


--
-- Name: index_facilities_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_facilities_on_updated_at ON public.facilities USING btree (updated_at);


--
-- Name: index_facilities_teleconsult_mos_on_facility_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_facilities_teleconsult_mos_on_facility_id_and_user_id ON public.facilities_teleconsultation_medical_officers USING btree (facility_id, user_id);


--
-- Name: index_facility_business_identifiers_on_facility_and_id_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_facility_business_identifiers_on_facility_and_id_type ON public.facility_business_identifiers USING btree (facility_id, identifier_type);


--
-- Name: index_facility_business_identifiers_on_facility_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_facility_business_identifiers_on_facility_id ON public.facility_business_identifiers USING btree (facility_id);


--
-- Name: index_facility_groups_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_facility_groups_on_deleted_at ON public.facility_groups USING btree (deleted_at);


--
-- Name: index_facility_groups_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_facility_groups_on_organization_id ON public.facility_groups USING btree (organization_id);


--
-- Name: index_facility_groups_on_protocol_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_facility_groups_on_protocol_id ON public.facility_groups USING btree (protocol_id);


--
-- Name: index_facility_groups_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_facility_groups_on_slug ON public.facility_groups USING btree (slug);


--
-- Name: index_flipper_features_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flipper_features_on_key ON public.flipper_features USING btree (key);


--
-- Name: index_flipper_gates_on_feature_key_and_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flipper_gates_on_feature_key_and_key_and_value ON public.flipper_gates USING btree (feature_key, key, value);


--
-- Name: index_fs_dimensions_facility_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_fs_dimensions_facility_id ON public.reporting_facility_state_dimensions USING btree (facility_id);


--
-- Name: index_fs_dimensions_month_date_facility_region_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_fs_dimensions_month_date_facility_region_id ON public.reporting_facility_state_dimensions USING btree (month_date, facility_region_id);


--
-- Name: index_fs_month_date_region_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_fs_month_date_region_id ON public.reporting_facility_states USING btree (month_date, facility_region_id);


--
-- Name: index_gin_email_authentications_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gin_email_authentications_on_email ON public.email_authentications USING gin (to_tsvector('simple'::regconfig, COALESCE((email)::text, ''::text)));


--
-- Name: index_gin_phone_number_authentications_on_phone_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gin_phone_number_authentications_on_phone_number ON public.phone_number_authentications USING gin (to_tsvector('simple'::regconfig, COALESCE((phone_number)::text, ''::text)));


--
-- Name: index_gin_users_on_full_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_gin_users_on_full_name ON public.users USING gin (to_tsvector('simple'::regconfig, COALESCE((full_name)::text, ''::text)));


--
-- Name: index_latest_blood_pressures_per_patient_per_months; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_latest_blood_pressures_per_patient_per_months ON public.latest_blood_pressures_per_patient_per_months USING btree (bp_id);


--
-- Name: index_latest_blood_pressures_per_patient_per_quarters; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_latest_blood_pressures_per_patient_per_quarters ON public.latest_blood_pressures_per_patient_per_quarters USING btree (bp_id);


--
-- Name: index_latest_blood_pressures_per_patients; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_latest_blood_pressures_per_patients ON public.latest_blood_pressures_per_patients USING btree (bp_id);


--
-- Name: index_latest_bp_per_patient_per_months_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_latest_bp_per_patient_per_months_patient_id ON public.latest_blood_pressures_per_patient_per_months USING btree (patient_id);


--
-- Name: index_latest_bp_per_patient_per_quarters_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_latest_bp_per_patient_per_quarters_patient_id ON public.latest_blood_pressures_per_patient_per_quarters USING btree (patient_id);


--
-- Name: index_materialized_patient_summaries_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_materialized_patient_summaries_on_id ON public.materialized_patient_summaries USING btree (id);


--
-- Name: index_medical_histories_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_medical_histories_on_patient_id ON public.medical_histories USING btree (patient_id);


--
-- Name: index_medical_histories_on_patient_id_and_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_medical_histories_on_patient_id_and_updated_at ON public.medical_histories USING btree (patient_id, updated_at);


--
-- Name: index_notifications_on_experiment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_experiment_id ON public.notifications USING btree (experiment_id);


--
-- Name: index_notifications_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_patient_id ON public.notifications USING btree (patient_id);


--
-- Name: index_notifications_on_reminder_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_reminder_template_id ON public.notifications USING btree (reminder_template_id);


--
-- Name: index_notifications_on_subject_type_and_subject_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_subject_type_and_subject_id ON public.notifications USING btree (subject_type, subject_id);


--
-- Name: index_observations_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observations_on_deleted_at ON public.observations USING btree (deleted_at);


--
-- Name: index_observations_on_encounter_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observations_on_encounter_id ON public.observations USING btree (encounter_id);


--
-- Name: index_observations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_observations_on_user_id ON public.observations USING btree (user_id);


--
-- Name: index_organizations_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_organizations_on_deleted_at ON public.organizations USING btree (deleted_at);


--
-- Name: index_organizations_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_organizations_on_slug ON public.organizations USING btree (slug);


--
-- Name: index_patient_business_identifiers_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patient_business_identifiers_identifier ON public.patient_business_identifiers USING btree (identifier);


--
-- Name: index_patient_business_identifiers_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patient_business_identifiers_on_deleted_at ON public.patient_business_identifiers USING btree (deleted_at);


--
-- Name: index_patient_business_identifiers_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patient_business_identifiers_on_patient_id ON public.patient_business_identifiers USING btree (patient_id);


--
-- Name: index_patient_phone_numbers_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patient_phone_numbers_on_deleted_at ON public.patient_phone_numbers USING btree (deleted_at);


--
-- Name: index_patient_phone_numbers_on_dnd_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patient_phone_numbers_on_dnd_status ON public.patient_phone_numbers USING btree (dnd_status);


--
-- Name: index_patient_phone_numbers_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patient_phone_numbers_on_patient_id ON public.patient_phone_numbers USING btree (patient_id);


--
-- Name: index_patient_registrations_per_day_per_facilities; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_patient_registrations_per_day_per_facilities ON public.patient_registrations_per_day_per_facilities USING btree (facility_id, day, year);


--
-- Name: index_patients_on_address_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patients_on_address_id ON public.patients USING btree (address_id);


--
-- Name: index_patients_on_assigned_facility_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patients_on_assigned_facility_id ON public.patients USING btree (assigned_facility_id);


--
-- Name: index_patients_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patients_on_deleted_at ON public.patients USING btree (deleted_at);


--
-- Name: index_patients_on_id_and_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patients_on_id_and_updated_at ON public.patients USING btree (id, updated_at);


--
-- Name: index_patients_on_recorded_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patients_on_recorded_at ON public.patients USING btree (recorded_at);


--
-- Name: index_patients_on_registration_facility_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patients_on_registration_facility_id ON public.patients USING btree (registration_facility_id);


--
-- Name: index_patients_on_registration_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patients_on_registration_user_id ON public.patients USING btree (registration_user_id);


--
-- Name: index_patients_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patients_on_updated_at ON public.patients USING btree (updated_at);


--
-- Name: index_phone_number_authentications_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_phone_number_authentications_on_deleted_at ON public.phone_number_authentications USING btree (deleted_at);


--
-- Name: index_prescription_drugs_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescription_drugs_on_deleted_at ON public.prescription_drugs USING btree (deleted_at);


--
-- Name: index_prescription_drugs_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescription_drugs_on_patient_id ON public.prescription_drugs USING btree (patient_id);


--
-- Name: index_prescription_drugs_on_patient_id_and_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescription_drugs_on_patient_id_and_updated_at ON public.prescription_drugs USING btree (patient_id, updated_at);


--
-- Name: index_prescription_drugs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescription_drugs_on_updated_at ON public.prescription_drugs USING btree (updated_at);


--
-- Name: index_prescription_drugs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prescription_drugs_on_user_id ON public.prescription_drugs USING btree (user_id);


--
-- Name: index_protocol_drugs_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocol_drugs_on_deleted_at ON public.protocol_drugs USING btree (deleted_at);


--
-- Name: index_protocols_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_deleted_at ON public.protocols USING btree (deleted_at);


--
-- Name: index_protocols_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_protocols_on_updated_at ON public.protocols USING btree (updated_at);


--
-- Name: index_qfs_facility_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_qfs_facility_id ON public.reporting_quarterly_facility_states USING btree (facility_id);


--
-- Name: index_qfs_quarter_string_region_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_qfs_quarter_string_region_id ON public.reporting_quarterly_facility_states USING btree (quarter_string, facility_region_id);


--
-- Name: index_regions_on_path; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regions_on_path ON public.regions USING gist (path);


--
-- Name: index_regions_on_region_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regions_on_region_type ON public.regions USING btree (region_type);


--
-- Name: index_regions_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_regions_on_slug ON public.regions USING btree (slug);


--
-- Name: index_regions_on_source_type_and_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_regions_on_source_type_and_source_id ON public.regions USING btree (source_type, source_id);


--
-- Name: index_regions_on_unique_path; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_regions_on_unique_path ON public.regions USING btree (path);


--
-- Name: index_reminder_templates_on_treatment_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reminder_templates_on_treatment_group_id ON public.reminder_templates USING btree (treatment_group_id);


--
-- Name: index_reporting_facility_appointment_scheduled_days; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_reporting_facility_appointment_scheduled_days ON public.reporting_facility_appointment_scheduled_days USING btree (month_date, facility_id);


--
-- Name: index_teleconsultations_on_facility_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teleconsultations_on_facility_id ON public.teleconsultations USING btree (facility_id);


--
-- Name: index_teleconsultations_on_medical_officer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teleconsultations_on_medical_officer_id ON public.teleconsultations USING btree (medical_officer_id);


--
-- Name: index_teleconsultations_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teleconsultations_on_patient_id ON public.teleconsultations USING btree (patient_id);


--
-- Name: index_teleconsultations_on_requested_medical_officer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teleconsultations_on_requested_medical_officer_id ON public.teleconsultations USING btree (requested_medical_officer_id);


--
-- Name: index_teleconsultations_on_requester_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teleconsultations_on_requester_id ON public.teleconsultations USING btree (requester_id);


--
-- Name: index_tgm_patient_id_and_experiment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tgm_patient_id_and_experiment_id ON public.treatment_group_memberships USING btree (patient_id, experiment_id);


--
-- Name: index_treatment_group_memberships_on_appointment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_treatment_group_memberships_on_appointment_id ON public.treatment_group_memberships USING btree (appointment_id);


--
-- Name: index_treatment_group_memberships_on_experiment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_treatment_group_memberships_on_experiment_id ON public.treatment_group_memberships USING btree (experiment_id);


--
-- Name: index_treatment_group_memberships_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_treatment_group_memberships_on_patient_id ON public.treatment_group_memberships USING btree (patient_id);


--
-- Name: index_treatment_group_memberships_on_treatment_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_treatment_group_memberships_on_treatment_group_id ON public.treatment_group_memberships USING btree (treatment_group_id);


--
-- Name: index_treatment_groups_on_experiment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_treatment_groups_on_experiment_id ON public.treatment_groups USING btree (experiment_id);


--
-- Name: index_twilio_sms_delivery_details_on_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_twilio_sms_delivery_details_on_session_id ON public.twilio_sms_delivery_details USING btree (session_id);


--
-- Name: index_unique_exotel_phone_number_details_on_phone_number_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_unique_exotel_phone_number_details_on_phone_number_id ON public.exotel_phone_number_details USING btree (patient_phone_number_id);


--
-- Name: index_user_authentications_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_authentications_on_user_id ON public.user_authentications USING btree (user_id);


--
-- Name: index_users_on_access_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_access_level ON public.users USING btree (access_level);


--
-- Name: index_users_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_deleted_at ON public.users USING btree (deleted_at);


--
-- Name: index_users_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_organization_id ON public.users USING btree (organization_id);


--
-- Name: index_users_on_teleconsultation_phone_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_teleconsultation_phone_number ON public.users USING btree (teleconsultation_phone_number);


--
-- Name: medicine_purposes_unique_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX medicine_purposes_unique_name ON public.medicine_purposes USING btree (name);


--
-- Name: overdue_calls_month_date_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX overdue_calls_month_date_patient_id ON public.reporting_overdue_calls USING btree (month_date, patient_id);


--
-- Name: patient_blood_pressures_patient_id_month_date; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX patient_blood_pressures_patient_id_month_date ON public.reporting_patient_blood_pressures USING btree (month_date, patient_id);


--
-- Name: patient_states_assigned_block; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_states_assigned_block ON public.reporting_patient_states USING btree (assigned_block_region_id);


--
-- Name: patient_states_assigned_district; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_states_assigned_district ON public.reporting_patient_states USING btree (assigned_district_region_id);


--
-- Name: patient_states_assigned_facility; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_states_assigned_facility ON public.reporting_patient_states USING btree (assigned_facility_region_id);


--
-- Name: patient_states_assigned_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_states_assigned_state ON public.reporting_patient_states USING btree (assigned_state_region_id);


--
-- Name: patient_states_care_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX patient_states_care_state ON public.reporting_patient_states USING btree (hypertension, htn_care_state, htn_treatment_outcome_in_last_3_months);


--
-- Name: patient_states_month_date_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX patient_states_month_date_patient_id ON public.reporting_patient_states USING btree (month_date, patient_id);


--
-- Name: patient_visits_patient_id_month_date; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX patient_visits_patient_id_month_date ON public.reporting_patient_visits USING btree (month_date, patient_id);


--
-- Name: raw_to_clean_medicines_unique_name_and_dosage; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX raw_to_clean_medicines_unique_name_and_dosage ON public.raw_to_clean_medicines USING btree (raw_name, raw_dosage);


--
-- Name: reporting_patient_follow_ups_unique_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX reporting_patient_follow_ups_unique_index ON public.reporting_patient_follow_ups USING btree (patient_id, user_id, facility_id, month_date);


--
-- Name: reporting_patient_states_bp_facility_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reporting_patient_states_bp_facility_id ON public.reporting_patient_states USING btree (bp_facility_id);


--
-- Name: reporting_patient_states_titrated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reporting_patient_states_titrated ON public.reporting_patient_states USING btree (titrated);


--
-- Name: reporting_prescriptions_patient_month_date; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX reporting_prescriptions_patient_month_date ON public.reporting_prescriptions USING btree (patient_id, month_date);


--
-- Name: user_authentications_master_users_authenticatable_uniq_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_authentications_master_users_authenticatable_uniq_index ON public.user_authentications USING btree (user_id, authenticatable_type, authenticatable_id);


--
-- Name: patient_phone_numbers fk_rails_0145dd0b05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_phone_numbers
    ADD CONSTRAINT fk_rails_0145dd0b05 FOREIGN KEY (patient_id) REFERENCES public.patients(id);


--
-- Name: facility_groups fk_rails_0ba9e6af98; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.facility_groups
    ADD CONSTRAINT fk_rails_0ba9e6af98 FOREIGN KEY (organization_id) REFERENCES public.organizations(id);


--
-- Name: treatment_group_memberships fk_rails_14fd76db1b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.treatment_group_memberships
    ADD CONSTRAINT fk_rails_14fd76db1b FOREIGN KEY (treatment_group_id) REFERENCES public.treatment_groups(id);


--
-- Name: communications fk_rails_17477eedd4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.communications
    ADD CONSTRAINT fk_rails_17477eedd4 FOREIGN KEY (notification_id) REFERENCES public.notifications(id);


--
-- Name: treatment_groups fk_rails_1c30d535fa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.treatment_groups
    ADD CONSTRAINT fk_rails_1c30d535fa FOREIGN KEY (experiment_id) REFERENCES public.experiments(id);


--
-- Name: patients fk_rails_256d8f15cb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT fk_rails_256d8f15cb FOREIGN KEY (registration_facility_id) REFERENCES public.facilities(id);


--
-- Name: patients fk_rails_39783febcc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT fk_rails_39783febcc FOREIGN KEY (address_id) REFERENCES public.addresses(id);


--
-- Name: teleconsultations fk_rails_3e1ccaa4cb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teleconsultations
    ADD CONSTRAINT fk_rails_3e1ccaa4cb FOREIGN KEY (medical_officer_id) REFERENCES public.users(id);


--
-- Name: observations fk_rails_47dc1837b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observations
    ADD CONSTRAINT fk_rails_47dc1837b8 FOREIGN KEY (encounter_id) REFERENCES public.encounters(id);


--
-- Name: teleconsultations fk_rails_4aa89bd48e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teleconsultations
    ADD CONSTRAINT fk_rails_4aa89bd48e FOREIGN KEY (requested_medical_officer_id) REFERENCES public.users(id);


--
-- Name: treatment_group_memberships fk_rails_4b8f85a6e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.treatment_group_memberships
    ADD CONSTRAINT fk_rails_4b8f85a6e7 FOREIGN KEY (appointment_id) REFERENCES public.appointments(id);


--
-- Name: drug_stocks fk_rails_5230adeadd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drug_stocks
    ADD CONSTRAINT fk_rails_5230adeadd FOREIGN KEY (protocol_drug_id) REFERENCES public.protocol_drugs(id);


--
-- Name: estimated_populations fk_rails_58af12b1a9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estimated_populations
    ADD CONSTRAINT fk_rails_58af12b1a9 FOREIGN KEY (region_id) REFERENCES public.regions(id);


--
-- Name: observations fk_rails_60d667a791; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observations
    ADD CONSTRAINT fk_rails_60d667a791 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: patients fk_rails_66733b5dc0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT fk_rails_66733b5dc0 FOREIGN KEY (assigned_facility_id) REFERENCES public.facilities(id);


--
-- Name: blood_sugars fk_rails_7c63b0ef2d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blood_sugars
    ADD CONSTRAINT fk_rails_7c63b0ef2d FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: reminder_templates fk_rails_7d64d6b790; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reminder_templates
    ADD CONSTRAINT fk_rails_7d64d6b790 FOREIGN KEY (treatment_group_id) REFERENCES public.treatment_groups(id);


--
-- Name: teleconsultations fk_rails_811d7873b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teleconsultations
    ADD CONSTRAINT fk_rails_811d7873b8 FOREIGN KEY (facility_id) REFERENCES public.facilities(id);


--
-- Name: appointments fk_rails_81e897bb97; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT fk_rails_81e897bb97 FOREIGN KEY (facility_id) REFERENCES public.facilities(id);


--
-- Name: encounters fk_rails_8df9902cc7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encounters
    ADD CONSTRAINT fk_rails_8df9902cc7 FOREIGN KEY (facility_id) REFERENCES public.facilities(id);


--
-- Name: blood_sugars fk_rails_8e56e1055e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blood_sugars
    ADD CONSTRAINT fk_rails_8e56e1055e FOREIGN KEY (facility_id) REFERENCES public.facilities(id);


--
-- Name: drug_stocks fk_rails_8eb7cdedd2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drug_stocks
    ADD CONSTRAINT fk_rails_8eb7cdedd2 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: clean_medicine_to_dosages fk_rails_96b1526de4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clean_medicine_to_dosages
    ADD CONSTRAINT fk_rails_96b1526de4 FOREIGN KEY (medicine) REFERENCES public.medicine_purposes(name);


--
-- Name: notifications fk_rails_a0b99d451b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_a0b99d451b FOREIGN KEY (experiment_id) REFERENCES public.experiments(id);


--
-- Name: notifications fk_rails_aa9c165c6f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_aa9c165c6f FOREIGN KEY (reminder_template_id) REFERENCES public.reminder_templates(id);


--
-- Name: exotel_phone_number_details fk_rails_b7da75c721; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exotel_phone_number_details
    ADD CONSTRAINT fk_rails_b7da75c721 FOREIGN KEY (patient_phone_number_id) REFERENCES public.patient_phone_numbers(id);


--
-- Name: treatment_group_memberships fk_rails_b892696282; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.treatment_group_memberships
    ADD CONSTRAINT fk_rails_b892696282 FOREIGN KEY (experiment_id) REFERENCES public.experiments(id);


--
-- Name: treatment_group_memberships fk_rails_ba05256ae6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.treatment_group_memberships
    ADD CONSTRAINT fk_rails_ba05256ae6 FOREIGN KEY (patient_id) REFERENCES public.patients(id);


--
-- Name: teleconsultations fk_rails_c436ea0008; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teleconsultations
    ADD CONSTRAINT fk_rails_c436ea0008 FOREIGN KEY (requester_id) REFERENCES public.users(id);


--
-- Name: facilities fk_rails_c44117c78f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.facilities
    ADD CONSTRAINT fk_rails_c44117c78f FOREIGN KEY (facility_group_id) REFERENCES public.facility_groups(id);


--
-- Name: protocol_drugs fk_rails_dbcef01693; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.protocol_drugs
    ADD CONSTRAINT fk_rails_dbcef01693 FOREIGN KEY (protocol_id) REFERENCES public.protocols(id);


--
-- Name: accesses fk_rails_e47574ce84; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accesses
    ADD CONSTRAINT fk_rails_e47574ce84 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: notifications fk_rails_e966d86b08; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_rails_e966d86b08 FOREIGN KEY (patient_id) REFERENCES public.patients(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20210517195627'),
('20210517201622'),
('20210517213259'),
('20210517214940'),
('20210517215935'),
('20210518072610'),
('20210518072611'),
('20210518074409'),
('20210518092103'),
('20210518094025'),
('20210518182324'),
('20210518212747'),
('20210603193527'),
('20210607235412'),
('20210614090147'),
('20210615191355'),
('20210620144826'),
('20210622142216'),
('20210622191111'),
('20210628154848'),
('20210702063413'),
('20210702192822'),
('20210706215522'),
('20210707014011'),
('20210708133404'),
('20210708133405'),
('20210712223435'),
('20210713134836'),
('20210714165255'),
('20210714183848'),
('20210715085219'),
('20210715120731'),
('20210715165453'),
('20210728062811'),
('20210728062812'),
('20210728100307'),
('20210728100308'),
('20210813061906'),
('20210826080108'),
('20210826121045'),
('20210907205603'),
('20210910200224'),
('20210915134540'),
('20210923204541'),
('20210924102745'),
('20210928134120'),
('20211007075808'),
('20211018065146'),
('20211018080612'),
('20211019135407'),
('20211019144905'),
('20211029070915'),
('20211105065243'),
('20211115070346'),
('20211123060535'),
('20211123060537'),
('20211125062406'),
('20211125072030'),
('20211201230130'),
('20211202183101'),
('20211207043358'),
('20211207043615'),
('20211209103527'),
('20211209104346'),
('20211209110618'),
('20211210152751'),
('20211210152752'),
('20211214014913'),
('20211215192748'),
('20211216144440'),
('20211216154413'),
('20211220230913'),
('20211231084747'),
('20211231110314'),
('20220106075216'),
('20220112142707'),
('20220118190607'),
('20220124212048'),
('20220124215220'),
('20220202091240'),
('20220203073617'),
('20220204224734'),
('20220209233034'),
('20220217102418'),
('20220217102500'),
('20220217202441'),
('20220223080958'),
('20220315095931'),
('20220321095014');


