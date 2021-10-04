module Reports
  class RegionSummary
    def self.call(regions, range: nil)
      new(regions, range: range).call
    end

    attr_reader :id_field
    attr_reader :range
    attr_reader :region_type
    attr_reader :regions
    attr_reader :slug_field
    
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
    ].freeze

    SUMS = FIELDS.map { |field| Arel.sql("SUM(#{field}::int) as #{field}") }

    def initialize(regions, range: nil)
      @range = range
      @regions = Array(regions).map(&:region)
      @region_type = @regions.first.region_type
      @id_field = "#{region_type}_region_id"
      @slug_field = region_type == "facility" ? "#{region_type}_region_slug" : "#{region_type}_slug"
    end

    def call
      query = for_regions
      query = query.where(month_date: range) if range
      result = query.group(:month_date, slug_field)
        .select("month_date", slug_field, SUMS)
      result.each_with_object({}) { |facility_state, hsh|
        slug = facility_state.send(slug_field)
        hsh[slug] ||= {}
        hsh[facility_state.send(slug_field)][facility_state.period] = facility_state.attributes.except("month_date")
      }
    end

    def for_regions
      regions_by_type = regions.group_by { |r| r.region_type }
      queries = regions_by_type.each_with_object({}) do |(region_type, regions), queries|
        field = "#{region_type}_region_id"
        queries[field] = regions.map(&:id)
      end
      FacilityState.where(queries)
    end
  end
end