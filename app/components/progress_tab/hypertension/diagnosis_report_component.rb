# frozen_string_literal: true

class ProgressTab::Hypertension::DiagnosisReportComponent < ApplicationComponent
  include AssetsHelper
  include ApplicationHelper

  attr_reader :hypertension_reports_data

  def initialize(hypertension_reports_data:, cohort_data:, last_updated_at:)
    @hypertension_reports_data = hypertension_reports_data
    @cohort_data = cohort_data
    @last_updated_at = last_updated_at
  end
end
