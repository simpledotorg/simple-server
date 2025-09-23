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
        with facility_titrations as (
          select
            reporting_patient_states.month_date,
            facility_name,
            count(*) as follow_up_count,
            count(*) filter (where titrated) as titrated_count,
            count(*) filter (where titrated)::float / count(*) * 100 as titration_rate
          from reporting_patient_states
          inner join reporting_facilities
          on reporting_facilities.facility_id = reporting_patient_states.bp_facility_id
          where 1 = 1
            and "public"."reporting_patient_states"."month_date" between date '#{from_date}' and date '#{to_date}'
            and reporting_patient_states.months_since_bp = 0
            and reporting_patient_states.last_bp_state = 'uncontrolled'
            and reporting_patient_states.months_since_registration > 0
          group by 1, 2
          order by 1, 2
        ),

        selected_facility_titrations as (
          select
            month_date,
            facility_name,
            follow_up_count,
            titrated_count,
            titration_rate
          from facility_titrations
          where facility_name in (
            select facility_name
            from reporting_facilities
          )
        ),

        averages as (
          select
            month_date,
            'average' as facility_name,
            sum(follow_up_count) as follow_up_count,
            sum(titrated_count) as titrated_count,
            (sum(titrated_count)::float / sum(follow_up_count)) * 100 as titration_rate
          from facility_titrations
          group by month_date
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
