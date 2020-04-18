module MyFacilitiesHelper
  def preserve_query_params(params, preserve_list)
    params.select { |param, _| preserve_list.include?(param) }
  end

  def percentage(numerator, denominator)
    return '—' if denominator.nil? || denominator.zero? || numerator.nil?
    percentage_string((numerator * 100.0) / denominator)
  end
end
