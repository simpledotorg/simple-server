# frozen_string_literal: true

class ResourcesController < AdminController
  QI_REPORTS_DIR = Rails.root.join("public", "documents", "qi_reports")

  skip_after_action :verify_authorization_attempted, only: [:index, :qi_reports]

  def index
  end

  def qi_reports
    @qi_reports = Dir.children(QI_REPORTS_DIR).select { |name| name.downcase.end_with?(".pdf") }.sort
    @selected_report = @qi_reports.find { |name| name == params[:file] } || @qi_reports.first
  end
end
