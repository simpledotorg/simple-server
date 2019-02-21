class AppointmentsController < AdminController
  before_action :set_appointment, only: [:update]

  def index
    authorize Appointment, :index?

    @facility_id = params[:facility_id].present? ? params[:facility_id] : 'All'
    @per_page = params[:per_page] || 10

    appointments_to_show = policy_scope(Appointment)
                             .overdue
                             .where_or_all(:facility_id, @facility_id)

    @appointments = appointments_to_show
                      .order(scheduled_date: :asc)
                      .page(params[:page])
                      .per(@per_page == 'All' ? appointments_to_show.count : @per_page.to_i)
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
