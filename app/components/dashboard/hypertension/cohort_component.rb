class Dashboard::Hypertension::CohortComponent < ApplicationComponent
  include AssetsHelper

  attr_reader :period, :cohort_data

  def initialize(period, cohort_data)
    @period = period
    @cohort_data = cohort_data
  end

  def cohort_report_type(period)
    "#{period.type.to_s.humanize}ly report"
  end
end
