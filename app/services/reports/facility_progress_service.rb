module Reports
  class FacilityProgressService
    include Memery

    MONTHS = -5
    CONTROL_MONTHS = -12
    DAYS_AGO = 29
    DIAGNOSES_FOR_V1 = [:hypertension_and_diabetes, :diabetes, :hypertension]
    DIAGNOSES = [:diabetes, :hypertension]
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
      @daily_facility_data =
        Reports::FacilityDailyFollowUpAndRegistration
          .for_region(region)
          .where("visit_date >= ?", DAYS_AGO.days.ago.to_date)
          .load
      @monthly_facility_data =
        Reports::FacilityMonthlyFollowUpAndRegistration
          .for_region(region)
          .where("month_date > ?", 6.months.ago.beginning_of_month.to_date)
          .load
    end

    # we use the daily timestamp for the purposes of the last updated at,
    # even though monthly numbers may lag behind the daily.  The update time
    # probably matters the most health care workers as they see patients
    # throughout the day and expect to see those reflected in the daily counts.
    def last_updated_at
      RefreshReportingViews.last_updated_at_facility_daily_follow_ups_and_registrations
    end

    def daily_registrations(date)
      daily_total_registrations[date]
    end

    def daily_follow_ups(date)
      daily_total_follow_ups[date]
    end

    def total_registrations
      total_counts[:monthly_registrations_htn_or_dm]
    end

    def total_follow_ups
      total_counts[:monthly_follow_ups_htn_or_dm]
    end

    memoize def total_overdue_calls
      Reports::FacilityState.where(facility: facility).pluck(:monthly_overdue_calls).compact.sum
    end

    def daily_statistics
      {
        daily: {
          grouped_by_date: {
            follow_ups: daily_total_follow_ups,
            registrations: daily_total_registrations
          }
        },
        metadata: {
          is_diabetes_enabled: @diabetes_enabled,
          last_updated_at: last_updated_at,
          formatted_next_date: (Time.current + 1.day).to_s(:mon_year),
          today_string: I18n.t(:today_str)
        }
      }
    end

    def total_counts
      @total_counts ||= Reports::FacilityMonthlyFollowUpAndRegistration.totals(facility)
    end

    def monthly_counts
      @monthly_counts ||= repository.monthly_follow_ups_and_registrations[facility.region.slug]
    end

    def repository
      @repository ||= Reports::Repository.new(facility, periods: @range)
    end

    def control_rates_repository
      @control_rates_repository ||= Reports::Repository.new(facility, periods: control_range)
    end

    # Returns all possible combinations of FacilityProgressDimensions for displaying
    # the different slices of progress data.
    def dimension_combinations_for(indicator, diagnoses: DIAGNOSES)
      dimensions = [create_dimension(indicator, diagnosis: :all, gender: :all)] # special case first
      combinations = [indicator].product(diagnoses).product([:all, :male, :female, :transgender])
      combinations.each do |c|
        indicator, diagnosis = *c.first
        gender = c.last
        dimensions << create_dimension(indicator, diagnosis: diagnosis, gender: gender)
      end
      dimensions
    end

    def dimension_combinations_for_v1(indicator)
      dimension_combinations_for(indicator, diagnoses: DIAGNOSES_FOR_V1)
    end

    attr_reader :diabetes_enabled

    memoize def daily_total_follow_ups
      @daily_facility_data.each_with_object({}) do |record, hsh|
        hsh[record.period] = if region.diabetes_management_enabled?
          record[:daily_follow_ups_htn_or_dm]
        else
          record[:daily_follow_ups_htn_only] + record[:daily_follow_ups_htn_and_dm]
        end
      end
    end

    memoize def daily_total_registrations
      @daily_facility_data.each_with_object({}) do |record, hsh|
        hsh[record.period] = if diabetes_enabled
          record[:daily_registrations_htn_or_dm]
        else
          record[:daily_registrations_htn_only] + record[:daily_registrations_htn_and_dm]
        end
      end
    end

    memoize def monthly_total_follow_ups
      @monthly_facility_data.each_with_object({}) do |record, hsh|
        hsh[record.period] = if region.diabetes_management_enabled?
          record[:monthly_follow_ups_htn_or_dm]
        else
          record[:monthly_follow_ups_htn_only] + record[:monthly_follow_ups_htn_and_dm]
        end
      end
    end

    memoize def monthly_total_registrations
      @monthly_facility_data.each_with_object({}) do |record, hsh|
        hsh[record.period] = if diabetes_enabled
          record[:monthly_registrations_htn_or_dm]
        else
          record[:monthly_registrations_htn_only] + record[:monthly_registrations_htn_and_dm]
        end
      end
    end

    memoize def daily_registrations_breakdown
      registrations_breakdown(period_type: "daily", facility_data: @daily_facility_data)
    end

    memoize def daily_follow_ups_breakdown
      follow_ups_breakdown(period_type: "daily", facility_data: @daily_facility_data)
    end

    memoize def monthly_registrations_breakdown
      registrations_breakdown(period_type: "monthly", facility_data: @monthly_facility_data)
    end

    memoize def monthly_follow_ups_breakdown
      follow_ups_breakdown(period_type: "monthly", facility_data: @monthly_facility_data)
    end

    memoize def registrations_breakdown(period_type:, facility_data:)
      facility_data.each_with_object({}) do |record, hsh|
        hsh[record.period] = {
          hypertension: {
            all: record["#{period_type}_registrations_htn_only"],
            male: record["#{period_type}_registrations_htn_only_male"],
            female: record["#{period_type}_registrations_htn_only_female"],
            transgender: record["#{period_type}_registrations_htn_only_transgender"]
          },
          diabetes: {
            all: record["#{period_type}_registrations_dm_only"],
            male: record["#{period_type}_registrations_dm_only_male"],
            female: record["#{period_type}_registrations_dm_only_female"],
            transgender: record["#{period_type}_registrations_dm_only_transgender"]
          },
          hypertension_and_diabetes: {
            all: record["#{period_type}_registrations_htn_and_dm"],
            male: record["#{period_type}_registrations_htn_and_dm_male"],
            female: record["#{period_type}_registrations_htn_and_dm_female"],
            transgender: record["#{period_type}_registrations_htn_and_dm_transgender"]
          }
        }
      end
    end

    memoize def follow_ups_breakdown(period_type:, facility_data:)
      facility_data.each_with_object({}) do |record, hsh|
        hsh[record.period] = {
          hypertension: {
            all: record["#{period_type}_follow_ups_htn_only"],
            male: record["#{period_type}_follow_ups_htn_only_male"],
            female: record["#{period_type}_follow_ups_htn_only_female"],
            transgender: record["#{period_type}_follow_ups_htn_only_transgender"]
          },
          diabetes: {
            all: record["#{period_type}_follow_ups_dm_only"],
            male: record["#{period_type}_follow_ups_dm_only_male"],
            female: record["#{period_type}_follow_ups_dm_only_female"],
            transgender: record["#{period_type}_follow_ups_dm_only_transgender"]
          },
          hypertension_and_diabetes: {
            all: record["#{period_type}_follow_ups_htn_and_dm"],
            male: record["#{period_type}_follow_ups_htn_and_dm_male"],
            female: record["#{period_type}_follow_ups_htn_and_dm_female"],
            transgender: record["#{period_type}_follow_ups_htn_and_dm_transgender"]
          }
        }
      end
    end

    def create_dimension(*args)
      Reports::FacilityProgressDimension.new(*args)
    end
  end
end
