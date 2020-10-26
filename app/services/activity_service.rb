class ActivityService
  def initialize(region, include_current_period: true, group: [:gender])
    @region = region
    @group = group
  end

  DAYS_AGO = 30
  MONTHS_AGO = 6
  HTN_CONTROL_MONTHS_AGO = 12

  attr_reader :group
  attr_reader :region

  def follow_ups
    region.hypertension_follow_ups_by_period(:month, last: MONTHS_AGO)
      .group(:gender)
      .count
  end

  def registrations
    region.registered_hypertension_patients
      .group_by_period(:month, :recorded_at, last: MONTHS_AGO)
      .group(group)
      .count
  end

  def controlled_visits
    control_rate_end = Period.month(Date.current.advance(months: -1).beginning_of_month)
    control_rate_start = control_rate_end.advance(months: -HTN_CONTROL_MONTHS_AGO)
    ControlRateService.new(region, periods: control_rate_start..control_rate_end).call
  end

  def call
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
end