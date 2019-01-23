class Admin::OverdueAppointmentsController < AdminController
  before_action :set_overdue_appointment, only: [:edit, :update, :cancel]

  def index
    authorize :overdue_appointment, :index?
    facilities = policy_scope(Facility)
    @overdue_appointments_per_facility = {}
    facilities.each do |facility|
      @overdue_appointments_per_facility[facility.name] = OverdueAppointment.for_facility(facility)
    end
  end

  def edit
  end

  def cancel
  end

  def update
    appointment = @overdue_appointment.latest_overdue_appointment
    if appointment.update(appointment_params)
      redirect_to admin_overdue_appointments_url, notice: 'Appointment was successfully updated.'
    else
      redirect_to :back
    end
  end

  private

  def set_overdue_appointment
    patient = Patient.find(params[:id] || params[:overdue_appointment_id])
    @overdue_appointment = OverdueAppointment.for_patient(patient)
    authorize @overdue_appointment
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