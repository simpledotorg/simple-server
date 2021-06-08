class ControlRateQueryV2
  def controlled(region)
    ReportingPatientStatesPerMonth.where(assigned_facility: region.facilities, last_bp_state: :controlled, care_state: :under_care)
      .where("months_since_bp < ?", 3)
      .group_by_period(:month, :month_date, default_value: 0, format: Period.formatter(:month))
  end

  def uncontrolled(region, period)
    raise 'not yet'
  end

  def controlled_counts(region, range:)
    time_range = (range.begin.value..range.end.value)
    ReportingPatientStatesPerMonth.where(assigned_facility: region.facilities, last_bp_state: :controlled, care_state: :under_care)
      .where("months_since_bp < ?", 3)
      .group_by_period(:month, :month_date, range: time_range, format: Period.formatter(:month))
      .count
  end

end