# frozen_string_literal: true

class QiReportsController < AdminController
  # [report name used in the PDF filename, tab label]
  REPORT_TABS = [["Titration", "Titration reports"], ["Statins", "Statins report"]].freeze

  def index
    @report_tabs = REPORT_TABS
    @report_type, @report_label = REPORT_TABS.find { |name, _| name.casecmp?(params[:report].to_s) } || REPORT_TABS.first
    visible = authorize { QiReport.visible_to(current_admin) }
    @qi_reports = visible.select { |r| r.report.casecmp?(@report_type) }
    @selected_report = @qi_reports.find { |r| r.filename == params[:file] } || @qi_reports.first
  end

  def file
    # authorize raises NotAuthorizedError when the file isn't one this user may see (nil result)
    report = authorize { QiReport.visible_to(current_admin).find { |r| r.filename == params[:file] } }

    send_file report.path, type: "application/pdf", filename: report.filename,
      disposition: params[:download].present? ? "attachment" : "inline"
  end
end
