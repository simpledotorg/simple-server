class ActivityService
  def initialize(region, diagnosis: :hypertension, period: :month, include_current_period: true, group: nil, last: nil)
    @region = region
    @diagnosis = diagnosis
    @period = period
    @include_current_period = include_current_period
    @group = group
    @last = last
  end

  DAYS_AGO = 30
  MONTHS_AGO = 6

  attr_reader :region
  attr_reader :diagnosis
  attr_reader :period
  attr_reader :include_current_period
  attr_reader :group
  attr_reader :last

  def registrations
    relation = registrations_relation
    relation = relation.group_by_period(period, :recorded_at, current: include_current_period, last: last)
    relation = relation.group(group) if group.present?
    relation.count
  end

  def follow_ups
    relation = follow_ups_relation
    relation = relation.group(group) if group.present?
    relation.count
  end

  def bp_measures
    relation = bp_measures_relation
    relation = relation.group(group) if group.present?
    relation.count
  end

  private

  def registrations_relation
    case diagnosis
    when :hypertension
      region.registered_hypertension_patients.for_reports
    when :diabetes
      region.registered_diabetes_patients.excluding_dead
    when :all
      region.registered_patients.excluding_dead
    else
      raise ArgumentError, "Unsupported diagnosis"
    end
  end

  def follow_ups_relation
    case diagnosis
    when :hypertension
      Patient.hypertension_follow_ups_by_period(period, at_region: region, current: include_current_period, last: last)
    when :diabetes
      Patient.diabetes_follow_ups_by_period(period, at_region: region, current: include_current_period, last: last)
    when :all
      Patient.follow_ups_by_period(period, at_region: region, current: include_current_period, last: last)
    else
      raise ArgumentError, "Unsupported diagnosis"
    end
  end

  def bp_measures_relation
    case diagnosis
    when :hypertension
      BloodPressure
        .joins(:patient).merge(Patient.with_hypertension)
        .group_by_period(period, :recorded_at, current: include_current_period, last: last)
        .where(facility: region.facilities)
    when :diabetes
      BloodPressure
        .joins(:patient).merge(Patient.with_diabetes)
        .group_by_period(period, :recorded_at, current: include_current_period, last: last)
        .where(facility: region.facilities)
    when :all
      BloodPressure
        .group_by_period(period, :recorded_at, current: include_current_period, last: last)
        .where(facility: region.facilities)
    else
      raise ArgumentError, "Unsupported diagnosis"
    end
  end
end
