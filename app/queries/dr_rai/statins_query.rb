module DrRai
  class StatinsQuery
    attr_reader :db_results

    include BustCache
    include IndicatorFunction

    CACHE_VERSION = 2

    def initialize(region, from: nil, to: nil)
      @region = region
    end

    def call
      Rails.cache.fetch(cache_key, expires_in: 1.day, force: bust_cache?) do
        _call
      end
    end

    def transform!
      result = {}
      db_results.rows.each do |db_row|
        # Legend
        # 0. month_date
        # 1. aggregate_root
        # 2. eligible_statins_patients
        # 3. patients_prescribed_statins
        # 4. percentage_statin_patients

        the_period = Period.quarter(db_row[0])
        facility_name = db_row[1].strip
        eligible_statins_patients = db_row[2].to_i
        patients_prescribed_statins = db_row[3].to_i
        # percentage_statin_patients = db_row[4]
        # Leaving this out because summation doesn't work for the percentage

        internal_data = {
          eligible_statins_patients: eligible_statins_patients,
          patients_prescribed_statins: patients_prescribed_statins
          # percentage_statin_patients: percentage_statin_patients
        }

        if result.has_key? facility_name
          if result[facility_name].has_key? the_period
            result[facility_name][the_period].merge!(internal_data) { |_, old, new| old + new }
          else
            result[facility_name][the_period] = internal_data
          end
        else
          result[facility_name] = {
            the_period => internal_data
          }
        end
      end

      result
    end

    private

    def _call
      @db_results = ApplicationRecord.connection.exec_query(query_string)
      transform!
    end

    def cache_key
      [
        self.class.name,
        @region.slug,
        time_window.to_s + "months",
        CACHE_VERSION
      ].join("/")
    end

    def time_window
      if @from.nil? || @to.nil?
        return 12
      end

      result = (@to.year * 12 + @to.month) - (@from.year * 12 + @from.month)

      # Cap this to 18 months for performant query
      [result, 18].min
    end

    def facilities
      [@region.slug].map do |slug|
        ActiveRecord::Base.connection.quote(slug)
      end.join(" ")
    end

    def supported_country_org
      if Organization.count == 1
        return Organization.first.slug
      end

      case CountryConfig.current[:name]
      when "Ethiopia"
        "ethiopian-hypertension-control-initiative"
      when "Bangladesh"
        "nhf"
      when "Sri Lanka"
        "sri-lanka-organization"
      else
        ""
      end
    end

    def query_string
      <<~SQL
        with latest_visits as (
          select
            patient_id,
            month_date,
            visited_at
          from
            reporting_patient_visits
          where
            month_date > now() - '#{time_window} months'::interval
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
          where
            facilities.slug in (#{facilities})
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
            and rps.assigned_organization_slug = '#{supported_country_org}'
            and month_date > now() - '#{time_window} months'::interval
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
            and rps.assigned_organization_slug = '#{supported_country_org}'
            and month_date > now() - '#{time_window} months'::interval
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
        select
          month_date,
          assigned_facility_slug as aggregate_root,
          diabetes_patient_under_care_above_39 as eligible_statins_patients,
          statin_patients as patients_prescribed_statins,
          (statin_patients * 100.00) / nullif(diabetes_patient_under_care_above_39, 0) as percentage_statin_patients
        from
          statin_report
        union all 
        select
          month_date,
          assigned_organization_slug as aggregate_root,
          diabetes_patient_under_care_above_39 as eligible_statins_patients,
          statin_patients as patients_prescribed_statins,
          (statin_patients * 100.00) / nullif(diabetes_patient_under_care_above_39, 0) as percentage_statin_patients
        from
          statin_report__org_wide
      SQL
    end
  end
end
