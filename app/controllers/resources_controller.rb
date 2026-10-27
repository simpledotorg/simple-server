# frozen_string_literal: true

class ResourcesController < AdminController
  skip_after_action :verify_authorization_attempted, only: [:index]

  def index
  end

  def qi_reports
    @qi_reports = authorize { QiReport.visible_to(current_admin) }
    @selected_report = @qi_reports.find { |r| r.filename == params[:file] } || @qi_reports.first
  end

  def qi_report
    # authorize raises NotAuthorizedError when the file isn't one this user may see (nil result)
    report = authorize { QiReport.visible_to(current_admin).find { |r| r.filename == params[:file] } }

    send_file report.path, type: "application/pdf", filename: report.filename,
      disposition: params[:download].present? ? "attachment" : "inline"
  end
end
