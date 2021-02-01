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
        /<%= report[:patient_count] %>*<%= report[:load_factor] %>*<%= report[:new_patient_coefficient] %>
      </span>
      Patients
      <br>
      <span class='math'>=<%= report[:patient_days] %> days</span>
      Patient days
    EOF
    tooltip_template.result(binding)
  end
end
