module Reports
  class FacilityDailyFollowUpAndRegistration < Reports::View
    self.table_name = "reporting_facility_daily_follow_ups_and_registrations"

    def self.materialized?
      true
    end

    def self.for_region(region_or_source)
      region = region_or_source.region
      where(region_id_field(region) => region.id)
    end

    def self.region_id_field(region)
      "#{region.region_type}_region_id"
    end

    def period
      visit_date
    end
  end
end
