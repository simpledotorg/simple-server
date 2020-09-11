module Reports::RegionsHelper
  def percentage_or_na(value, options)
    return "N/A" if value.blank?
    number_to_percentage(value, options)
  end

  def cohort_report_type(period)
    "#{period.type.to_s.humanize}ly report"
  end
end
