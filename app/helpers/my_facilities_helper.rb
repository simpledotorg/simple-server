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

  # def drug_stock_tooltip(report)
  #   ERB.new("")
  #   "<span class='math'>886,915</span>Telmisartin 20 mg<br><span class='math'>+1,000,000*2</span>Amlodipine 10 mg<br><span class='math'>+128,760</span>Losartan 50 mg<br><span class='math'>/23,489*0.37</span>Patients<br><span class='math'>=117 days</span>Patient days"
  # end
end
