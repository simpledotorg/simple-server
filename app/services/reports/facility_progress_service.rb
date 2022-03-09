module Reports
  class FacilityProgressService
    MONTHS = -5
    CONTROL_MONTHS = -12
    attr_reader :control_range
    attr_reader :facility
    attr_reader :range
    attr_reader :region

    def initialize(facility, period)
      @facility = facility
      @region = facility.region
      @period = period
      @range = Range.new(@period.advance(months: MONTHS), @period)
      @control_range = Range.new(@period.advance(months: CONTROL_MONTHS), @period.previous)
      @diabetes_enabled = facility.enable_diabetes_management
    end

    # we use the daily timestamp for the purposes of the last updated at,
    # even though monthly numbers may lag behind the daily.  The update time
    # probably matters the most health care workers as they see patients
    # throughout the day and expect to see those reflected in the daily counts.
    def last_updated_at
      RefreshReportingViews.last_updated_at_daily_follow_ups
    end

    def daily_registrations(date)
      daily_registrations_grouped_by_day[date.to_date] || 0
    end

    def daily_follow_ups(date)
      daily_follow_ups_grouped_by_day[date.to_date] || 0
    end

    def daily_statistics
      {
        daily: {
          grouped_by_date: {
            follow_ups: daily_follow_ups_grouped_by_day,
            registrations: daily_registrations_grouped_by_day
          }
        },
        metadata: {
          is_diabetes_enabled: @diabetes_enabled,
          last_updated_at: I18n.l(Time.current),
          formatted_next_date: (Time.current + 1.day).to_s(:mon_year),
          today_string: I18n.t(:today_str)
        }
      }
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

    attr_reader :diabetes_enabled

    def daily_registrations_grouped_by_day
      diagnosis = diabetes_enabled ? :all : :hypertension
      RegisteredPatientsQuery.new.count_daily(facility, diagnosis: diagnosis, last: 30)
    end

    def daily_follow_ups_grouped_by_day
      scope = Reports::DailyFollowUp.with_hypertension
      scope = scope.or(Reports::DailyFollowUp.with_diabetes) if diabetes_enabled
      scope.where(facility: facility).group_by_day(:visited_at, last: 30).count
    end

    def create_dimension(*args)
      Reports::FacilityProgressDimension.new(*args)
    end
  end
end
