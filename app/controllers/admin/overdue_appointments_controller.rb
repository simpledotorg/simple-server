class Admin::OverdueAppointmentsController < AdminController
  before_action :set_overdue_appointment, only: [:edit, :update, :cancel]

  def index
    authorize :overdue_appointment, :index?
    overdue_appointments = policy_scope(OverdueAppointment)
    @overdue_appointments_per_facility = overdue_appointments.group_by do |overdue_appointment|
      overdue_appointment.appointment.facility
    end
  end

  def edit
  end

  def cancel
  end

  def update
    appointment = @overdue_appointment.appointment
    if appointment.update(appointment_params)
      redirect_to admin_overdue_appointments_url, notice: 'Appointment was successfully updated.'
    else
      redirect_to :back
    end
  end

  private

  def set_overdue_appointment
    begin
      patient = Patient.find(params[:id] || params[:overdue_appointment_id])
      @overdue_appointment = OverdueAppointment.for_patient(patient)
      authorize @overdue_appointment
    rescue
      render file: "#{Rails.root}/public/404.html", status: 404
    end
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
