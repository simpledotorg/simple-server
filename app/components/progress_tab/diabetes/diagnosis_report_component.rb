# frozen_string_literal: true

class ProgressTab::Diabetes::DiagnosisReportComponent < ApplicationComponent
  include AssetsHelper
  include ApplicationHelper

  attr_reader :diabetes_reports_data

  def initialize(diabetes_reports_data:)
    @diabetes_reports_data = diabetes_reports_data
  end
end
