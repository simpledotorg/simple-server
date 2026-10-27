# frozen_string_literal: true

class QiReportsController < AdminController
  def index
    @qi_reports = authorize { QiReport.visible_to(current_admin) }
    @selected_report = @qi_reports.find { |r| r.filename == params[:file] } || @qi_reports.first
  end

  def file
    # authorize raises NotAuthorizedError when the file isn't one this user may see (nil result)
    report = authorize { QiReport.visible_to(current_admin).find { |r| r.filename == params[:file] } }

    send_file report.path, type: "application/pdf", filename: report.filename,
      disposition: params[:download].present? ? "attachment" : "inline"
  end
end
