class AppointmentsController < AdminController
  include FacilityFiltering
  include Pagination

  before_action :set_patient_search_filters, only: [:index]
  before_action :set_appointment, only: [:update]

  DEFAULT_SEARCH_FILTERS = ["only_less_than_year_overdue"]

  def index
    authorize [:overdue_list, Appointment], :index?

    @search_filters = index_params[:search_filters]
    # We have to check for a couple cases here to handle the default, page load with no parameters as well as the
    # case where a user cleared out all search filters and then submitted the search form.
    # This is because the default page load has one search filter enabled.
    if @search_filters.blank? && index_params[:submitted] # user cleared out all filters and submitted
      @search_filters = []
    elsif @search_filters.blank? # initial page load
      @search_filters = DEFAULT_SEARCH_FILTERS
    end

    scope = policy_scope([:overdue_list, PatientSummary])
    @patient_summaries = PatientSummaryQuery.call(relation: scope, filters: @search_filters)

    if current_facility
      @patient_summaries = @patient_summaries.where(next_appointment_facility_id: current_facility.id)
    end
    @patient_summaries = @patient_summaries.order(risk_level: :desc, next_appointment_scheduled_date: :desc)

    respond_to do |format|
      format.html do
        @patient_summaries = paginate(@patient_summaries).includes(:next_appointment, patient: :appointments)
        render layout: "overdue"
      end
      format.csv do
        send_data render_to_string('index.csv.erb'), filename: download_filename
      end
    end
  end

  def update
    call_result = appointment_params[:call_result].to_sym

    if set_appointment_status_from_call_result(@appointment, call_result)
      redirect_to appointments_url(params: { facility_id: selected_facility_id, page: page}),
                  notice: "Saved. #{@appointment.patient.full_name} marked as \"#{call_result.to_s.humanize}\""
    else
      redirect_back fallback_location: root_path, alert: 'Something went wrong!'
    end
  end

  private

  def set_patient_search_filters
    @patient_search_filters = {
      "only_less_than_year_overdue" => "< 365 days overdue",
      "phone_number" => "Has phone number",
      "no_phone_number" => "No phone number",
      "high_risk" => "High risk only",
    }
  end

  def index_params
    @index_params ||= params.permit(:facility_id, :per_page, :submitted, search_filters: [])
  end

  def set_appointment
    @appointment = Appointment.find(params[:id] || params[:appointment_id])
    authorize([:overdue_list, @appointment])
  end

  def appointment_params
    params.require(:appointment).permit(:call_result)
  end

  def set_appointment_status_from_call_result(appointment, call_result)
    if call_result == :agreed_to_visit
      appointment.mark_patient_agreed_to_visit
    elsif call_result == :patient_has_already_visited
      appointment.mark_patient_already_visited
    elsif call_result == :remind_to_call_later
      appointment.mark_remind_to_call_later
    elsif Appointment.cancel_reasons.values.include? call_result.to_s
      appointment.mark_appointment_cancelled(call_result)
    end

    if call_result == :dead
      appointment.mark_patient_as_dead
    end

    appointment.save
  end

  def selected_facility_id
    params[:appointment][:selected_facility_id]
  end

  def page
    params[:appointment][:page]
  end

  def download_filename
    facility_name = current_facility.present? ? current_facility.name.parameterize : 'all'
    "overdue-patients_#{facility_name}_#{Time.current.to_s(:number)}.csv"
  end
end
