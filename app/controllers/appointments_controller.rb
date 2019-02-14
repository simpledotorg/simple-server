class AppointmentsController < AdminController
  before_action :set_appointment, only: [:edit, :update, :cancel, :cancel_with_reason]

  def index
    authorize Appointment, :index?
    @appointments_per_facility = policy_scope(Appointment).overdue.appointments_per_facility
  end

  def edit
  end

  def cancel
  end

  def cancel_with_reason
    update_fields = {
      status: :cancelled,
      cancel_reason: cancel_params[:cancel_reason]
    }
    if @appointment.update(update_fields)
      redirect_to appointments_url, notice: 'Appointment was successfully canceled.'
    else
      redirect_back fallback_location: root_path, alert: 'Something went wrong!'
    end
  end

  def update
    if @appointment.update(edit_params)
      redirect_to appointments_url, notice: 'Appointment was successfully updated.'
    else
      redirect_back fallback_location: root_path, alert: 'Something went wrong!'
    end
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:id] || params[:appointment_id])
    authorize @appointment
  end

  def edit_params
    params.require(:appointment).permit(
      :agreed_to_visit,
      :remind_on
    )
  end

  def cancel_params
    params.require(:appointment).permit(
      :cancel_reason
    )
  end
end
