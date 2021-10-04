module Reports
  class FacilityState < Reports::View
    self.table_name = "reporting_facility_states"

    belongs_to :facility

    def self.materialized?
      true
    end

    def self.regions_summary(regions, range:)
      Summary.for(regions, range: range)
    end

    class Summary < SimpleDelegator
      def self.for(regions, range:)
        regions = regions.map(&:region)
        region_type = regions.first.region_type
        region_field = "#{region_type}_region_id"
        result = new(FacilityState).for_regions(regions).where(month_date: range).summary(region_type)

        result.each_with_object({}) { |facility_state, hsh|
          hsh[facility_state.send(region_field)] = { Period.month(facility_state.month_date) => facility_state.adjusted_controlled_under_care }
        }
      end
    end

    def self.region_field(region_type)
      "#{region_type}_region_id"
    end

    def self.summary(region_type)
      group(:month_date, region_field(region_type))
        .select("month_date, #{region_field(region_type)}, sum(adjusted_controlled_under_care) as adjusted_controlled_under_care")
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
      where(queries)
    end

    def period
      Period.month(month_date)
    end
  end
end
