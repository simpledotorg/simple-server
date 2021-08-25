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

    def period
      Period.month(month_date)
    end
  end
end
