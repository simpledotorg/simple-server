class ActivityService
  def initialize(region, period: :month, include_current_period: true, group: nil, last: MONTHS_AGO)
    @region = region
    @period = period
    @group = group
    @last = last
  end

  DAYS_AGO = 30
  MONTHS_AGO = 6

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
end
