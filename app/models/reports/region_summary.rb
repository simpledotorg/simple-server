module Reports
  class RegionSummary
    def self.call(regions, range:)
      new(regions, range: range).call
    end

    attr_reader :regions
    attr_reader :region_type, :id_field, :slug_field
    attr_reader :range

    def initialize(regions, range:)
      @range = range
      @regions = regions.map(&:region)
      @region_type = regions.first.region_type
      @id_field = "#{region_type}_region_id"
      @slug_field = region_type == "facility" ? "#{region_type}_region_slug" : "#{region_type}_slug"
    end

    def call
      query = for_regions
      query = query.where(month_date: range) if range
      result = query.group(:month_date, slug_field)
        .select("month_date, #{slug_field}, sum(adjusted_controlled_under_care) as adjusted_controlled_under_care")
      result.each_with_object({}) { |facility_state, hsh|
        slug = facility_state.send(slug_field)
        hsh[slug] ||= {}
        hsh[facility_state.send(slug_field)][facility_state.period] = facility_state.adjusted_controlled_under_care
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