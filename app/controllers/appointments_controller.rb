class AppointmentsController < AdminController
  before_action :set_appointment, only: [:update]

  DEFAULT_PAGE_SIZE = 20

  def index
    authorize Appointment, :index?

    @facility_id = params[:facility_id] || 'All'
    selected_facilities = @facility_id == 'All' ? policy_scope(Facility.all) : policy_scope(Facility.where(id: @facility_id))
    appointments_to_show = policy_scope(Appointment)
                             .overdue
                             .where(facility: selected_facilities)

    @per_page = params[:per_page].present? || DEFAULT_PAGE_SIZE
    per_page_count = @per_page == 'All' ? appointments_to_show.size : @per_page.to_i
    @appointments = appointments_to_show
                      .order(scheduled_date: :asc)
                      .page(params[:page])
                      .per(per_page_count)
  end

  def update
    if @appointment.update(appointment_params)
      redirect_to appointments_url, notice: "Saved. #{@appointment.patient.full_name} marked as \"#{@appointment.call_result.humanize}\""
    else
      redirect_back fallback_location: root_path, alert: 'Something went wrong!'
    end
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:id] || params[:appointment_id])
    authorize @appointment
  end

  def appointment_params
    params.require(:appointment).permit(:call_result)
  end
end
