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

  def drug_stock_tooltip(report)
    return nil if report.nil? || report[:patient_days] == "error"
    tooltip_template = ERB.new <<-EOF
      <% report[:stocks_on_hand].each_with_index do |stock_on_hand, i| %>
        <span class='math'><%= '+' unless i == 0 %><%= stock_on_hand[:in_stock] %>*<%= stock_on_hand[:coefficient] %></span>
        <%= stock_on_hand[:protocol_drug].name %> <%= stock_on_hand[:protocol_drug].dosage %>
        <br>
      <% end %>
      <span class='math'>
        /<%= report[:patient_count] %>*<%= report[:load_coefficient] %>*<%= report[:new_patient_coefficient] %>
      </span>
      Patients
      <br>
      <span class='math'>=<%= report[:patient_days] %></span>
      Patient days
    EOF
    tooltip_template.result(binding)
  end

  def patient_days_bg_color(patient_days)
    return if patient_days.nil?
    return "bg-red" if patient_days == "error"
    if patient_days < 30 then "bg-red"
    elsif patient_days < 60 then "bg-orange"
    elsif patient_days < 90 then "bg-yellow"
    else
      "bg-green"
    end
  end

  def protocol_drug_labels
    {hypertension_ccb: "CCB Tablets",
     hypertension_arb: "ARB Tablets",
     hypertension_diuretic: "Diuretic Tablets",
     hypertension_other: "Other Tablets",
     diabetes: "Diabetes Tablets",
     other: "Other Tablets"}.with_indifferent_access
  end
end
