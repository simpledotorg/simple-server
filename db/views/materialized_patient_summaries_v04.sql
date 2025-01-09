with latest_bp_passport as (
    select
        distinct on (patient_id)
        id,
        identifier,
        patient_id
    from patient_business_identifiers
    where identifier_type = 'simple_bp_passport' and deleted_at is null
    order by patient_id, device_created_at desc
), latest_phone_number as (
    select
        distinct on (patient_id)
        patient_phone_numbers.patient_id,
        patient_phone_numbers.number
    from patient_phone_numbers
    where deleted_at is null
    order by patient_id, device_created_at desc
), latest_medical_history as (
    SELECT 
        DISTINCT ON (patient_id)
        patient_id,
        hypertension,
        diabetes
    FROM
        medical_histories
    WHERE
        deleted_at IS NULL
),ranked_prescription_drugs as (
    select
        bp.id as bp_id,
        array_agg(array[name, dosage] order by prescription_drugs.is_protocol_drug desc, prescription_drugs.name, prescription_drugs.device_created_at desc) as blood_pressure_drugs,
        array_agg(name || '-' || dosage order by prescription_drugs.is_protocol_drug desc, prescription_drugs.name, prescription_drugs.device_created_at desc) as drug_strings
    from blood_pressures bp
        join prescription_drugs
            on prescription_drugs.patient_id = bp.patient_id
                and date(prescription_drugs.device_created_at) <= date(bp.recorded_at)
                and (prescription_drugs.is_deleted is false or (prescription_drugs.is_deleted is true and date(prescription_drugs.device_updated_at) > date(bp.recorded_at)))
    where bp.deleted_at is null and prescription_drugs.deleted_at is null
    group by bp.id
), blood_pressure_follow_up as (
    select
        distinct on (bp.patient_id, date(bp.recorded_at))
        bp.id bp_id,
        appointments.scheduled_date,
        appointments.device_created_at,
        appointments.facility_id, 
        appointments.deleted_at
    from blood_pressures bp
    join appointments on appointments.patient_id = bp.patient_id and date(appointments.device_created_at) = date(bp.recorded_at)
    order by bp.patient_id, date(bp.recorded_at), appointments.device_created_at desc
), blood_sugar_follow_up as (
    select
        distinct on (bs.patient_id, date(bs.recorded_at))
        bs.id bs_id,
        appointments.scheduled_date,
        appointments.device_created_at,
        appointments.facility_id, 
        appointments.deleted_at
    from blood_sugars bs
    join appointments on appointments.patient_id = bs.patient_id and date(appointments.device_created_at) = date(bs.recorded_at)
    order by bs.patient_id, date(bs.recorded_at), appointments.device_created_at desc
), ranked_blood_pressures as (
    select
        bp.id,
        bp.patient_id,
        bp.recorded_at as recorded_at,
        bp.systolic,
        bp.diastolic,
        f.name as facility_name,
        f.facility_type,
        f.district,
        f.state,
        follow_up_facility.name as follow_up_facility_name,
        a.scheduled_date as follow_up_date,
        greatest(0, date_part('day', a.scheduled_date - date_trunc('day', a.device_created_at)))::int as follow_up_days,

        bp_drugs.blood_pressure_drugs[1][1] as prescription_drug_1_name,
        bp_drugs.blood_pressure_drugs[1][2] as prescription_drug_1_dosage,

        bp_drugs.blood_pressure_drugs[2][1] as prescription_drug_2_name,
        bp_drugs.blood_pressure_drugs[2][2] as prescription_drug_2_dosage,

        bp_drugs.blood_pressure_drugs[3][1] as prescription_drug_3_name,
        bp_drugs.blood_pressure_drugs[3][2] as prescription_drug_3_dosage,

        bp_drugs.blood_pressure_drugs[4][1] as prescription_drug_4_name,
        bp_drugs.blood_pressure_drugs[4][2] as prescription_drug_4_dosage,

        bp_drugs.blood_pressure_drugs[5][1] as prescription_drug_5_name,
        bp_drugs.blood_pressure_drugs[5][2] as prescription_drug_5_dosage,

        (select string_agg(value, ', ') from unnest(bp_drugs.drug_strings[6:]) as value) as other_prescription_drugs,
        (select string_agg(value, ', ') from unnest(bp_drugs.drug_strings) as value) as all_prescription_drugs,

        rank() over (partition by bp.patient_id order by bp.recorded_at desc, bp.id) rank
    from blood_pressures bp
             left outer join facilities f on bp.facility_id = f.id
             left outer join ranked_prescription_drugs bp_drugs on bp.id = bp_drugs.bp_id
             left outer join blood_pressure_follow_up a on  a.bp_id = bp.id
             left outer join facilities follow_up_facility on follow_up_facility.id = a.facility_id
    where bp.deleted_at is null and a.deleted_at is null
), filtered_ranked_blood_pressures as (
    select
        rbp.id,
        rbp.patient_id,
        rbp.recorded_at as recorded_at,
        rbp.systolic,
        rbp.diastolic,
        rbp.facility_name,
        rbp.facility_type,
        rbp.district,
        rbp.state,
        rbp.follow_up_facility_name,
        rbp.follow_up_date,
        rbp.follow_up_days,

        rbp.prescription_drug_1_name,
        rbp.prescription_drug_1_dosage,
        rbp.prescription_drug_2_name,
        rbp.prescription_drug_2_dosage,
        rbp.prescription_drug_3_name,
        rbp.prescription_drug_3_dosage,
        rbp.prescription_drug_4_name,
        rbp.prescription_drug_4_dosage,
        rbp.prescription_drug_5_name,
        rbp.prescription_drug_5_dosage,

        rbp.other_prescription_drugs,
        rbp.all_prescription_drugs,

        case when rank = 2 and all_prescription_drugs != lag(all_prescription_drugs) over (partition by patient_id order by rank) then 1 else null end as the_medication_1_updated,
        case when rank = 3 and all_prescription_drugs != lag(all_prescription_drugs) over (partition by patient_id order by rank) then 1 else null end as the_medication_2_updated,
        case when rank = 4 and all_prescription_drugs != lag(all_prescription_drugs) over (partition by patient_id order by rank) then 1 else null end as the_medication_3_updated,

        rbp.rank
    from ranked_blood_pressures rbp
    where rank <= 4
), latest_blood_pressures as (
    select
        patient_id,

        max(case when rank = 1 then id::text end) as latest_blood_pressure_1_id,
        max(case when rank = 1 then recorded_at end) as latest_blood_pressure_1_recorded_at,
        max(case when rank = 1 then systolic end) as latest_blood_pressure_1_systolic,
        max(case when rank = 1 then diastolic end) as latest_blood_pressure_1_diastolic,
        max(case when rank = 1 then facility_name end) as latest_blood_pressure_1_facility_name,
        max(case when rank = 1 then facility_type end) as latest_blood_pressure_1_facility_type,
        max(case when rank = 1 then district end) as latest_blood_pressure_1_district,
        max(case when rank = 1 then state end) as latest_blood_pressure_1_state,
        max(case when rank = 1 then follow_up_facility_name end) as latest_blood_pressure_1_follow_up_facility_name,
        max(case when rank = 1 then follow_up_date end) as latest_blood_pressure_1_follow_up_date,
        max(case when rank = 1 then follow_up_days end) as latest_blood_pressure_1_follow_up_days,
        the_medication_1_updated as latest_blood_pressure_1_medication_updated,
        max(case when rank = 1 then prescription_drug_1_name end) as latest_blood_pressure_1_prescription_drug_1_name,
        max(case when rank = 1 then prescription_drug_1_dosage end) as latest_blood_pressure_1_prescription_drug_1_dosage,
        max(case when rank = 1 then prescription_drug_2_name end) as latest_blood_pressure_1_prescription_drug_2_name,
        max(case when rank = 1 then prescription_drug_2_dosage end) as latest_blood_pressure_1_prescription_drug_2_dosage,
        max(case when rank = 1 then prescription_drug_3_name end) as latest_blood_pressure_1_prescription_drug_3_name,
        max(case when rank = 1 then prescription_drug_3_dosage end) as latest_blood_pressure_1_prescription_drug_3_dosage,
        max(case when rank = 1 then prescription_drug_4_name end) as latest_blood_pressure_1_prescription_drug_4_name,
        max(case when rank = 1 then prescription_drug_4_dosage end) as latest_blood_pressure_1_prescription_drug_4_dosage,
        max(case when rank = 1 then prescription_drug_5_name end) as latest_blood_pressure_1_prescription_drug_5_name,
        max(case when rank = 1 then prescription_drug_5_dosage end) as latest_blood_pressure_1_prescription_drug_5_dosage,
        max(case when rank = 1 then other_prescription_drugs end) as latest_blood_pressure_1_other_prescription_drugs,

        max(case when rank = 2 then id::text end) as latest_blood_pressure_2_id,
        max(case when rank = 2 then recorded_at end) as latest_blood_pressure_2_recorded_at,
        max(case when rank = 2 then systolic end) as latest_blood_pressure_2_systolic,
        max(case when rank = 2 then diastolic end) as latest_blood_pressure_2_diastolic,
        max(case when rank = 2 then facility_name end) as latest_blood_pressure_2_facility_name,
        max(case when rank = 2 then facility_type end) as latest_blood_pressure_2_facility_type,
        max(case when rank = 2 then district end) as latest_blood_pressure_2_district,
        max(case when rank = 2 then state end) as latest_blood_pressure_2_state,
        max(case when rank = 2 then follow_up_facility_name end) as latest_blood_pressure_2_follow_up_facility_name,
        max(case when rank = 2 then follow_up_date end) as latest_blood_pressure_2_follow_up_date,
        max(case when rank = 2 then follow_up_days end) as latest_blood_pressure_2_follow_up_days,
        the_medication_2_updated as latest_blood_pressure_2_medication_updated,
        max(case when rank = 2 then prescription_drug_1_name end) as latest_blood_pressure_2_prescription_drug_1_name,
        max(case when rank = 2 then prescription_drug_1_dosage end) as latest_blood_pressure_2_prescription_drug_1_dosage,
        max(case when rank = 2 then prescription_drug_2_name end) as latest_blood_pressure_2_prescription_drug_2_name,
        max(case when rank = 2 then prescription_drug_2_dosage end) as latest_blood_pressure_2_prescription_drug_2_dosage,
        max(case when rank = 2 then prescription_drug_3_name end) as latest_blood_pressure_2_prescription_drug_3_name,
        max(case when rank = 2 then prescription_drug_3_dosage end) as latest_blood_pressure_2_prescription_drug_3_dosage,
        max(case when rank = 2 then prescription_drug_4_name end) as latest_blood_pressure_2_prescription_drug_4_name,
        max(case when rank = 2 then prescription_drug_4_dosage end) as latest_blood_pressure_2_prescription_drug_4_dosage,
        max(case when rank = 2 then prescription_drug_5_name end) as latest_blood_pressure_2_prescription_drug_5_name,
        max(case when rank = 2 then prescription_drug_5_dosage end) as latest_blood_pressure_2_prescription_drug_5_dosage,
        max(case when rank = 2 then other_prescription_drugs end) as latest_blood_pressure_2_other_prescription_drugs,

        max(case when rank = 3 then id::text end) as latest_blood_pressure_3_id,
        max(case when rank = 3 then recorded_at end) as latest_blood_pressure_3_recorded_at,
        max(case when rank = 3 then systolic end) as latest_blood_pressure_3_systolic,
        max(case when rank = 3 then diastolic end) as latest_blood_pressure_3_diastolic,
        max(case when rank = 3 then facility_name end) as latest_blood_pressure_3_facility_name,
        max(case when rank = 3 then facility_type end) as latest_blood_pressure_3_facility_type,
        max(case when rank = 3 then district end) as latest_blood_pressure_3_district,
        max(case when rank = 3 then state end) as latest_blood_pressure_3_state,
        max(case when rank = 3 then follow_up_facility_name end) as latest_blood_pressure_3_follow_up_facility_name,
        max(case when rank = 3 then follow_up_date end) as latest_blood_pressure_3_follow_up_date,
        max(case when rank = 3 then follow_up_days end) as latest_blood_pressure_3_follow_up_days,
        the_medication_3_updated as latest_blood_pressure_3_medication_updated,
        max(case when rank = 3 then prescription_drug_1_name end) as latest_blood_pressure_3_prescription_drug_1_name,
        max(case when rank = 3 then prescription_drug_1_dosage end) as latest_blood_pressure_3_prescription_drug_1_dosage,
        max(case when rank = 3 then prescription_drug_2_name end) as latest_blood_pressure_3_prescription_drug_2_name,
        max(case when rank = 3 then prescription_drug_2_dosage end) as latest_blood_pressure_3_prescription_drug_2_dosage,
        max(case when rank = 3 then prescription_drug_3_name end) as latest_blood_pressure_3_prescription_drug_3_name,
        max(case when rank = 3 then prescription_drug_3_dosage end) as latest_blood_pressure_3_prescription_drug_3_dosage,
        max(case when rank = 3 then prescription_drug_4_name end) as latest_blood_pressure_3_prescription_drug_4_name,
        max(case when rank = 3 then prescription_drug_4_dosage end) as latest_blood_pressure_3_prescription_drug_4_dosage,
        max(case when rank = 3 then prescription_drug_5_name end) as latest_blood_pressure_3_prescription_drug_5_name,
        max(case when rank = 3 then prescription_drug_5_dosage end) as latest_blood_pressure_3_prescription_drug_5_dosage,
        max(case when rank = 3 then other_prescription_drugs end) as latest_blood_pressure_3_other_prescription_drugs

    from filtered_ranked_blood_pressures
    group by
      patient_id,
      the_medication_1_updated,
      the_medication_2_updated,
      the_medication_3_updated
), ranked_blood_sugars as (
    select
        bs.id,
        bs.patient_id,
        bs.recorded_at as recorded_at,
        bs.blood_sugar_type,
        bs.blood_sugar_value,
        f.name as facility_name,
        f.facility_type,
        f.district,
        f.state,
        follow_up_facility.name as follow_up_facility_name,
        a.scheduled_date as follow_up_date,
        greatest(0, date_part('day', a.scheduled_date - date_trunc('day',a.device_created_at)))::int as follow_up_days,
        rank() over (partition by bs.patient_id order by bs.recorded_at desc, bs.id) rank
    from blood_sugars bs
    left outer join facilities f on bs.facility_id = f.id
    left outer join blood_sugar_follow_up a on a.bs_id = bs.id
    left outer join facilities follow_up_facility on follow_up_facility.id = a.facility_id
    where bs.deleted_at is null and a.deleted_at is null
), filtered_ranked_blood_sugars as (
    select
        rbs.id,
        rbs.patient_id,
        rbs.recorded_at,
        rbs.blood_sugar_type,
        rbs.blood_sugar_value,
        rbs.facility_name,
        rbs.facility_type,
        rbs.district,
        rbs.state,
        rbs.follow_up_facility_name,
        rbs.follow_up_date,
        rbs.follow_up_days,
        rbs.rank
    from ranked_blood_sugars rbs
    where rank <= 3
), latest_blood_sugars as (
    select
        patient_id,
        MAX(CASE WHEN rank = 1 THEN id::text END) AS latest_blood_sugar_1_id,
        MAX(CASE WHEN rank = 1 THEN recorded_at END) AS latest_blood_sugar_1_recorded_at,
        MAX(CASE WHEN rank = 1 THEN blood_sugar_type END) AS latest_blood_sugar_1_blood_sugar_type,
        MAX(CASE WHEN rank = 1 THEN blood_sugar_value END) AS latest_blood_sugar_1_blood_sugar_value,
        MAX(CASE WHEN rank = 1 THEN facility_name END) AS latest_blood_sugar_1_facility_name,
        MAX(CASE WHEN rank = 1 THEN facility_type END) AS latest_blood_sugar_1_facility_type,
        MAX(CASE WHEN rank = 1 THEN district END) AS latest_blood_sugar_1_district,
        MAX(CASE WHEN rank = 1 THEN state END) AS latest_blood_sugar_1_state,
        MAX(CASE WHEN rank = 1 THEN follow_up_facility_name END) AS latest_blood_sugar_1_follow_up_facility_name,
        MAX(CASE WHEN rank = 1 THEN follow_up_date END) AS latest_blood_sugar_1_follow_up_date,
        MAX(CASE WHEN rank = 1 THEN follow_up_days END) AS latest_blood_sugar_1_follow_up_days,
        MAX(CASE WHEN rank = 2 THEN id::text END) AS latest_blood_sugar_2_id,
        MAX(CASE WHEN rank = 2 THEN recorded_at END) AS latest_blood_sugar_2_recorded_at,
        MAX(CASE WHEN rank = 2 THEN blood_sugar_type END) AS latest_blood_sugar_2_blood_sugar_type,
        MAX(CASE WHEN rank = 2 THEN blood_sugar_value END) AS latest_blood_sugar_2_blood_sugar_value,
        MAX(CASE WHEN rank = 2 THEN facility_name END) AS latest_blood_sugar_2_facility_name,
        MAX(CASE WHEN rank = 2 THEN facility_type END) AS latest_blood_sugar_2_facility_type,
        MAX(CASE WHEN rank = 2 THEN district END) AS latest_blood_sugar_2_district,
        MAX(CASE WHEN rank = 2 THEN state END) AS latest_blood_sugar_2_state,
        MAX(CASE WHEN rank = 2 THEN follow_up_facility_name END) AS latest_blood_sugar_2_follow_up_facility_name,
        MAX(CASE WHEN rank = 2 THEN follow_up_date END) AS latest_blood_sugar_2_follow_up_date,
        MAX(CASE WHEN rank = 2 THEN follow_up_days END) AS latest_blood_sugar_2_follow_up_days,
        MAX(CASE WHEN rank = 3 THEN id::text END) AS latest_blood_sugar_3_id,
        MAX(CASE WHEN rank = 3 THEN recorded_at END) AS latest_blood_sugar_3_recorded_at,
        MAX(CASE WHEN rank = 3 THEN blood_sugar_type END) AS latest_blood_sugar_3_blood_sugar_type,
        MAX(CASE WHEN rank = 3 THEN blood_sugar_value END) AS latest_blood_sugar_3_blood_sugar_value,
        MAX(CASE WHEN rank = 3 THEN facility_name END) AS latest_blood_sugar_3_facility_name,
        MAX(CASE WHEN rank = 3 THEN facility_type END) AS latest_blood_sugar_3_facility_type,
        MAX(CASE WHEN rank = 3 THEN district END) AS latest_blood_sugar_3_district,
        MAX(CASE WHEN rank = 3 THEN state END) AS latest_blood_sugar_3_state,
        MAX(CASE WHEN rank = 3 THEN follow_up_facility_name END) AS latest_blood_sugar_3_follow_up_facility_name,
        MAX(CASE WHEN rank = 3 THEN follow_up_date END) AS latest_blood_sugar_3_follow_up_date,
        MAX(CASE WHEN rank = 3 THEN follow_up_days END) AS latest_blood_sugar_3_follow_up_days
    from filtered_ranked_blood_sugars
    group by patient_id
    order by patient_id
), next_scheduled_appointment as (
    select distinct on (patient_id)
        appointments.id,
        appointments.scheduled_date,
        appointments.status,
        appointments.remind_on,
        appointments.patient_id,
        f.id as appointment_facility_id,
        f.name as appointment_facility_name,
        f.facility_type appointment_facility_type,
        f.district as appointment_district,
        f.state as appointment_state
    from appointments
    left outer join facilities f on f.id = appointments.facility_id and appointments.status = 'scheduled'
    where appointments.deleted_at is null
    order by patient_id, device_created_at desc
)

