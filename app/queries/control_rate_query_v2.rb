class ControlRateQueryV2
  def controlled(region)
    ReportingPipeline::PatientStatesPerMonth
      .where(hypertension: "yes", htn_care_state: "under_care")
      .where("assigned_#{region.region_type}_region_id" => region.id)
      .where("months_since_registration >= ?", Reports::REGISTRATION_BUFFER_IN_MONTHS)
      .where(htn_treatment_outcome_in_last_3_months: :controlled)
  end

  def controlled_counts(region, range: nil)
    options = { format: Period.formatter(:month) }
    if range
      time_range = (range.begin.start_time..range.end.end_time)
      options[:range] = time_range
    end
    controlled(region).group_by_period(:month, :month_date, options).count
  end

  def uncontrolled(region)
    ReportingPipeline::PatientStatesPerMonth
      .where("assigned_#{region.region_type}_region_id" => region.id)
      .where(hypertension: "yes", htn_care_state: "under_care")
      .where("months_since_registration >= ?", Reports::REGISTRATION_BUFFER_IN_MONTHS)
      .where(htn_treatment_outcome_in_last_3_months: :uncontrolled)
  end

  def uncontrolled_counts(region, range: nil)
    time_range = (range.begin.start_time..range.end.end_time) if range
    uncontrolled(region).group_by_period(:month, :month_date, range: time_range, format: Period.formatter(:month)).count
  end
end
