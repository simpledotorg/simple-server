module Reports
  class FacilityProgressService
    attr_reader :facility
    attr_reader :range

    def initialize(facility, period)
      @facility = facility
      @period = period
      @range = Range.new(@period.advance(months: -5), @period)
    end

    # Returns all possible combinations of FacilityProgressDimensions for displaying 
    # the different slices of progress data.
    def dimension_combinations_for(indicator)
      dimensions = [create_dimension(indicator, diagnosis: :all, gender: :all)] # special case first
      combinations = [indicator].product([:diabetes, :hypertension]).product([:all, :male, :female, :transgender])
      combinations.each_with_object([]) do |c|
        indicator, diagnosis = *c.first
        gender = c.last
        dimensions << create_dimension(indicator, diagnosis: diagnosis, gender: gender)
      end
      dimensions
    end

    def create_dimension(*args)
      Reports::FacilityProgressDimension.new(*args)
    end

    def total_counts
      @total_counts ||= Reports::FacilityStateGroup.totals(facility)
    end

    def monthly_counts
      @monthly_counts ||= Reports::FacilityStateGroup.where(facility_region_id: facility.region.id, month_date: @range).to_a
    end
  end
end
