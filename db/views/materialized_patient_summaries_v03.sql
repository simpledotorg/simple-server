with latest_bp_passport as (
    select distinct on (patient_id) *
    from patient_business_identifiers
    where identifier_type = 'simple_bp_passport' and deleted_at is null
    order by patient_id, device_created_at desc
), latest_phone_number as (
    select distinct on (patient_id) *
    from patient_phone_numbers
    where deleted_at is null
    order by patient_id, device_created_at desc
), latest_medical_history as (
    SELECT DISTINCT ON (patient_id) * FROM medical_histories WHERE deleted_at IS NULL
),ranked_prescription_drugs as (
    select
        bp.id as bp_id,
        prescription_drugs.*,
        rank() over (partition by bp.id order by prescription_drugs.is_protocol_drug desc, prescription_drugs.name, prescription_drugs.device_created_at desc) rank
    from blood_pressures bp
    left outer join prescription_drugs
        on prescription_drugs.patient_id = bp.patient_id
        and (prescription_drugs.device_created_at < date(bp.recorded_at) + '1 day'::interval)
        and (prescription_drugs.is_deleted is false or (prescription_drugs.is_deleted is true and prescription_drugs.updated_at >= date(bp.recorded_at) + '1 day'::interval))
    where bp.deleted_at is null and prescription_drugs.deleted_at is null
), other_medications as (
    select
        bp_id,
        string_agg (name || '-' || dosage, ', ') filter (where rank > 5) as other_prescription_drugs,
        string_agg (name || '-' || dosage, ', ' order by rank) as all_prescription_drugs
    from ranked_prescription_drugs
    group by bp_id
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

        pd_1.name as prescription_drug_1_name,
        pd_1.dosage as prescription_drug_1_dosage,

        pd_2.name as prescription_drug_2_name,
        pd_2.dosage as prescription_drug_2_dosage,

        pd_3.name as prescription_drug_3_name,
        pd_3.dosage as prescription_drug_3_dosage,

        pd_4.name as prescription_drug_4_name,
        pd_4.dosage as prescription_drug_4_dosage,

        pd_5.name as prescription_drug_5_name,
        pd_5.dosage as prescription_drug_5_dosage,

        other_medications.other_prescription_drugs,
        other_medications.all_prescription_drugs,

        rank() over (partition by bp.patient_id order by bp.recorded_at desc) rank
    from blood_pressures bp
    left outer join facilities f on bp.facility_id = f.id
    left outer join appointments a on a.patient_id = bp.patient_id and date_trunc('day', a.device_created_at) = date_trunc('day', bp.recorded_at)
    left outer join facilities follow_up_facility on follow_up_facility.id = a.facility_id
    left outer join ranked_prescription_drugs pd_1 on bp.id = pd_1.bp_id and pd_1.rank = 1
    left outer join ranked_prescription_drugs pd_2 on bp.id = pd_2.bp_id and pd_2.rank = 2
    left outer join ranked_prescription_drugs pd_3 on bp.id = pd_3.bp_id and pd_3.rank = 3
    left outer join ranked_prescription_drugs pd_4 on bp.id = pd_4.bp_id and pd_4.rank = 4
    left outer join ranked_prescription_drugs pd_5 on bp.id = pd_5.bp_id and pd_5.rank = 5
    left outer join other_medications on pd_1.bp_id = other_medications.bp_id
    where bp.deleted_at is null and a.deleted_at is null
), latest_blood_pressures as (
    select
        latest_blood_pressure_1.patient_id as patient_id,

        latest_blood_pressure_1.id as latest_blood_pressure_1_id,
        latest_blood_pressure_1.recorded_at as latest_blood_pressure_1_recorded_at,
        latest_blood_pressure_1.systolic as latest_blood_pressure_1_systolic,
        latest_blood_pressure_1.diastolic as latest_blood_pressure_1_diastolic,
        latest_blood_pressure_1.facility_name as latest_blood_pressure_1_facility_name,
        latest_blood_pressure_1.facility_type as latest_blood_pressure_1_facility_type,
        latest_blood_pressure_1.district as latest_blood_pressure_1_district,
        latest_blood_pressure_1.state as latest_blood_pressure_1_state,
        latest_blood_pressure_1.follow_up_facility_name as latest_blood_pressure_1_follow_up_facility_name,
        latest_blood_pressure_1.follow_up_date as latest_blood_pressure_1_follow_up_date,
        latest_blood_pressure_1.follow_up_days as latest_blood_pressure_1_follow_up_days,
        latest_blood_pressure_1.all_prescription_drugs != latest_blood_pressure_2.all_prescription_drugs as latest_blood_pressure_1_medication_updated,
        latest_blood_pressure_1.prescription_drug_1_name as latest_blood_pressure_1_prescription_drug_1_name,
        latest_blood_pressure_1.prescription_drug_1_dosage as latest_blood_pressure_1_prescription_drug_1_dosage,
        latest_blood_pressure_1.prescription_drug_2_name as latest_blood_pressure_1_prescription_drug_2_name,
        latest_blood_pressure_1.prescription_drug_2_dosage as latest_blood_pressure_1_prescription_drug_2_dosage,
        latest_blood_pressure_1.prescription_drug_3_name as latest_blood_pressure_1_prescription_drug_3_name,
        latest_blood_pressure_1.prescription_drug_3_dosage as latest_blood_pressure_1_prescription_drug_3_dosage,
        latest_blood_pressure_1.prescription_drug_4_name as latest_blood_pressure_1_prescription_drug_4_name,
        latest_blood_pressure_1.prescription_drug_4_dosage as latest_blood_pressure_1_prescription_drug_4_dosage,
        latest_blood_pressure_1.prescription_drug_5_name as latest_blood_pressure_1_prescription_drug_5_name,
        latest_blood_pressure_1.prescription_drug_5_dosage as latest_blood_pressure_1_prescription_drug_5_dosage,
        latest_blood_pressure_1.other_prescription_drugs as latest_blood_pressure_1_other_prescription_drugs,

        latest_blood_pressure_2.id as latest_blood_pressure_2_id,
        latest_blood_pressure_2.recorded_at as latest_blood_pressure_2_recorded_at,
        latest_blood_pressure_2.systolic as latest_blood_pressure_2_systolic,
        latest_blood_pressure_2.diastolic as latest_blood_pressure_2_diastolic,
        latest_blood_pressure_2.facility_name as latest_blood_pressure_2_facility_name,
        latest_blood_pressure_2.facility_type as latest_blood_pressure_2_facility_type,
        latest_blood_pressure_2.district as latest_blood_pressure_2_district,
        latest_blood_pressure_2.state as latest_blood_pressure_2_state,
        latest_blood_pressure_2.follow_up_facility_name as latest_blood_pressure_2_follow_up_facility_name,
        latest_blood_pressure_2.follow_up_date as latest_blood_pressure_2_follow_up_date,
        latest_blood_pressure_2.follow_up_days as latest_blood_pressure_2_follow_up_days,
        latest_blood_pressure_2.all_prescription_drugs != latest_blood_pressure_3.all_prescription_drugs as latest_blood_pressure_2_medication_updated,
        latest_blood_pressure_2.prescription_drug_1_name as latest_blood_pressure_2_prescription_drug_1_name,
        latest_blood_pressure_2.prescription_drug_1_dosage as latest_blood_pressure_2_prescription_drug_1_dosage,
        latest_blood_pressure_2.prescription_drug_2_name as latest_blood_pressure_2_prescription_drug_2_name,
        latest_blood_pressure_2.prescription_drug_2_dosage as latest_blood_pressure_2_prescription_drug_2_dosage,
        latest_blood_pressure_2.prescription_drug_3_name as latest_blood_pressure_2_prescription_drug_3_name,
        latest_blood_pressure_2.prescription_drug_3_dosage as latest_blood_pressure_2_prescription_drug_3_dosage,
        latest_blood_pressure_2.prescription_drug_4_name as latest_blood_pressure_2_prescription_drug_4_name,
        latest_blood_pressure_2.prescription_drug_4_dosage as latest_blood_pressure_2_prescription_drug_4_dosage,
        latest_blood_pressure_2.prescription_drug_5_name as latest_blood_pressure_2_prescription_drug_5_name,
        latest_blood_pressure_2.prescription_drug_5_dosage as latest_blood_pressure_2_prescription_drug_5_dosage,
        latest_blood_pressure_2.other_prescription_drugs as latest_blood_pressure_2_other_prescription_drugs,

        latest_blood_pressure_3.id as latest_blood_pressure_3_id,
        latest_blood_pressure_3.recorded_at as latest_blood_pressure_3_recorded_at,
        latest_blood_pressure_3.systolic as latest_blood_pressure_3_systolic,
        latest_blood_pressure_3.diastolic as latest_blood_pressure_3_diastolic,
        latest_blood_pressure_3.facility_name as latest_blood_pressure_3_facility_name,
        latest_blood_pressure_3.facility_type as latest_blood_pressure_3_facility_type,
        latest_blood_pressure_3.district as latest_blood_pressure_3_district,
        latest_blood_pressure_3.state as latest_blood_pressure_3_state,
        latest_blood_pressure_3.follow_up_facility_name as latest_blood_pressure_3_follow_up_facility_name,
        latest_blood_pressure_3.follow_up_date as latest_blood_pressure_3_follow_up_date,
        latest_blood_pressure_3.follow_up_days as latest_blood_pressure_3_follow_up_days,
        latest_blood_pressure_3.all_prescription_drugs != latest_blood_pressure_4.all_prescription_drugs as latest_blood_pressure_3_medication_updated,
        latest_blood_pressure_3.prescription_drug_1_name as latest_blood_pressure_3_prescription_drug_1_name,
        latest_blood_pressure_3.prescription_drug_1_dosage as latest_blood_pressure_3_prescription_drug_1_dosage,
        latest_blood_pressure_3.prescription_drug_2_name as latest_blood_pressure_3_prescription_drug_2_name,
        latest_blood_pressure_3.prescription_drug_2_dosage as latest_blood_pressure_3_prescription_drug_2_dosage,
        latest_blood_pressure_3.prescription_drug_3_name as latest_blood_pressure_3_prescription_drug_3_name,
        latest_blood_pressure_3.prescription_drug_3_dosage as latest_blood_pressure_3_prescription_drug_3_dosage,
        latest_blood_pressure_3.prescription_drug_4_name as latest_blood_pressure_3_prescription_drug_4_name,
        latest_blood_pressure_3.prescription_drug_4_dosage as latest_blood_pressure_3_prescription_drug_4_dosage,
        latest_blood_pressure_3.prescription_drug_5_name as latest_blood_pressure_3_prescription_drug_5_name,
        latest_blood_pressure_3.prescription_drug_5_dosage as latest_blood_pressure_3_prescription_drug_5_dosage,
        latest_blood_pressure_3.other_prescription_drugs as latest_blood_pressure_3_other_prescription_drugs

    from ranked_blood_pressures latest_blood_pressure_1
    left outer join ranked_blood_pressures latest_blood_pressure_2 on latest_blood_pressure_2.patient_id = latest_blood_pressure_1.patient_id and latest_blood_pressure_2.rank = 2
    left outer join ranked_blood_pressures latest_blood_pressure_3 on latest_blood_pressure_3.patient_id = latest_blood_pressure_1.patient_id and latest_blood_pressure_3.rank = 3
    left outer join ranked_blood_pressures latest_blood_pressure_4 on latest_blood_pressure_4.patient_id = latest_blood_pressure_1.patient_id and latest_blood_pressure_4.rank = 4
    where latest_blood_pressure_1.rank = 1
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
        greatest(0, date_part('day', a.scheduled_date -  date_trunc('day',a.device_created_at)))::int as follow_up_days,
        rank() over (partition by bs.patient_id order by bs.recorded_at desc) rank
    from blood_sugars bs
    left outer join facilities f on bs.facility_id = f.id
    left outer join appointments a on a.patient_id = bs.patient_id and date_trunc('day', a.device_created_at) = date_trunc('day', bs.recorded_at)
    left outer join facilities follow_up_facility on follow_up_facility.id = a.facility_id
    where bs.deleted_at is null and a.deleted_at is null
), latest_blood_sugars as (
    select
        latest_blood_sugar_1.patient_id as patient_id,

        latest_blood_sugar_1.id as latest_blood_sugar_1_id,
        latest_blood_sugar_1.recorded_at as latest_blood_sugar_1_recorded_at,
        latest_blood_sugar_1.blood_sugar_type as latest_blood_sugar_1_blood_sugar_type,
        latest_blood_sugar_1.blood_sugar_value as latest_blood_sugar_1_blood_sugar_value,
        latest_blood_sugar_1.facility_name as latest_blood_sugar_1_facility_name,
        latest_blood_sugar_1.facility_type as latest_blood_sugar_1_facility_type,
        latest_blood_sugar_1.district as latest_blood_sugar_1_district,
        latest_blood_sugar_1.state as latest_blood_sugar_1_state,
        latest_blood_sugar_1.follow_up_facility_name as latest_blood_sugar_1_follow_up_facility_name,
        latest_blood_sugar_1.follow_up_date as latest_blood_sugar_1_follow_up_date,
        latest_blood_sugar_1.follow_up_days as latest_blood_sugar_1_follow_up_days,

        latest_blood_sugar_2.id as latest_blood_sugar_2_id,
        latest_blood_sugar_2.recorded_at as latest_blood_sugar_2_recorded_at,
        latest_blood_sugar_2.blood_sugar_type as latest_blood_sugar_2_blood_sugar_type,
        latest_blood_sugar_2.blood_sugar_value as latest_blood_sugar_2_blood_sugar_value,
        latest_blood_sugar_2.facility_name as latest_blood_sugar_2_facility_name,
        latest_blood_sugar_2.facility_type as latest_blood_sugar_2_facility_type,
        latest_blood_sugar_2.district as latest_blood_sugar_2_district,
        latest_blood_sugar_2.state as latest_blood_sugar_2_state,
        latest_blood_sugar_2.follow_up_facility_name as latest_blood_sugar_2_follow_up_facility_name,
        latest_blood_sugar_2.follow_up_date as latest_blood_sugar_2_follow_up_date,
        latest_blood_sugar_2.follow_up_days as latest_blood_sugar_2_follow_up_days,

        latest_blood_sugar_3.id as latest_blood_sugar_3_id,
        latest_blood_sugar_3.recorded_at as latest_blood_sugar_3_recorded_at,
        latest_blood_sugar_3.blood_sugar_type as latest_blood_sugar_3_blood_sugar_type,
        latest_blood_sugar_3.blood_sugar_value as latest_blood_sugar_3_blood_sugar_value,
        latest_blood_sugar_3.facility_name as latest_blood_sugar_3_facility_name,
        latest_blood_sugar_3.facility_type as latest_blood_sugar_3_facility_type,
        latest_blood_sugar_3.district as latest_blood_sugar_3_district,
        latest_blood_sugar_3.state as latest_blood_sugar_3_state,
        latest_blood_sugar_3.follow_up_facility_name as latest_blood_sugar_3_follow_up_facility_name,
        latest_blood_sugar_3.follow_up_date as latest_blood_sugar_3_follow_up_date,
        latest_blood_sugar_3.follow_up_days as latest_blood_sugar_3_follow_up_days

    from ranked_blood_sugars latest_blood_sugar_1
    left outer join ranked_blood_sugars latest_blood_sugar_2 on latest_blood_sugar_2.patient_id = latest_blood_sugar_1.patient_id and latest_blood_sugar_2.rank = 2
    left outer join ranked_blood_sugars latest_blood_sugar_3 on latest_blood_sugar_3.patient_id = latest_blood_sugar_1.patient_id and latest_blood_sugar_3.rank = 3
    where latest_blood_sugar_1.rank = 1
), next_scheduled_appointment as (
    select distinct on (patient_id)
        appointments.*,
        f.id as appointment_facility_id,
        f.name as appointment_facility_name,
        f.facility_type appointment_facility_type,
        f.district as appointment_district,
        f.state as appointment_state
    from appointments
    left outer join facilities f on f.id = appointments.facility_id
    where appointments.deleted_at is null and appointments.status = 'scheduled'
    order by patient_id, device_created_at desc
)

