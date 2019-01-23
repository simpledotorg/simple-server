class Admin::OverdueAppointmentsController < AdminController
  def index
    authorize :overdue_appointment, :index?
    facilities = policy_scope(Facility)
    @patient_details_per_facility = {}
    facilities.each do |facility|
      @patient_details_per_facility[facility.name] = OverdueAppointment.for_facility(facility)
    end
  end

  def show
  end
end