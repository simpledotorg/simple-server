require 'csv'

class AppointmentsController < AdminController
  include FacilityFiltering
  include Pagination

  before_action :set_appointment, only: [:update]

  def index
    authorize Appointment, :index?

    @appointments = policy_scope(Appointment)
                      .joins(:patient)
                      .overdue
                      .where(facility: selected_facilities)
                      .order(scheduled_date: :asc)

    respond_to do |format|
      format.html { @appointments = paginate(@appointments) }
      format.csv { render stream: true }
    end
  end

  def update
    call_result = appointment_params[:call_result].to_sym

    if set_appointment_status_from_call_result(@appointment, call_result)
      redirect_to appointments_url, notice: "Saved. #{@appointment.patient.full_name} marked as \"#{call_result.to_s.humanize}\""
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
      appointment.patient.status = appointment.mark_patient_as_dead
    end

    appointment.save
  end
end
