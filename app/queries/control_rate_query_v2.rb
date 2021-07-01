class ControlRateQueryV2
  def controlled(region)
    ReportingPipeline::PatientStatesPerMonth
      .where(hypertension: "yes", htn_care_state: "under_care")
      .where("assigned_#{region.region.region_type}_region_id" => region.id)
      .where("months_since_registration >= ?", Reports::REGISTRATION_BUFFER_IN_MONTHS)
      .where(htn_treatment_outcome_in_last_3_months: :controlled)
  end

  def controlled_counts(region, range: nil)
    options = group_date_options(range)
    controlled(region).group_by_period(:month, :month_date, options).count
  end

  def uncontrolled(region)
    ReportingPipeline::PatientStatesPerMonth
      .where("assigned_#{region.region.region_type}_region_id" => region.id)
      .where(hypertension: "yes", htn_care_state: "under_care")
      .where("months_since_registration >= ?", Reports::REGISTRATION_BUFFER_IN_MONTHS)
      .where(htn_treatment_outcome_in_last_3_months: :uncontrolled)
  end

  def uncontrolled_counts(region, range: nil)
    options = group_date_options(range)
    uncontrolled(region).group_by_period(:month, :month_date, options).count
  end

  private

  def group_date_options(range)
    options = {format: Period.formatter(:month)}
    if range
      time_range = (range.begin.start_time..range.end.end_time)
      options[:range] = time_range
    end
    options
  end
end
