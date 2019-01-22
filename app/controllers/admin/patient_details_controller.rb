class Admin::PatientDetailsController < AdminController
  def index
    authorize :patient_detail, :index?
    facilities = policy_scope(Facility)
    @patient_details_per_facility = {}
    puts :here
    facilities.each do |facility|
      @patient_details_per_facility[facility.name] = PatientDetail.for_facility(facility)
    end
  end

  def show
  end
end