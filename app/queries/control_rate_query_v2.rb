class ControlRateQueryV2
  def controlled(maybe_region)
    base_query(maybe_region).where(htn_treatment_outcome_in_last_3_months: :controlled)
  end

  def uncontrolled(maybe_region)
    base_query(maybe_region).where(htn_treatment_outcome_in_last_3_months: :uncontrolled)
  end

  def controlled_counts(region, range: nil)
    options = group_date_options(range)
    controlled(region).group_by_period(:month, :month_date, options).count
  end

  def uncontrolled_counts(region, range: nil)
    options = group_date_options(range)
    uncontrolled(region).group_by_period(:month, :month_date, options).count
  end

  private

  def base_query(maybe_region)
    # We need to do a little bit of hackery here to handle FacilityDistrict, which is a
    # weird special case of Region
    region = maybe_region.region
    if region.region_type == "facility_district"
      region_type = "facility"
      region_id = region.facility_ids
    else
      region_type = region.region_type
      region_id = region.id
    end
    Reports::PatientState
      .where(hypertension: "yes", htn_care_state: "under_care")
      .where("assigned_#{region_type}_region_id" => region_id)
      .where("months_since_registration >= ?", Reports::REGISTRATION_BUFFER_IN_MONTHS)
  end

  def group_date_options(range)
    options = {format: Period.formatter(:month)}
    if range
      time_range = (range.begin.start_time..range.end.end_time)
      options[:range] = time_range
    end
    options
  end
end