select distinct  on (p.id)
    p.id,
    p.recorded_at,
    p.full_name as full_name,
    latest_bp_passport.id as latest_bp_passport_id,
    latest_bp_passport.identifier as latest_bp_passport_identifier,
    extract(year from coalesce(
        age(p.date_of_birth),
        make_interval(years => p.age) + age(p.age_updated_at)
    )) as current_age,
    p.gender,
    p.status,
    latest_phone_number.number as latest_phone_number,
    addresses.village_or_colony,
    addresses.street_address,
    addresses.district,
    addresses.zone,
    addresses.state,

    assigned_facility.name as assigned_facility_name,
    assigned_facility.facility_type as assigned_facility_type,
    assigned_facility.state as assigned_facility_state,
    assigned_facility.district as assigned_facility_district,

    registration_facility.name as registration_facility_name,
    registration_facility.facility_type as registration_facility_type,
    registration_facility.state as registration_facility_state,
    registration_facility.district as registration_facility_district,

    mh.hypertension,
    mh.diabetes,

    greatest(0, date_part('day', NOW() - next_scheduled_appointment.scheduled_date)) as days_overdue,
    next_scheduled_appointment.id as next_scheduled_appointment_id,
    next_scheduled_appointment.scheduled_date as next_scheduled_appointment_scheduled_date,
    next_scheduled_appointment.status as next_scheduled_appointment_status,
    next_scheduled_appointment.remind_on as next_scheduled_appointment_remind_on,
    next_scheduled_appointment.appointment_facility_id as next_scheduled_appointment_facility_id,
    next_scheduled_appointment.appointment_facility_name as next_scheduled_appointment_facility_name,
    next_scheduled_appointment.appointment_facility_type as next_scheduled_appointment_facility_type,
    next_scheduled_appointment.appointment_district as next_scheduled_appointment_district,
    next_scheduled_appointment.appointment_state as next_scheduled_appointment_state,

    latest_blood_pressures.latest_blood_pressure_1_id,
    latest_blood_pressures.latest_blood_pressure_1_recorded_at,
    latest_blood_pressures.latest_blood_pressure_1_systolic,
    latest_blood_pressures.latest_blood_pressure_1_diastolic,
    latest_blood_pressures.latest_blood_pressure_1_facility_name,
    latest_blood_pressures.latest_blood_pressure_1_facility_type,
    latest_blood_pressures.latest_blood_pressure_1_district,
    latest_blood_pressures.latest_blood_pressure_1_state,
    latest_blood_pressures.latest_blood_pressure_1_follow_up_facility_name,
    latest_blood_pressures.latest_blood_pressure_1_follow_up_date,
    latest_blood_pressures.latest_blood_pressure_1_follow_up_days,
    latest_blood_pressures.latest_blood_pressure_1_medication_updated,
    latest_blood_pressures.latest_blood_pressure_1_prescription_drug_1_name,
    latest_blood_pressures.latest_blood_pressure_1_prescription_drug_1_dosage,
    latest_blood_pressures.latest_blood_pressure_1_prescription_drug_2_name,
    latest_blood_pressures.latest_blood_pressure_1_prescription_drug_2_dosage,
    latest_blood_pressures.latest_blood_pressure_1_prescription_drug_3_name,
    latest_blood_pressures.latest_blood_pressure_1_prescription_drug_3_dosage,
    latest_blood_pressures.latest_blood_pressure_1_prescription_drug_4_name,
    latest_blood_pressures.latest_blood_pressure_1_prescription_drug_4_dosage,
    latest_blood_pressures.latest_blood_pressure_1_prescription_drug_5_name,
    latest_blood_pressures.latest_blood_pressure_1_prescription_drug_5_dosage,
    latest_blood_pressures.latest_blood_pressure_1_other_prescription_drugs,

    latest_blood_pressures.latest_blood_pressure_2_id,
    latest_blood_pressures.latest_blood_pressure_2_recorded_at,
    latest_blood_pressures.latest_blood_pressure_2_systolic,
    latest_blood_pressures.latest_blood_pressure_2_diastolic,
    latest_blood_pressures.latest_blood_pressure_2_facility_name,
    latest_blood_pressures.latest_blood_pressure_2_facility_type,
    latest_blood_pressures.latest_blood_pressure_2_district,
    latest_blood_pressures.latest_blood_pressure_2_state,
    latest_blood_pressures.latest_blood_pressure_2_follow_up_facility_name,
    latest_blood_pressures.latest_blood_pressure_2_follow_up_date,
    latest_blood_pressures.latest_blood_pressure_2_follow_up_days,
    latest_blood_pressures.latest_blood_pressure_2_medication_updated,
    latest_blood_pressures.latest_blood_pressure_2_prescription_drug_1_name,
    latest_blood_pressures.latest_blood_pressure_2_prescription_drug_1_dosage,
    latest_blood_pressures.latest_blood_pressure_2_prescription_drug_2_name,
    latest_blood_pressures.latest_blood_pressure_2_prescription_drug_2_dosage,
    latest_blood_pressures.latest_blood_pressure_2_prescription_drug_3_name,
    latest_blood_pressures.latest_blood_pressure_2_prescription_drug_3_dosage,
    latest_blood_pressures.latest_blood_pressure_2_prescription_drug_4_name,
    latest_blood_pressures.latest_blood_pressure_2_prescription_drug_4_dosage,
    latest_blood_pressures.latest_blood_pressure_2_prescription_drug_5_name,
    latest_blood_pressures.latest_blood_pressure_2_prescription_drug_5_dosage,
    latest_blood_pressures.latest_blood_pressure_2_other_prescription_drugs,

    latest_blood_pressures.latest_blood_pressure_3_id,
    latest_blood_pressures.latest_blood_pressure_3_recorded_at,
    latest_blood_pressures.latest_blood_pressure_3_systolic,
    latest_blood_pressures.latest_blood_pressure_3_diastolic,
    latest_blood_pressures.latest_blood_pressure_3_facility_name,
    latest_blood_pressures.latest_blood_pressure_3_facility_type,
    latest_blood_pressures.latest_blood_pressure_3_district,
    latest_blood_pressures.latest_blood_pressure_3_state,
    latest_blood_pressures.latest_blood_pressure_3_follow_up_facility_name,
    latest_blood_pressures.latest_blood_pressure_3_follow_up_date,
    latest_blood_pressures.latest_blood_pressure_3_follow_up_days,
    latest_blood_pressures.latest_blood_pressure_3_medication_updated,
    latest_blood_pressures.latest_blood_pressure_3_prescription_drug_1_name,
    latest_blood_pressures.latest_blood_pressure_3_prescription_drug_1_dosage,
    latest_blood_pressures.latest_blood_pressure_3_prescription_drug_2_name,
    latest_blood_pressures.latest_blood_pressure_3_prescription_drug_2_dosage,
    latest_blood_pressures.latest_blood_pressure_3_prescription_drug_3_name,
    latest_blood_pressures.latest_blood_pressure_3_prescription_drug_3_dosage,
    latest_blood_pressures.latest_blood_pressure_3_prescription_drug_4_name,
    latest_blood_pressures.latest_blood_pressure_3_prescription_drug_4_dosage,
    latest_blood_pressures.latest_blood_pressure_3_prescription_drug_5_name,
    latest_blood_pressures.latest_blood_pressure_3_prescription_drug_5_dosage,
    latest_blood_pressures.latest_blood_pressure_3_other_prescription_drugs,

    latest_blood_sugars.latest_blood_sugar_1_id,
    latest_blood_sugars.latest_blood_sugar_1_recorded_at,
    latest_blood_sugars.latest_blood_sugar_1_blood_sugar_type,
    latest_blood_sugars.latest_blood_sugar_1_blood_sugar_value,
    latest_blood_sugars.latest_blood_sugar_1_facility_name,
    latest_blood_sugars.latest_blood_sugar_1_facility_type,
    latest_blood_sugars.latest_blood_sugar_1_district,
    latest_blood_sugars.latest_blood_sugar_1_state,
    latest_blood_sugars.latest_blood_sugar_1_follow_up_facility_name,
    latest_blood_sugars.latest_blood_sugar_1_follow_up_date,
    latest_blood_sugars.latest_blood_sugar_1_follow_up_days,

    latest_blood_sugars.latest_blood_sugar_2_id,
    latest_blood_sugars.latest_blood_sugar_2_recorded_at,
    latest_blood_sugars.latest_blood_sugar_2_blood_sugar_type,
    latest_blood_sugars.latest_blood_sugar_2_blood_sugar_value,
    latest_blood_sugars.latest_blood_sugar_2_facility_name,
    latest_blood_sugars.latest_blood_sugar_2_facility_type,
    latest_blood_sugars.latest_blood_sugar_2_district,
    latest_blood_sugars.latest_blood_sugar_2_state,
    latest_blood_sugars.latest_blood_sugar_2_follow_up_facility_name,
    latest_blood_sugars.latest_blood_sugar_2_follow_up_date,
    latest_blood_sugars.latest_blood_sugar_2_follow_up_days,

    latest_blood_sugars.latest_blood_sugar_3_id,
    latest_blood_sugars.latest_blood_sugar_3_recorded_at,
    latest_blood_sugars.latest_blood_sugar_3_blood_sugar_type,
    latest_blood_sugars.latest_blood_sugar_3_blood_sugar_value,
    latest_blood_sugars.latest_blood_sugar_3_facility_name,
    latest_blood_sugars.latest_blood_sugar_3_facility_type,
    latest_blood_sugars.latest_blood_sugar_3_district,
    latest_blood_sugars.latest_blood_sugar_3_state,
    latest_blood_sugars.latest_blood_sugar_3_follow_up_facility_name,
    latest_blood_sugars.latest_blood_sugar_3_follow_up_date,
    latest_blood_sugars.latest_blood_sugar_3_follow_up_days
from patients p
left outer join latest_bp_passport on latest_bp_passport.patient_id = p.id
left outer join latest_phone_number on latest_phone_number.patient_id = p.id
left outer join addresses on addresses.id = p.address_id
left outer join facilities assigned_facility on assigned_facility.id = p.assigned_facility_id
left outer join facilities registration_facility on registration_facility.id = p.registration_facility_id
left outer join latest_medical_history mh on mh.patient_id = p.id
left outer join latest_blood_pressures on latest_blood_pressures.patient_id = p.id
left outer join latest_blood_sugars on latest_blood_sugars.patient_id = p.id
left outer join next_scheduled_appointment on next_scheduled_appointment.patient_id = p.id
where p.deleted_at is null
