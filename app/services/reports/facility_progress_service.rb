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
    attr_reader :diabetes_enabled

    def initialize(facility, period, current_user: nil)
      @facility = facility
      @region = facility.region
      @period = period
      @range = Range.new(@period.advance(months: MONTHS), @period)
      @control_range = Range.new(@period.advance(months: CONTROL_MONTHS), @period.previous)
      @diabetes_enabled = facility.enable_diabetes_management
      @current_user = current_user
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
      @yearly_facility_data = FacilityYearlyFollowUpsAndRegistrationsQuery.new(facility, @current_user).call
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
      repository.cumulative_registrations[@facility.region.slug][@period] +
        repository.cumulative_diabetes_registrations[@facility.region.slug][@period] -
        repository.cumulative_hypertension_and_diabetes_registrations[@facility.region.slug][@period]
    end

    def total_follow_ups
      total_counts[:monthly_follow_ups_htn_or_dm]
    end

    memoize def total_overdue_calls
      CallResult.where(facility_id: @facility.id).count
    end

    def total_counts
      @total_counts ||= Reports::FacilityMonthlyFollowUpAndRegistration.totals(facility)
    end

    memoize def repository
      Reports::Repository.new(facility, periods: @range)
    end

    def hypertension_reports_data
      {
        monthly_follow_ups: repository.hypertension_follow_ups[@region.slug],
        total_registrations: repository.cumulative_registrations[@region.slug],
        assigned_patients: repository.cumulative_assigned_patients[@region.slug][@period],
        missed_visits_rates: repository.missed_visits_rate[@region.slug],
        missed_visits: repository.missed_visits[@region.slug],
        uncontrolled_rates: repository.uncontrolled_rates[@region.slug],
        uncontrolled: repository.uncontrolled[@region.slug],
        controlled_rates: repository.controlled_rates[@region.slug],
        controlled: repository.controlled[@region.slug],
        adjusted_patients: repository.adjusted_patients[@region.slug],
        period_info: repository.period_info(@region),
        region: @region,
        current_user: @current_user
      }
    end

    memoize def daily_total_follow_ups
      total_follow_ups_per_period(period_type: "daily", facility_data: @daily_facility_data)
    end

    memoize def daily_total_registrations
      total_registrations_per_period(period_type: "daily", facility_data: @daily_facility_data)
    end

    memoize def monthly_total_follow_ups
      total_follow_ups_per_period(period_type: "monthly", facility_data: @monthly_facility_data)
    end

    memoize def monthly_total_registrations
      total_registrations_per_period(period_type: "monthly", facility_data: @monthly_facility_data)
    end

    memoize def yearly_total_follow_ups
      total_follow_ups_per_period(period_type: "yearly", facility_data: @yearly_facility_data)
    end

    memoize def yearly_total_registrations
      total_registrations_per_period(period_type: "yearly", facility_data: @yearly_facility_data)
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

    memoize def yearly_registrations_breakdown
      registrations_breakdown(period_type: "yearly", facility_data: @yearly_facility_data)
    end

    memoize def yearly_follow_ups_breakdown
      follow_ups_breakdown(period_type: "yearly", facility_data: @yearly_facility_data)
    end

    private

    memoize def total_registrations_per_period(period_type:, facility_data:)
      facility_data.each_with_object({}) do |record, hsh|
        period = period_type == "yearly" ? record["year"] : record.period
        hsh[period] = if diabetes_enabled
          record["#{period_type}_registrations_htn_or_dm"]
        else
          record["#{period_type}_registrations_htn_only"] + record["#{period_type}_registrations_htn_and_dm"]
        end
      end
    end

    memoize def total_follow_ups_per_period(period_type:, facility_data:)
      facility_data.each_with_object({}) do |record, hsh|
        period = period_type == "yearly" ? record["year"] : record.period
        hsh[period] = if diabetes_enabled
          record["#{period_type}_follow_ups_htn_or_dm"]
        else
          record["#{period_type}_follow_ups_htn_only"] + record["#{period_type}_follow_ups_htn_and_dm"]
        end
      end
    end

    memoize def registrations_breakdown(period_type:, facility_data:)
      facility_data.each_with_object({}) do |record, hsh|
        period = period_type == "yearly" ? record["year"] : record.period
        hsh[period] = {
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
        period = period_type == "yearly" ? record["year"] : record.period
        hsh[period] = {
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
  end
end
