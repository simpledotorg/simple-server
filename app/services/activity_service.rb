class ActivityService
  def initialize(region, include_current_period: true)
    @region = region
  end

  DAYS_AGO = 30
  MONTHS_AGO = 6
  HTN_CONTROL_MONTHS_AGO = 12

  attr_reader :region
  def call
    follow_ups =
      region
        .hypertension_follow_ups_by_period(:month, last: MONTHS_AGO)
        .group(:gender)
        .count

    control_rate_end = Period.month(Date.current.advance(months: -1).beginning_of_month)
    control_rate_start = control_rate_end.advance(months: -HTN_CONTROL_MONTHS_AGO)
    controlled_visits = ControlRateService.new(region, periods: control_rate_start..control_rate_end).call

    registrations =
      region
        .registered_hypertension_patients
        .group_by_period(:month, :recorded_at, last: MONTHS_AGO)
        .group(:gender)
        .count

    {
      grouped_by_date_and_gender: {
        hypertension: {
          follow_ups: follow_ups,
          registrations: registrations
        }
      },

      grouped_by_date: {
        hypertension: {
          follow_ups: sum_by_date(follow_ups),
          controlled_visits: controlled_visits.to_hash,
          registrations: sum_by_date(registrations)
        }
      }
    }
  end

  def sum_by_date(data)
    data.each_with_object({}) do |((date, _), count), by_date|
      by_date[date] ||= 0
      by_date[date] += count
    end
  end


end