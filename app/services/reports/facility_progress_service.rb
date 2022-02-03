module Reports
  class FacilityProgressService
    attr_reader :facility
    attr_reader :range

    def initialize(facility, period)
      @facility = facility
      @period = period
      @range = Range.new(@period.advance(months: -5), @period)
    end

    def dimensions(indicator)
      # handle the special case of any diagnosis and all genders first
      dimensions = [Reports::FacilityProgressDimension.new(indicator, diagnosis: :all, gender: :all)]
      combinations = [indicator].product([:diabetes, :hypertension]).product([:all, :male, :female, :transgender])
      combinations.each_with_object([]) do |c|
        indicator, diagnosis = *c.first
        gender = c.last
        dimensions << Reports::FacilityProgressDimension.new(indicator, diagnosis: diagnosis, gender: gender)
      end
      dimensions
    end

    def total_counts
      @total_counts ||= Reports::FacilityStateGroup.totals(facility)
    end

    def monthly_counts
      @monthly_counts ||= Reports::FacilityStateGroup.where(facility_region_id: facility.region.id, month_date: @range).to_a
    end
  end
end
