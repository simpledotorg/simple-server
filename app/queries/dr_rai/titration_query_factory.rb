module DrRai
  class TitrationQueryFactory < QueryFactory
    INSERTER_SQL = "insert into public.dr_rai_data_titrations (month_date, facility_name, follow_up_count, titrated_count, titration_rate)".freeze

    CONFLICT_HANDLER_SQL = <<~SQL
      on conflict (month_date, facility_name) do
        update
          set
            follow_up_count = excluded.follow_up_count,
            titrated_count = excluded.titrated_count,
            titration_rate = excluded.titration_rate,
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
        with protocol_rows_by_drug AS (
          SELECT m.drug_name, pr.drug_category
          FROM (
            SELECT DISTINCT name AS drug_name FROM protocol_drugs
            UNION
            SELECT 'Nifedipine'
          ) m
          JOIN protocol_drugs pr
            ON pr.name = m.drug_name
          OR (pr.name = 'Nifedipine SR' AND m.drug_name = 'Nifedipine')
        ),

        htn_drug_names AS (
          SELECT p.drug_name AS name
          FROM protocol_rows_by_drug p
          GROUP BY p.drug_name
          HAVING bool_or(p.drug_category ILIKE '%hypertension%')
            AND NOT EXISTS (
              SELECT 1 FROM medicine_purposes mp
              WHERE mp.name = p.drug_name
                AND mp.hypertension = false
            )
        ),

        cohort AS (
          SELECT
            rps.patient_id,
            rps.month_date,
            rps.assigned_facility_id
          FROM reporting_patient_states rps
          JOIN reporting_overdue_patients rop
            ON rop.patient_id = rps.patient_id
          AND rop.month_date = rps.month_date
          JOIN patients p
            ON p.id = rps.patient_id
          AND p.deleted_at IS NULL
          AND date_trunc('month', timezone(current_setting('TIMEZONE'), timezone('UTC', p.recorded_at))) <= rps.month_date
            WHERE rps.month_date >= '#{from_date}' and rps.month_date <= '#{to_date}'
            AND rop.month_date >= '#{from_date}' and rop.month_date <= '#{to_date}'
            AND rps.months_since_bp = 0
            AND rps.last_bp_state = 'uncontrolled'
            AND rop.visited_at_after_appointment::date - rop.previous_appointment_schedule_date::date < 3
        ),

        patient_months AS (
          SELECT patient_id, month_date FROM cohort
          UNION
          SELECT patient_id, (month_date - interval '1 month')::date FROM cohort
        ),

        drugs AS (
          SELECT
            pm.patient_id,
            pm.month_date,
            d.name,
            d.dosage
          FROM patient_months pm
          CROSS JOIN LATERAL (
            SELECT DISTINCT pd.name, pd.dosage
            FROM prescription_drugs pd
            WHERE pd.patient_id = pm.patient_id
              AND pd.deleted_at IS NULL
              AND pd.name IN (SELECT name FROM htn_drug_names)
              AND date_trunc('month', timezone(current_setting('TIMEZONE'), timezone('UTC', pd.device_created_at))) <= pm.month_date
              AND (
                pd.is_deleted = false
                OR date_trunc('month', timezone(current_setting('TIMEZONE'), timezone('UTC', pd.device_updated_at))) > pm.month_date
              )
          ) d
        ),

        titration AS (
          SELECT
            c.patient_id,
            c.month_date,
            c.assigned_facility_id,
            bool_or(cur.dosage IS DISTINCT FROM prev.dosage) AS htn_protocol_drug_titrated
          FROM cohort c
          LEFT JOIN drugs cur
            ON cur.patient_id = c.patient_id
          AND cur.month_date = c.month_date
          LEFT JOIN drugs prev
            ON prev.patient_id = c.patient_id
          AND prev.month_date = (c.month_date - interval '1 month')::date
          AND prev.name = cur.name
          GROUP BY 1, 2, 3
        ),

        detailed AS (
          SELECT
            rf.facility_name,
            COUNT(*) AS follow_up_count,
            COUNT(*) FILTER (WHERE t.htn_protocol_drug_titrated) AS titrated_count,
            COUNT(*) FILTER (WHERE NOT t.htn_protocol_drug_titrated) AS not_titrated,
            COUNT(*) FILTER (WHERE t.htn_protocol_drug_titrated)::float / COUNT(*) * 100 AS titration_rate,
            t.month_date
          FROM titration t
          JOIN reporting_facilities rf ON rf.facility_id = t.assigned_facility_id
          GROUP BY t.month_date, rf.facility_name
        ),

        selected_facility_titrations as (
          SELECT
            month_date,
            facility_name,
            follow_up_count,
            titrated_count,
            titration_rate
          FROM detailed
          WHERE facility_name in (SELECT facility_name FROM reporting_facilities)
        ),

        averages as (
          SELECT
            month_date,
            'average' AS facility_name,
            SUM(titrated_count) + SUM(not_titrated) AS follow_up_count,
            SUM(titrated_count) AS titrated_count,
            SUM(titrated_count)::float / (SUM(titrated_count) + SUM(not_titrated)) * 100 AS titration_rate
          FROM detailed
          GROUP BY month_date
        )

        #{yield inserter}
        (
          select * from selected_facility_titrations
          union all
          select * from averages
        )
        #{yield conflict_handler};
      SQL
    end
  end
end
