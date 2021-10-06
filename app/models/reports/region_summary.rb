module Reports
  class RegionSummary
    def self.call(regions, range: nil)
      new(regions, range: range).call
    end

    FIELDS = %i[
      adjusted_controlled_under_care
      adjusted_missed_visit_lost_to_follow_up
      adjusted_missed_visit_under_care
      adjusted_patients_under_care
      adjusted_uncontrolled_under_care
      adjusted_visited_no_bp_lost_to_follow_up
      adjusted_visited_no_bp_under_care
      cumulative_assigned_patients
      cumulative_registrations
      lost_to_follow_up
      monthly_registrations
    ].sort.freeze

    UNDER_CARE_WITH_LTFU = %i[
      adjusted_missed_visit
      adjusted_visited_no_bp
    ].freeze

    attr_reader :id_field
    attr_reader :range
    attr_reader :region_type
    attr_reader :regions
    attr_reader :slug_field

    def self.under_care_with_ltfu(field)
      Arel.sql(<<-SQL)
        COALESCE(SUM(#{field}_under_care::int + #{field}_lost_to_follow_up::int), 0) as #{field}_under_care_with_lost_to_follow_up
      SQL
    end

    SUMS = FIELDS.map { |field| Arel.sql("COALESCE(SUM(#{field}::int), 0) as #{field}") }
    CALCULATIONS = UNDER_CARE_WITH_LTFU.map { |field| under_care_with_ltfu(field) }

    def initialize(regions, range: nil)
      @range = range
      @regions = Array(regions).map(&:region)
      @region_type = @regions.first.region_type
      @id_field = "#{region_type}_region_id"
      @slug_field = region_type == "facility" ? "#{region_type}_region_slug" : "#{region_type}_slug"
      @results = @regions.each_with_object({}) { |region, hsh| hsh[region.slug] = Hash.new(0) }
    end

    def call
      query = for_regions
      query = query.where(month_date: range) if range
      facility_states = query.group(:month_date, slug_field).select("month_date", slug_field, SUMS, CALCULATIONS)
      facility_states.each { |facility_state|
        @results[facility_state.send(slug_field)][facility_state.period] = facility_state.attributes.except("month_date")
      }
      @results
    end

    def for_regions
      regions_by_type = regions.group_by { |r| r.region_type }
      queries = regions_by_type.each_with_object({}) do |(region_type, regions), queries|
        field = "#{region_type}_region_id"
        queries[field] = regions.map(&:id)
      end
      FacilityState.where(queries).where("cumulative_registrations IS NOT NULL OR cumulative_assigned_patients IS NOT NULL")
    end
  end
end
