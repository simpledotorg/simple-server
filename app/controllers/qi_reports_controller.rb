# frozen_string_literal: true

class QiReportsController < AdminController
  # [report name used in the PDF filename, tab label]
  REPORT_TABS = [["Titration", "Titration reports"], ["Statins", "Statins report"]].freeze

  OTHER_DIVISION = "Other"

  def index
    @report_tabs = REPORT_TABS
    @report_type, @report_label = REPORT_TABS.find { |name, _| name.casecmp?(params[:report].to_s) } || REPORT_TABS.first
    visible = authorize { QiReport.visible_to(current_admin) }
    reports_by_district = visible.select { |r| r.report.casecmp?(@report_type) }.group_by(&:district)

    @settings = QiReport.settings
    @state_level = QiReport.state_level?
    if @state_level
      # One report per state region: a single dropdown, no divisions
      @divisions = []
      @districts = reports_by_district.keys.sort
    else
      division_of = QiReport.divisions_by_district(current_admin)
      @district_divisions = reports_by_district.keys.to_h { |d| [d, division_of[d.downcase] || OTHER_DIVISION] }
      @divisions = @district_divisions.values.uniq.sort

      @division = params[:division] if @divisions.include?(params[:division])
      @division ||= @divisions.first if @divisions.one?
      @districts = @district_divisions.select { |_, division| @division.nil? || division == @division }.keys.sort
    end

    @district = params[:district] if @districts.include?(params[:district])
    @district ||= @districts.first if @districts.one?
    @division ||= @district_divisions[@district] if @district && !@state_level

    # Newest first, so the latest report for the district is shown by default
    @district_reports = reports_by_district.fetch(@district, []).sort_by { |r| r.sort_date.to_s }.reverse
    @selected_report = @district_reports.find { |r| r.filename == params[:file] } || @district_reports.first
    @has_reports = reports_by_district.any?
  end

  def file
    # authorize raises NotAuthorizedError when the file isn't one this user may see (nil result)
    report = authorize { QiReport.visible_to(current_admin).find { |r| r.filename == params[:file] } }

    send_file report.path, type: "application/pdf", filename: report.filename,
      disposition: params[:download].present? ? "attachment" : "inline"
  end
end
