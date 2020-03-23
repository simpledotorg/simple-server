class Api::Current::Analytics::UserAnalyticsController < Api::Current::AnalyticsController
  include HashUtilities
  include ApplicationHelper
  include DashboardHelper
  include MonthHelper
  include DayHelper
  include PeriodHelper

  layout false

  def show
    @days_ago = 30
    @daily_period_list = period_list(:day, @days_ago).sort.reverse.map { |date| doy_to_date_obj(*date) }
    @months_ago = 6
    @monthly_period_list = period_list(:month, @months_ago).sort.reverse.map { |date| moy_to_date_obj(*date) }

    @statistics = {
      daily: prepare_daily_stats(@days_ago),
      monthly: prepare_monthly_stats(@months_ago),
      trophies: prepare_trophies,
      metadata: {
        is_diabetes_enabled: false && current_facility.diabetes_enabled?,
        last_updated_at: Time.current,
        formatted_next_date: display_date(Time.current + 1.day),
        formatted_today_string: t(:today_str)
      }
    }

    respond_to_html_or_json(@statistics)
  end

  private

  def respond_to_html_or_json(stats)
    respond_to do |format|
      format.html { render :show }
      format.json { render json: stats }
    end
  end

  def prepare_monthly_stats(months_ago)
    [
      registrations_for_last_n_months(months_ago),
      follow_ups_for_last_n_months(months_ago),
      htn_control_for_last_n_months(months_ago)
    ].inject(&:deep_merge)
  end

  def prepare_daily_stats(days_ago)
    [
      registrations_for_last_n_days(days_ago),
      follow_ups_for_last_n_days(days_ago)
    ].inject(&:deep_merge)
  end

  #
  # After exhausting the initial TROPHY_MILESTONES, subsequent milestones must follow the following pattern:
  #
  # 10
  # 25
  # 50
  # 100
  # 250
  # 500
  # 1_000
  # 2_000
  # 3_000
  # 4_000
  # 5_000
  # 10_000
  # 20_000
  # 30_000
  # etc.
  #
  TROPHY_MILESTONES =
    [10, 25, 50, 100, 250, 500, 1_000, 2_000, 3_000, 4_000, 5_000]
  POST_SEED_MILESTONE_INCR = 10_000

  def prepare_trophies
    total_follow_ups = MyFacilities::FollowUpsQuery.total_follow_ups(current_facility).count

    all_trophies =
      total_follow_ups > TROPHY_MILESTONES.last ?
        [*TROPHY_MILESTONES,
         *(POST_SEED_MILESTONE_INCR..(total_follow_ups + POST_SEED_MILESTONE_INCR)).step(POST_SEED_MILESTONE_INCR)] :
        TROPHY_MILESTONES

    unlocked_trophies_until = all_trophies.index { |v| total_follow_ups < v }

    { locked_trophy_value: all_trophies[unlocked_trophies_until],
      unlocked_trophy_values: all_trophies[0, unlocked_trophies_until] }
  end

  def follow_ups_for_last_n_days(n)
    follow_ups =
      MyFacilities::FollowUpsQuery
        .new(facilities: current_facility, period: :day, last_n: n)
        .follow_ups
        .group(:year, :day)
        .count
        .map { |group, fps| [doy_to_date_obj(*group), follow_ups: fps] } # TODO: fix this doy_to_date_obj helper
        .to_h

    group_by_date(data_for_unavailable_dates(:follow_ups, @daily_period_list).merge(follow_ups))
  end

  def registrations_for_last_n_days(n)
    registrations =
      MyFacilities::RegistrationsQuery
        .new(facilities: current_facility, period: :day, last_n: n)
        .registrations
        .group_by { |reg| [reg.year, reg.day] }
        .map { |group, reg| [doy_to_date_obj(*group), registrations: reg.first.registration_count] }
        .to_h

    group_by_date(data_for_unavailable_dates(:registrations, @daily_period_list).merge(registrations))
  end

  def registrations_for_last_n_months(n)
    registrations =
      current_facility
        .registered_patients
        .group(:gender)
        .group_by_period(:month, :recorded_at, range: n.months.ago..Time.now)
        .distinct('patients.id')
        .count
        .map { |(gender, date), count| [[gender, date.year, date.month], count] }
        .to_h

    group_by_gender(registrations, :registrations, @monthly_period_list)
  end

  def follow_ups_for_last_n_months(n)
    follow_ups =
      MyFacilities::FollowUpsQuery
        .new(facilities: current_facility, period: :month, last_n: n)
        .follow_ups
        .joins(:patient)
        .group(:gender, :year, :month)
        .count

    group_by_gender(follow_ups, :follow_ups, @monthly_period_list)
  end

  def htn_control_for_last_n_months(n)
    visits = LatestBloodPressuresPerPatientPerDay
               .where(facility: @current_facility)
               .where("(year, month) IN (#{periods_as_sql_list(period_list(:month, n))})")

    total_visits =
      visits
        .group(:year, :month)
        .count
        .map { |group, fps| [moy_to_date_obj(*group), total_visits: fps] }
        .to_h

    controlled_visits =
      visits
        .under_control
        .group(:year, :month)
        .count
        .map { |group, fps| [moy_to_date_obj(*group), controlled_visits: fps] }
        .to_h

    group_by_date([
                    data_for_unavailable_dates(:total_visits, @monthly_period_list).merge(total_visits),
                    data_for_unavailable_dates(:controlled_visits, @monthly_period_list).merge(controlled_visits)
                  ].inject(&:deep_merge))
  end

  #
  # Groups by gender in the following format,
  #
  # { :grouped_by_gender =>
  #    { "male" =>
  #        { "Sun, 01 Mar 2020" => { :resource_name => 21 },
  #          "Tue, 01 Oct 2019" => { :resource_name => 0 } },
  #      "female" =>
  #        { "Sun, 01 Mar 2020" => { :resource_name => 18 },
  #          "Tue, 01 Oct 2019" => { :resource_name => 0 } } } }
  #
  def group_by_gender(resource_data, resource_name, period_list)
    grouped_by_gender =
      resource_data.inject(autovivified_hash) do |acc, (group, resource)|
        gender, year, month = *group
        acc[gender][moy_to_date_obj(year, month)].merge!(resource_name => resource)
        acc
      end

    {
      grouped_by_gender:
        grouped_by_gender
          .map { |gender, data| [gender, data_for_unavailable_dates(resource_name, period_list).merge(data)] }
          .to_h
    }
  end

  def group_by_date(resource_data)
    {
      grouped_by_date: resource_data
    }
  end

  def data_for_unavailable_dates(data_key, period_list)
    period_list.map { |date| [date, data_key => 0] }.to_h
  end
end
