class ActivityService
  def initialize(region, include_current_period: true, last: MONTHS_AGO, group: [:gender])
    @region = region
    @group = group
    @last = last
  end

  DAYS_AGO = 30
  MONTHS_AGO = 6
  HTN_CONTROL_MONTHS_AGO = 12

  attr_reader :group
  attr_reader :region
  attr_reader :last

  def follow_ups
    region.hypertension_follow_ups_by_period(:month, last: last)
      .group(:gender)
      .count
  end

  def registrations
    region.registered_hypertension_patients
      .group_by_period(:month, :recorded_at, last: last)
      .group(group)
      .count
  end

  def controlled_visits
    control_rate_end = Period.month(Date.current.advance(months: -1).beginning_of_month)
    control_rate_start = control_rate_end.advance(months: -HTN_CONTROL_MONTHS_AGO)
    ControlRateService.new(region, periods: control_rate_start..control_rate_end).call
  end
end
