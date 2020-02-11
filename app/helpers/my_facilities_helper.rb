module MyFacilitiesHelper
  def preserve_query_params(params, preserve_list)
    params.select { |param, _| preserve_list.include?(param) }
  end
end
