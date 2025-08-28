module DrRai
  class StatinsQueryFactory < QueryFactory
    INSERTER_SQL = "insert into #{DrRai::Data::Statin.table_name} (month_date, aggregate_root, eligible_patients, patients_prescribed_statins, percentage_statins, created_at, updated_at)".freeze

    CONFLICT_HANDLER_SQL = <<~SQL
      on conflict (month_date, aggregate_root) do
        update
          set
            eligible_patients = excluded.eligible_patients,
            patients_prescribed_statins = excluded.patients_prescribed_statins,
            percentage_statins = excluded.percentage_statins,
            updated_at = now(); -- ...for good bookkeeping
    SQL

    def inserter
      base_query(INSERTER_SQL, "") { |enhancement| enhancement }
    end

    def updater
      base_query(INSERTER_SQL, CONFLICT_HANDLER_SQL) { |enhancement| enhancement }
    end

    private

    def base_query inserter, conflict_handler
      <<~SQL
        with latest_visits as (
          select
            patient_id,
            month_date,
            visited_at
          from
            reporting_patient_visits
          where
            month_date > now() - '#{months_between} months'::interval
        ), statin_prescriptions as (
          select
            distinct on (patient_id, month_date) id as statin_prescription_id,
            pd.patient_id,
            name,
            device_created_at,
            cal.month_date,
            is_deleted,
            device_updated_at
          from
            prescription_drugs pd
          left join reporting_months cal on date_trunc('month', pd.device_created_at) <= cal.month_date
          left join latest_visits lv on lv.month_date = cal.month_date and lv.patient_id = pd.patient_id
          where
            name ilike '%statin%'
            and (
              is_deleted = false
              or (
                is_deleted = true
                and device_updated_at >= lv.visited_at
              )
            )
            and deleted_at is null
        ), the_facilities as (
          select
            slug
          from
            facilities
        ), rps_with_age_on_month_date__org_wide as (
          select
            case
            when
              rps.date_of_birth is not null then date_part('year', age(rps.month_date, rps.date_of_birth))
            else
              date_part(
                'year',
                age(
                  rps.month_date,
                  (
                    rps.age_updated_at at time zone 'utc' at time zone (
                      select
                      current_setting('timezone')
                    )
                  ) :: date
                )
              ) + rps.age
            end as age_on_month_date,
            rps.patient_id,
            rps.month_date,
            rps.months_since_visit,
            rps.appointment_recorded_at,
            rps.prior_stroke,
            rps.diabetes,
            rps.prior_heart_attack,
            rps.assigned_organization_slug
          from
            reporting_patient_states rps
          where
            1 = 1
            and rps.htn_care_state = 'under_care'
            and month_date > now() - '#{months_between} months'::interval
        ), rps_with_age_on_month_date as (
          select
            case
            when
              rps.date_of_birth is not null then date_part('year', age(rps.month_date, rps.date_of_birth))
            else
              date_part(
                'year',
                age(
                  rps.month_date,
                  (
                    rps.age_updated_at at time zone 'utc' at time zone (
                      select
                      current_setting('timezone')
                    )
                  ) :: date
                )
              ) + rps.age
            end as age_on_month_date,
            rps.patient_id,
            rps.month_date,
            rps.months_since_visit,
            rps.appointment_recorded_at,
            rps.prior_stroke,
            rps.diabetes,
            rps.prior_heart_attack,
            rps.assigned_facility_slug,
            rps.assigned_organization_slug
          from
            reporting_patient_states rps
            join the_facilities on rps.assigned_facility_slug = the_facilities.slug
          where
            1 = 1
            and rps.htn_care_state = 'under_care'
            and month_date > now() - '#{months_between} months'::interval
        ), diabetes_patient_under_care__org_wide as (
          select
            *
          from
            rps_with_age_on_month_date__org_wide rps
          where
            rps.prior_heart_attack = 'yes'
            or rps.prior_stroke = 'yes'
            or (
              rps.diabetes = 'yes'
              and rps.age_on_month_date >= 40
            )
        ), diabetes_patient_under_care as (
          select
            *
          from
            rps_with_age_on_month_date rps
          where
            rps.prior_heart_attack = 'yes'
            or rps.prior_stroke = 'yes'
            or (
              rps.diabetes = 'yes'
              and rps.age_on_month_date >= 40
            )
        ), statin_report as (
          select
            dpuc.month_date,
            assigned_facility_slug,
            count(dpuc.patient_id) as diabetes_patient_under_care_above_39,
            count(sp.patient_id) filter (
              where
              statin_prescription_id is not null
            ) as statin_patients
          from
            diabetes_patient_under_care dpuc
          left join statin_prescriptions sp on sp.patient_id = dpuc.patient_id and sp.month_date = dpuc.month_date
          group by
            1, 2
          order by
            1 desc
        ), statin_report__org_wide as (
          select
            dpuc.month_date,
            assigned_organization_slug,
            count(dpuc.patient_id) as diabetes_patient_under_care_above_39,
            count(sp.patient_id) filter (
              where
              statin_prescription_id is not null
            ) as statin_patients
          from
            diabetes_patient_under_care__org_wide dpuc
          left join statin_prescriptions sp on sp.patient_id = dpuc.patient_id and sp.month_date = dpuc.month_date
          group by
            1, 2
          order by
            1 desc
        )
        #{yield inserter}
        (
          select
            month_date,
            assigned_facility_slug as aggregate_root,
            diabetes_patient_under_care_above_39 as eligible_patients,
            statin_patients as patients_prescribed_statins,
            (statin_patients * 100.00) / nullif(diabetes_patient_under_care_above_39, 0) as percentage_statins,
            now() as created_at,
            now() as updated_at
          from
            statin_report
          union all 
          select
            month_date,
            assigned_organization_slug as aggregate_root,
            diabetes_patient_under_care_above_39 as eligible_patients,
            statin_patients as patients_prescribed_statins,
            (statin_patients * 100.00) / nullif(diabetes_patient_under_care_above_39, 0) as percentage_statins,
            now() as created_at,
            now() as updated_at
          from
            statin_report__org_wide
        )
        #{yield conflict_handler};
      SQL
    end
  end
end
