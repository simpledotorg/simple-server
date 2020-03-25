class Api::V3::Analytics::UserAnalyticsController < Api::V3::AnalyticsController
  include HashUtilities
  include ApplicationHelper
  include DashboardHelper
  include MonthHelper
  include DayHelper
  include PeriodHelper

  layout false

  DAYS_AGO = 30
  MONTHS_AGO = 6

  def show
    @daily_period_list =
      period_list(:day, DAYS_AGO).sort.reverse.map { |date| doy_to_date_obj(*date) }
    @monthly_period_list =
      period_list(:month, MONTHS_AGO).sort.reverse.map { |date| moy_to_date_obj(*date) }

    @user_analytics =
      UserAnalyticsQuery.new(current_facility, days_ago: DAYS_AGO, months_ago: MONTHS_AGO)

    @statistics = {
      daily: prepare_daily_stats,
      monthly: prepare_monthly_stats,
      all_time: prepare_all_time_stats,
      trophies: prepare_trophies,
      metadata: {
        is_diabetes_enabled: false,
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

  def prepare_daily_stats
    {
      grouped_by_date:
        {
          follow_ups:
            data_for_unavailable_dates(@daily_period_list)
              .merge(@user_analytics.daily_follow_ups),

          registrations:
            data_for_unavailable_dates(@daily_period_list)
              .merge(@user_analytics.daily_registrations)
        }
    }
  end

  def prepare_monthly_stats
    {
      grouped_by_gender_and_date:
        {
          follow_ups:
            group_by_gender_and_date(@user_analytics.monthly_follow_ups)
              .map { |gender, data| [gender, data_for_unavailable_dates(@monthly_period_list).merge(data)] }
              .to_h,

          registrations:
            group_by_gender_and_date(@user_analytics.monthly_registrations)
              .map { |gender, data| [gender, data_for_unavailable_dates(@monthly_period_list).merge(data)] }
              .to_h
        },

      grouped_by_date:
        {
          total_visits:
            data_for_unavailable_dates(@monthly_period_list)
              .merge(@user_analytics.monthly_htn_control[:total_visits]),

          controlled_visits:
            data_for_unavailable_dates(@monthly_period_list)
              .merge(@user_analytics.monthly_htn_control[:controlled_visits]),
        }
    }
  end

  def prepare_all_time_stats
    {
      grouped_by_gender:
        {
          follow_ups:
            group_by_gender(@user_analytics.all_time_follow_ups),

          registrations:
            group_by_gender(@user_analytics.all_time_registrations)
        }
    }
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

    {
      locked_trophy_value:
        all_trophies[unlocked_trophies_until],

      unlocked_trophy_values:
        all_trophies[0, unlocked_trophies_until]
    }
  end

  #
  # Groups by gender+date in the following format,
  #
  # { :grouped_by_gender =>
  #    { "male" =>
  #        { "Sun, 01 Mar 2020" => 21 },
  #          "Tue, 01 Oct 2019" => 0 },
  #      "female" =>
  #        { "Sun, 01 Mar 2020" => 18,
  #          "Tue, 01 Oct 2019" => 0 } } }
  #
  def group_by_gender_and_date(resource_data)
    resource_data.inject(autovivified_hash) do |acc, (group, resource)|
      gender, date = *group
      acc[gender][date] = resource
      acc
    end
  end

  def group_by_gender(resource_data)
    resource_data.inject({}) do |acc, (gender, resource)|
      acc[gender] = resource
      acc
    end
  end

  def data_for_unavailable_dates(period_list)
    period_list.map { |date| [date, 0] }.to_h
  end
end
