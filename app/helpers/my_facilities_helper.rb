module MyFacilitiesHelper
  def preserve_query_params(params, preserve_list)
    params.select { |param, _| preserve_list.include?(param) }
  end

  def percentage(numerator, denominator)
    return "0%" if denominator.nil? || denominator.zero? || numerator.nil?
    percentage_string((numerator * 100.0) / denominator)
  end

  def opd_load(facility, selected_period)
    return if facility.monthly_estimated_opd_load.nil?

    case selected_period
    when :quarter
      facility.monthly_estimated_opd_load * 3
    when :month
      facility.monthly_estimated_opd_load
    end
  end

  def patient_days_css_class(patient_days, prefix: "bg")
    return if patient_days.nil?
    color = if patient_days == "error" then :red
    elsif patient_days < 30 then :red
    elsif patient_days < 60 then :orange
    elsif patient_days < 90 then "yellow-dark"
    else
      :green
    end
    "#{prefix}-#{color}"
  end

  def protocol_drug_labels
    {hypertension_ccb: {full: "CCB Tablets", short: "CCB"},
     hypertension_arb: {full: "ARB Tablets", short: "ARB"},
     hypertension_diuretic: {full: "Diuretic Tablets", short: "Diuretic"},
     hypertension_ace: {full: "ACE Tablets", short: "ACE"},
     hypertension_other: {full: "Other Tablets", short: "Other(H)"},
     diabetes: {full: "Diabetes Tablets", short: "Diabetes"},
     other: {full: "Other Tablets", short: "Other"}}.with_indifferent_access
  end
end
