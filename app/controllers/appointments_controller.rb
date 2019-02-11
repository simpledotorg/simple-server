class AppointmentsController < AdminController
  before_action :set_appointment, only: [:edit, :update, :cancel]

  def index
    authorize Appointment, :index?
    @appointments_per_facility = policy_scope(Appointment).overdue.group_by(&:facility)
  end

  def edit
  end

  def cancel
  end

  def update
    appointment = @appointment
    if appointment.update(appointment_params)
      redirect_to appointments_url, notice: 'Appointment was successfully updated.'
    else
      redirect_to :back
    end
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:id])
    authorize @appointment
  end

  def appointment_params
    params.require(:appointment).permit(
      :agreed_to_visit,
      :remind_on,
      :cancel_reason,
      :status
    )
  end
end
