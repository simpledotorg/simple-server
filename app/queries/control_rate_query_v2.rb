class ControlRateQueryV2
  def controlled(region)
    ReportingPatientStatesPerMonth.where(assigned_facility: region.facilities, last_bp_state: :controlled, care_state: :under_care)
      .where("months_since_bp < ?", 3)
      .group_by_period(:month, :month_date, format: Period.formatter(:month))
  end

  def uncontrolled(region, period)
    raise 'not yet'
  end

end