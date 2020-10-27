class ActivityService
  def initialize(region, diagnosis: :hypertension, period: :month, include_current_period: true, group: nil, last: nil)
    @region = region
    @diagnosis = diagnosis
    @period = period
    @group = group
    @last = last
  end

  DAYS_AGO = 30
  MONTHS_AGO = 6

  attr_reader :region
  attr_reader :diagnosis
  attr_reader :period
  attr_reader :group
  attr_reader :last

  def registrations
    relation = registrations_relation
    relation = relation.group_by_period(period, :recorded_at, last: last)
    relation = relation.group(group) if group.present?
    relation.count
  end

  def follow_ups
    relation = follow_ups_relation
    relation = relation.group(group) if group.present?
    relation.count
  end

  private

  def registrations_relation
    case diagnosis
    when :hypertension
      region.registered_hypertension_patients
    when :diabetes
      region.registered_diabetes_patients
    when :all
      region.registered_patients
    else
      raise ArgumentError, "Unsupported diagnosis"
    end
  end

  def follow_ups_relation
    case diagnosis
    when :hypertension
      region.hypertension_follow_ups_by_period(period, last: last)
    when :diabetes
      region.diabetes_follow_ups_by_period(period, last: last)
    when :all
      region.patient_follow_ups_by_period(period, last: last)
    else
      raise ArgumentError, "Unsupported diagnosis"
    end
  end
end
