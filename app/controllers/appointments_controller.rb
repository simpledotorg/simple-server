class AppointmentsController < AdminController
  before_action :set_appointment, only: [:update]

  def index
    authorize Appointment, :index?
    @appointments_per_facility = policy_scope(Appointment)
                                   .overdue
                                   .group_by(&:facility)
  end

  def edit
  end

  def cancel
  end

  def update
    if @appointment.update(appointment_params)
      redirect_to appointments_url, notice: "Appointment was successfully updated: #{appointment_params[:call_result]}"
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
