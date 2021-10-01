module Reports
  class FacilityState < Reports::View
    self.table_name = "reporting_facility_states"

    belongs_to :facility

    def self.materialized?
      true
    end

    def self.for_region(region_or_source)
      region = region_or_source.region
      where("#{region.region_type}_region_id" => region.id)
    end

    def self.group_by_region_field(region)
      region_field = "#{region.region_type}_region_id"
      group(region_field)
    end

    def self.for_regions(regions)
      regions = Array(regions)
      regions_by_type = regions.group_by { |r| r.region_type }
      queries = regions_by_type.each_with_object({}) do |(region_type, regions), queries|
        field = "#{region_type}_region_id"
        queries[field] = regions.map(&:id)
      end
      pp queries
      where(queries)
    end

    def period
      Period.month(month_date)
    end
  end
end
