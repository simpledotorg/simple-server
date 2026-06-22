class Reports::FormsController < AdminController
  include RegionSearch

  before_action :show_region_search
  MOCK_FORM_TYPES = [
    {
      id: "monthly_screening_reports",
      title: "Monthly screening report",
      description: "HTN and DM screening counts for the month",
      icon: "heartbeat"
    },
    {
      id: "monthly_supplies_reports",
      title: "Monthly supplies report",
      description: "Equipment and supplies available at the facility",
      icon: "toolbox"
    },
    {
      id: "drug_stock_reports",
      title: "Drug stock report",
      description: "Drug inventory at end of month",
      icon: "pills"
    }
  ].freeze

  MOCK_RESPONSES = {
    "monthly_screening_reports" => [
      {id: "2025-07", label: "Jul 2025", submitted: false},
      {id: "2025-06", label: "Jun 2025", submitted: true},
      {id: "2025-05", label: "May 2025", submitted: true}
    ],
    "monthly_supplies_reports" => [
      {id: "2025-07", label: "Jul 2025", submitted: false},
      {id: "2025-06", label: "Jun 2025", submitted: false},
      {id: "2025-05", label: "May 2025", submitted: true}
    ],
    "drug_stock_reports" => [
      {id: "2025-07", label: "Jul 2025", submitted: false},
      {id: "2025-06", label: "Jun 2025", submitted: true}
    ]
  }.freeze

  MOCK_FORM_LAYOUTS = {
    "monthly_screening_reports" => Reports::MockScreeningFormLayout::LAYOUT
  }.freeze

  MOCK_FORM_SECTIONS = {
    "monthly_supplies_reports" => [
      {
        header: "Blood pressure equipment",
        fields: [
          {label: "Functional BP apparatus available", value: "yes", type: :radio, options: %w[yes no]},
          {label: "Number of functional BP apparatus", value: nil}
        ]
      },
      {
        header: "Comments",
        fields: [
          {label: "Comments", value: nil, type: :text}
        ]
      }
    ],
    "drug_stock_reports" => [
      {
        header: "Amlodipine 5 mg",
        fields: [
          {label: "Received during the month", value: nil},
          {label: "Issued to other facilities", value: nil},
          {label: "Stock at end of the month", value: nil}
        ]
      },
      {
        header: "Metformin 500 mg",
        fields: [
          {label: "Received during the month", value: nil},
          {label: "Issued to other facilities", value: nil},
          {label: "Stock at end of the month", value: nil}
        ]
      }
    ]
  }.freeze

  before_action :find_region
  before_action :require_facility_region
  before_action :set_period
  before_action :set_form_type, only: [:responses, :edit, :update]
  before_action :set_response, only: [:edit, :update]

  def index
    @form_types = MOCK_FORM_TYPES
  end

  def responses
    @responses = MOCK_RESPONSES.fetch(@form_type[:id], [])
  end

  def edit
    @form_layout = MOCK_FORM_LAYOUTS[@form_type[:id]]
    @form_sections = MOCK_FORM_SECTIONS.fetch(@form_type[:id], []) unless @form_layout
  end

  def update
    redirect_to reports_region_form_responses_path(
      report_scope: params[:report_scope],
      id: @region.slug,
      form_type: @form_type[:id]
    ), notice: "Report saved (mock — not persisted)."
  end

  private

  def find_region
    report_scope = report_params[:report_scope]
    @region ||= authorize {
      case report_scope
      when "facility"
        current_admin.accessible_facility_regions(:view_reports).find_by!(slug: report_params[:id])
      else
        raise ActiveRecord::RecordNotFound, "Forms are only available at facility level"
      end
    }
  end

  def require_facility_region
    return if @region.facility_region?

    redirect_to root_path, alert: "Forms are only available at facility level."
  end

  def set_period
    period_params = report_params[:period].presence || Reports.default_period.attributes
    @period = Period.new(period_params)
  end

  def set_form_type
    @form_type = MOCK_FORM_TYPES.find { |form_type| form_type[:id] == params[:form_type] }
    if @form_type.nil?
      redirect_to reports_region_forms_path(report_scope: params[:report_scope], id: @region.slug), alert: "Form not found."
      false
    end
  end

  def set_response
    @response = MOCK_RESPONSES.fetch(@form_type[:id], []).find { |response| response[:id] == params[:response_id] }
    if @response.nil?
      redirect_to reports_region_form_responses_path(
        report_scope: params[:report_scope],
        id: @region.slug,
        form_type: @form_type[:id]
      ), alert: "Report not found."
      false
    end
  end

  def report_params
    params.permit(:id, :report_scope, :form_type, :response_id, {period: [:type, :value]})
  end

  def accessible_region?(region, action)
    return false unless region.reportable_region?
    current_admin.region_access(memoized: true).accessible_region?(region, action)
  end

  helper_method :accessible_region?
end
