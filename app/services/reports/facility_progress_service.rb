module Reports
  class FacilityProgressService
    include Memery

    MONTHS = -5
    CONTROL_MONTHS = -12
    DAYS_AGO = 29
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
      RefreshReportingViews.last_updated_at_facility_daily_follow_ups_and_registrations
    end

    def daily_registrations(date)
      daily_total_registrations[date]
    end

    def daily_follow_ups(date)
      daily_total_follow_ups[date]
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

    memoize def daily_total_follow_ups
      records = Reports::FacilityDailyFollowUpAndRegistration.for_region(region).where("visit_date >= ?", DAYS_AGO.days.ago.to_date)
      records.each_with_object({}) do |record, hsh|
        hsh[record.period] = if region.diabetes_management_enabled?
          record[:daily_follow_ups_htn_or_dm]
        else
          record[:daily_follow_ups_htn_only] + record[:daily_follow_ups_htn_and_dm]
        end
      end
    end

    memoize def daily_total_registrations
      records = Reports::FacilityDailyFollowUpAndRegistration.for_region(region).where("visit_date >= ?", DAYS_AGO.days.ago.to_date)
      records.each_with_object({}) do |record, hsh|
        hsh[record.period] = if diabetes_enabled
          record[:daily_registrations_htn_or_dm]
        else
          record[:daily_registrations_htn_only] + record[:daily_registrations_htn_and_dm]
        end
      end
    end

    def diagnosis_headers
      {
        hypertension: I18n.t("progress_tab.diagnoses.hypertension_only"),
        diabetes: I18n.t("progress_tab.diagnoses.diabetes_only"),
        hypertension_and_diabetes: I18n.t("progress_tab.diagnoses.hypertension_and_diabetes")
      }
    end

    memoize def daily_registrations_breakdown
      records = Reports::FacilityDailyFollowUpAndRegistration.for_region(region).where("visit_date >= ?", DAYS_AGO.days.ago.to_date)
      records.each_with_object({}) do |record, hsh|
        hsh[record.period] = {
          hypertension: {
            all: record[:daily_registrations_htn_only],
            male: record[:daily_registrations_htn_only_male],
            female: record[:daily_registrations_htn_only_female],
            transgender: record[:daily_registrations_htn_only_transgender]
          },
          diabetes: {
            all: record[:daily_registrations_dm_only],
            male: record[:daily_registrations_dm_only_male],
            female: record[:daily_registrations_dm_only_female],
            transgender: record[:daily_registrations_dm_only_transgender]
          },
          hypertension_and_diabetes: {
            all: record[:daily_registrations_htn_and_dm_all],
            male: record[:daily_registrations_htn_and_dm_male],
            female: record[:daily_registrations_htn_and_dm_female],
            transgender: record[:daily_registrations_htn_and_dm_transgender]
          }
        }
      end
    end

    memoize def daily_follow_ups_breakdown
      records = Reports::FacilityDailyFollowUpAndRegistration.for_region(region).where("visit_date >= ?", DAYS_AGO.days.ago.to_date)
      records.each_with_object({}) do |record, hsh|
        hsh[record.period] = {
          hypertension: {
            all: record[:daily_follow_ups_htn_only],
            male: record[:daily_follow_ups_htn_only_male],
            female: record[:daily_follow_ups_htn_only_female],
            transgender: record[:daily_follow_ups_htn_only_transgender]
          },
          diabetes: {
            all: record[:daily_follow_ups_dm_only],
            male: record[:daily_follow_ups_dm_only_male],
            female: record[:daily_follow_ups_dm_only_female],
            transgender: record[:daily_follow_ups_dm_only_transgender]
          },
          hypertension_and_diabetes: {
            all: record[:daily_follow_ups_htn_and_dm_all],
            male: record[:daily_follow_ups_htn_and_dm_male],
            female: record[:daily_follow_ups_htn_and_dm_female],
            transgender: record[:daily_follow_ups_htn_and_dm_transgender]
          }
        }
      end
    end

    def create_dimension(*args)
      Reports::FacilityProgressDimension.new(*args)
    end
  end
end
