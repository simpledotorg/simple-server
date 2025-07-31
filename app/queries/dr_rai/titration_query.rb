# Titration Indicator Function
module DrRai
  class TitrationQuery

    attr_reader :results, :db_results

    include IndicatorFunction

    def initialize(region, from: nil, to: nil)
      @region = region
    end

    def call
      @db_results = ApplicationRecord.connection.exec_query(query_string)
      transform!
    end

    def valid_structure? db_result
      false if db_result.nil?
      false unless db_result.columns.size == 6
      false unless %w[
        facility_name
        uncontrolled
        percent_titrated
        titrated
        not_titrated
        month_date
      ].all? { |column| db_result.columns.include?(column) }

      true
    end

    def transform!
      result = {}

      # Group by month_date as period
      # Group by facility_name
      db_results.rows.each do |db_row|
        # Legend
        # 0. facility_name
        # 1. uncontrolled
        # 2. titrated
        # 3. not_titrated
        # 4. percent_titrated
        # 5. month_date

        facility_name = db_row[0]
        uncontrolled = db_row[1]
        titrated = db_row[2]
        not_titrated = db_row[3]
        percent_titrated = db_row[4]
        the_period = Period.quarter(db_row[5])

        titration_data = {
          uncontrolled: uncontrolled,
          titrated: titrated,
          not_titrated: not_titrated,
          percent_titrated: percent_titrated,
        }

        if result.has_key? facility_name
          if result[facility_name].has_key?(the_period)
            result[facility_name][the_period][:uncontrolled] += uncontrolled
            result[facility_name][the_period][:titrated] += titrated
            result[facility_name][the_period][:not_titrated] += not_titrated
            result[facility_name][the_period][:percent_titrated] += percent_titrated
          else
            result[facility_name][the_period] = titration_data
          end
        else
          result[facility_name] = {
            the_period => titration_data
          }
        end
      end

      result
    end

    # Get the quarter period for some month date
    def period_for month_date
      raise "Dates must be a String" unless month_date.is_a? String

      Period.quarter month_date
    end

    private

    def begins_at
      @from unless @from.nil?

      1.year.ago.to_s(:db)
    end

    def ends_at
      @to unless @to.nil?

      Time.now.to_s(:db)
    end

    def facilities
      [@region.slug].map do |slug|
        ActiveRecord::Base.connection.quote(slug)
      end.join(' ')
    end

    def query_string
      <<~SQL
        with monthly_drugs as (SELECT p.id as patient_id,
          p.month_date,
          prescriptions.actual_name,
          actual_dosage,
          protocol_drug_category,
          medicine_purpose_hypertension
        FROM (
            SELECT *
            FROM patients p
            LEFT OUTER JOIN reporting_months cal
            ON to_char(p.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= cal.month_string
            WHERE p.deleted_at is null
        ) p
        LEFT JOIN LATERAL (
            SELECT DISTINCT ON (actual.name, actual.dosage)
              actual.name          as actual_name,
              actual.dosage        as actual_dosage,
              protocol_drugs.drug_category as protocol_drug_category,
              medicine_purposes.hypertension as medicine_purpose_hypertension
            FROM prescription_drugs actual
            LEFT OUTER JOIN protocol_drugs on (protocol_drugs.name = actual.name or protocol_drugs.name = 'Nifedipine SR' and actual.name = 'Nifedipine')
            LEFT OUTER JOIN medicine_purposes on medicine_purposes.name = actual.name
            WHERE patient_id = p.id
              AND to_char(device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= p.month_string
              AND actual.deleted_at is null
              AND (is_deleted = false OR (is_deleted = true AND to_char(actual.device_updated_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') > p.month_string))
            ORDER BY actual.name, actual.dosage, actual.device_created_at desc
            ) prescriptions ON true),

        patient_titration_summaries as
        (select
            current_month.patient_id,
            reporting_patient_states.last_bp_state,
            reporting_patient_states.assigned_facility_id,
            reporting_patient_states.assigned_facility_slug,
            reporting_patient_states.months_since_bp,
            reporting_patient_states.systolic,
            reporting_patient_states.diastolic,
            current_month.month_date,
            current_month.actual_name,
            current_month.protocol_drug_category,
            current_month.medicine_purpose_hypertension is TRUE as medicine_purpose_hypertension,
            current_month.actual_dosage as current_dosage,
            previous_month.actual_dosage as previous_dosage,
            current_month.actual_dosage IS DISTINCT FROM previous_month.actual_dosage as drug_titrated

        from monthly_drugs current_month
        join reporting_patient_states on reporting_patient_states.patient_id = current_month.patient_id and reporting_patient_states.month_date = current_month.month_date
        left outer join monthly_drugs previous_month on current_month.patient_id = previous_month.patient_id and current_month.actual_name = previous_month.actual_name and current_month.month_date = previous_month.month_date + '1 month'::interval
        where reporting_patient_states.month_date between timestamp '#{begins_at}' and timestamp '#{ends_at}'
        AND reporting_patient_states.assigned_facility_slug NOT LIKE '%non-rtsl%'
        ),

        monthly_patient_wise_titration as (
        select
            s.patient_id,
            s.month_date,
            s.last_bp_state,
            s.assigned_facility_id,
            s.months_since_bp,
            bool_or(drug_titrated) as any_drug_titrated,
            bool_or(drug_titrated) filter (where protocol_drug_category ilike '%hypertension%') as htn_protocol_drug_titrated,
            bool_or(drug_titrated) filter (where medicine_purpose_hypertension is true) as medicine_purpose_hypertension_titrated,
            rop.previous_appointment_schedule_date::DATE as scheduled_appointment_date,
            rop.visited_at_after_appointment::DATE as visited_on,
            rop.visited_at_after_appointment::DATE - rop.previous_appointment_schedule_date::DATE as days_overdue_on_visit,
            s.systolic,
            s.diastolic
        from patient_titration_summaries s
        join reporting_overdue_patients rop on rop.patient_id = s.patient_id and s.month_date = rop.month_date
        group by
            s.patient_id,
            s.month_date,
            s.last_bp_state,
            s.assigned_facility_id,
            s.months_since_bp,
            rop.previous_appointment_schedule_date,
            rop.visited_at_after_appointment,
            s.systolic,
            s.diastolic
        ),

        detailed AS (
          SELECT
            reporting_facilities.facility_name,
            COUNT(*) AS uncontrolled,
            SUM(CASE WHEN htn_protocol_drug_titrated THEN 1 ELSE 0 END) AS titrated,
            SUM(CASE WHEN htn_protocol_drug_titrated THEN 0 ELSE 1 END) AS not_titrated,
            (SUM(CASE WHEN htn_protocol_drug_titrated THEN 1 ELSE 0 END)::FLOAT /
            (SUM(CASE WHEN htn_protocol_drug_titrated THEN 1 ELSE 0 END) +
            SUM(CASE WHEN htn_protocol_drug_titrated THEN 0 ELSE 1 END)) * 100) AS percent_titrated,
            month_date
          FROM monthly_patient_wise_titration
            JOIN reporting_facilities ON reporting_facilities.facility_id = monthly_patient_wise_titration.assigned_facility_id
          WHERE
            months_since_bp = 0
            AND last_bp_state = 'uncontrolled'
            AND days_overdue_on_visit < 3
          GROUP BY
            month_date,
            reporting_facilities.facility_name
        ),

        selected_facility_titrations as (
        select
            detailed.facility_name,
            uncontrolled,
            titrated,
            not_titrated,
            percent_titrated,
            month_date
        from detailed
        join reporting_facilities on reporting_facilities.facility_name = detailed.facility_name
        where
            reporting_facilities.facility_region_slug in (#{facilities})
        ),

        averages AS (
          SELECT
            'Average' AS facility_name,
            ( SUM(titrated) + SUM(not_titrated) ) AS uncontrolled,
            SUM(titrated) AS titrated,
            SUM(not_titrated) AS not_titrated,
            ( ( SUM(titrated)::FLOAT / ( SUM(titrated) + SUM(not_titrated) ) ) * 100 ) AS percent_titrated,
            month_date
          FROM
            detailed
          GROUP BY
            month_date
        )

        SELECT * FROM selected_facility_titrations
        UNION ALL
        SELECT * FROM averages
        ORDER BY facility_name, month_date;
      SQL
    end
  end
end
