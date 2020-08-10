module Reports::RegionsHelper
  def percentage_or_na(value, options)
    return "N/A" if value.blank?
    number_to_percentage(value, options)
  end
end
