module Reports
  class FacilityProgressService
    include Memery
    attr_reader :facility
    attr_reader :range

    def initialize(facility, period)
      @facility = facility
      @period = period
      @range = Range.new(@period.advance(months: -5), @period)
      @diabetes_enabled = facility.enable_diabetes_management
    end

    def daily_registrations(date)
      daily_registrations_grouped_by_day[date.to_date] || 0
    end

    def daily_follow_ups(date)
      daily_follow_ups_grouped_by_day[date.yday] || 0
    end

    def total_counts
      @total_counts ||= Reports::FacilityStateDimension.totals(facility)
    end

    def monthly_counts
      @monthly_counts ||= repository.facility_progress[facility.region.slug]
    end

    def repository
      @repository ||= Reports::Repository.new(facility, periods: @range)
    end

    # Returns all possible combinations of FacilityProgressDimensions for displaying
    # the different slices of progress data.
    def dimension_combinations_for(indicator)
      dimensions = [create_dimension(indicator, diagnosis: :all, gender: :all)] # special case first
      combinations = [indicator].product([:diabetes, :hypertension]).product([:all, :male, :female, :transgender])
      combinations.each do |c|
        indicator, diagnosis = *c.first
        gender = c.last
        dimensions << create_dimension(indicator, diagnosis: diagnosis, gender: gender)
      end
      dimensions
    end

    private

    attr_reader :diabetes_enabled

    memoize def daily_registrations_grouped_by_day
      diagnosis = diabetes_enabled ? :all : :hypertension
      RegisteredPatientsQuery.new.count_daily(facility, diagnosis: diagnosis, last: 30)
    end

    memoize def daily_follow_ups_grouped_by_day
      scope = Reports::DailyFollowUp.with_hypertension
      scope = scope.or(Reports::DailyFollowUp.with_diabetes) if diabetes_enabled
      scope.where(facility: facility).group(:day_of_year).count
    end

    def create_dimension(*args)
      Reports::FacilityProgressDimension.new(*args)
    end
  end
end
