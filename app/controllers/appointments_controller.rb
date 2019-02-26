class AppointmentsController < AdminController
  before_action :set_appointment, only: [:update]

  DEFAULT_PAGE_SIZE = 20

  def index
    authorize Appointment, :index?

    appointments_to_show = policy_scope(Appointment)
                             .overdue
                             .where(facility: selected_facilities)

    @appointments = appointments_to_show
                      .order(scheduled_date: :asc)
                      .page(params[:page])
                      .per(per_page_count(appointments_to_show))
  end

  def update
    if @appointment.update(appointment_params)
      redirect_to appointments_url, notice: "Saved. #{@appointment.patient.full_name} marked as \"#{@appointment.call_result.humanize}\""
    else
      redirect_back fallback_location: root_path, alert: 'Something went wrong!'
    end
  end

  private

  def selected_facilities
    @facility_id = params[:facility_id].present? ? params[:facility_id] : 'All'
    if @facility_id == 'All'
      policy_scope(Facility.all)
    else
      policy_scope(Facility.where(id: @facility_id))
    end
  end

  def per_page_count(appointments_to_show)
    @per_page = params[:per_page] || DEFAULT_PAGE_SIZE
    if @per_page == 'All'
      appointments_to_show.size
    else
      @per_page.to_i
    end
  end

  def set_appointment
    @appointment = Appointment.find(params[:id] || params[:appointment_id])
    authorize @appointment
  end

  def appointment_params
    params.require(:appointment).permit(:call_result)
  end
end
