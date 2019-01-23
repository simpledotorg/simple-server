class Admin::OverdueAppointmentsController < AdminController
  def index
    authorize :overdue_appointment, :index?
    facilities = policy_scope(Facility)
    @overdue_appointments_per_facility = {}
    facilities.each do |facility|
      @overdue_appointments_per_facility[facility.name] = OverdueAppointment.for_facility(facility)
    end
  end

  def show
  end

  def edit
  end
end