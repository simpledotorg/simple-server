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

    def self.region_id_field(region)
      "#{region.region_type}_region_id"
    end

    def period
      @period ||= Period.month(month_date)
    end

    scope :with_patients, -> {
      where("cumulative_registrations > 0 OR cumulative_assigned_patients > 0 OR monthly_follow_ups > 0")
    }
  end
end
