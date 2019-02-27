class AppointmentsController < AdminController
  include FacilityFiltering
  include Pagination

  before_action :set_appointment, only: [:update]

  def index
    authorize Appointment, :index?

    @appointments = policy_scope(Appointment)
                      .overdue
                      .where(facility: selected_facilities)
                      .order(scheduled_date: :asc)

    @appointments = paginate(@appointments)
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