select
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
    latest_blood_sugars.latest_blood_sugar_3_follow_up_days,

    (CASE
         WHEN next_scheduled_appointment.scheduled_date IS NULL THEN 0
         WHEN next_scheduled_appointment.scheduled_date > date_trunc('day', NOW() - interval '30 days') THEN 0
         WHEN (latest_blood_pressure_1_systolic >= 180
             OR latest_blood_pressure_1_diastolic >= 110) THEN 1
         WHEN ((mh.prior_heart_attack = 'yes'
             OR mh.prior_stroke = 'yes')
             AND (latest_blood_pressure_1_systolic >= 140
                 OR latest_blood_pressure_1_diastolic >= 90)) THEN 1
         WHEN ((latest_blood_sugar_1_blood_sugar_type = 'random'
             AND latest_blood_sugar_1_blood_sugar_value >= 300)
             OR (latest_blood_sugar_1_blood_sugar_type = 'post_prandial'
                 AND latest_blood_sugar_1_blood_sugar_value >= 300)
             OR (latest_blood_sugar_1_blood_sugar_type = 'fasting'
                 AND latest_blood_sugar_1_blood_sugar_value >= 200)
             OR (latest_blood_sugar_1_blood_sugar_type = 'hba1c'
                 AND latest_blood_sugar_1_blood_sugar_value >= 9.0)) THEN 1
         ELSE 0
        END) as risk_level

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
