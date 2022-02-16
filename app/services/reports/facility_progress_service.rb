module Reports
  class FacilityProgressService
    include Memery
    attr_reader :control_range
    attr_reader :facility
    attr_reader :range
    attr_reader :region

    def initialize(facility, period)
      @facility = facility
      @region = facility.region
      @period = period
      @range = Range.new(@period.advance(months: -5), @period)
      @control_range = Range.new(@period.advance(months: -12), @period.previous)
      @diabetes_enabled = facility.enable_diabetes_management
    end

    # we use the daily timestamp for the purposes of the last updated at,
    # even though monthly numbers may lag behind the daily.  The update time
    # probably matters the most health care workers as they see patients
    # throughout the day and expect to see those reflected in the daily counts.
    def last_updated_at
      RefreshReportingViews.last_updated_at_daily_follow_ups
    end

    def control_summary
      controlled = control_rates_repository.controlled[region.slug][control_range.last]
      registrations = control_rates_repository.cumulative_registrations[region.slug][control_range.last]
      return "#{controlled} of #{registrations} patients"

      numerator = number_with_delimiter(controlled_patients)
      denominator = number_with_delimiter(registrations)
      unit = "patient".pluralize(registrations)
      "#{numerator} of #{denominator} #{unit}"
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

    def control_rates_repository
      @control_rates_repository ||= Reports::Repository.new(facility, periods: control_range)
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
