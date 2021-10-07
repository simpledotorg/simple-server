module Reports
  class FacilityState < Reports::View
    self.table_name = "reporting_facility_states"

    belongs_to :facility

    def self.materialized?
      true
    end

    def self.for_region(region_or_source)
      region = region_or_source.region
      where(region_id_field(region) => region.id)
    end

    def self.group_by_region_field(region)
      group(region_id_field(region))
    end

    def self.region_id_field(region)
      "#{region.region_type}_region_id"
    end

    def self.for_regions(regions)
      regions = Array(regions)
      regions_by_type = regions.group_by { |r| r.region_type }
      queries = regions_by_type.each_with_object({}) do |(region_type, regions), queries|
        id_field = region_id_field(regions.first)
        queries[id_field] = regions.map(&:id)
      end
      where(queries)
    end

    def period
      Period.month(month_date)
    end
  end
end
