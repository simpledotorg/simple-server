class ActivityService
  def initialize(region, period: :month, include_current_period: true, last: MONTHS_AGO, group: nil)
    @region = region
    @period = period
    @group = group
    @last = last
  end

  DAYS_AGO = 30
  MONTHS_AGO = 6
  HTN_CONTROL_MONTHS_AGO = 12

  attr_reader :region
  attr_reader :period
  attr_reader :group
  attr_reader :last

  def follow_ups
    relation = region.hypertension_follow_ups_by_period(period, last: last)
    if group.present?
      relation = relation.group(group)
    end
    relation.count
  end

  def registrations
    relation = region.registered_hypertension_patients
    relation = relation.group_by_period(period, :recorded_at, last: last)
    if group.present?
      relation = relation.group(group) if group
    end
    relation.count
  end

  def controlled_visits
    control_rate_end = Period.month(Date.current.advance(months: -1).beginning_of_month)
    control_rate_start = control_rate_end.advance(months: -HTN_CONTROL_MONTHS_AGO)
    ControlRateService.new(region, periods: control_rate_start..control_rate_end).call
  end
end
