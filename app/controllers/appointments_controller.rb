class AppointmentsController < AdminController
  before_action :set_appointment, only: [:edit, :update, :cancel, :cancel_with_reason]

  def index
    authorize Appointment, :index?
    @appointments_per_facility = policy_scope(Appointment)
                                   .overdue
                                   .reject(&:postponed?)
                                   .group_by(&:facility)
  end

  def edit
  end

  def cancel
  end

  def update
    call_result = call_result_params[:call_result]
    update_fields = parse_call_result(call_result)

    if @appointment.update(update_fields)
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

  def call_result_params
    params.require(:appointment).permit(
      :call_result
    )
  end

  def parse_call_result(call_result)
    if call_result.nil?
      {}
    elsif call_result == 'remind_in_a_week'
      {
        agreed_to_visit: true,
        remind_on: Date.today + 7.days
      }
    else
      {
        status: :cancelled,
        cancel_reason: call_result
      }
    end
  end
end
