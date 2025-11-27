module DrRai
  class BpFudgingQueryFactory < QueryFactory
    INSERTER_SQL = "insert into #{DrRai::Data::BpFudging.table_name} (state, district, slug, quarter, numerator, denominator, ratio)".freeze

    CONFLICT_HANDLER_SQL = <<~SQL
      on conflict (state, district, slug, quarter) do
        update set
          numerator = excluded.numerator,
          denominator = excluded.denominator,
          ratio = excluded.ratio,
          updated_at = now(); -- ...for good bookkeeping
    SQL

    def inserter
      base_query(INSERTER_SQL, "") { |enhancement| enhancement }
    end

    def updater
      base_query(INSERTER_SQL, CONFLICT_HANDLER_SQL) { |enhancement| enhancement }
    end

    private

    # This query is a modified version of what we use in Metabase; linked in Quick Links as well.
    # The modifications are thus
    # 1. Wide to Tall query on Quarter
    # 2. Added facility name to the mix, as "slug"
    # 3. Remove the filters on state and org
    def base_query inserter, conflict_handler
      <<~SQL
        #{yield inserter}
        (
          select
            reporting_facilities.state_name as "state",
            reporting_facilities.district_name "district",
            reporting_facilities.facility_name as "slug",
            to_char(bp.created_at, '"Q"q-yyyy') as "quarter",
            count(*) filter (where bp.systolic between 130 and 139) as "numerator",
            count(*) filter (where bp.systolic between 140 and 149) as "denominator",
            count(*) filter (where bp.systolic between 130 and 139) * 1.0 /
            nullif(count(*) filter (where bp.systolic between 140 and 149), 0) as "ratio"
          from blood_pressures bp
          join reporting_facilities on bp.facility_id = reporting_facilities.facility_id
          where 1 = 1
            and bp.created_at >= date_trunc('quarter', current_date - interval '12 months')
          group by
            1, 2, 3, 4
        )
        #{yield conflict_handler};
      SQL
    end
  end
end
