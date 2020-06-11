class PatientsController < AdminController
  include FacilityFiltering
  include Pagination
  include SearchHelper

  before_action :set_patient, only: [:update]

  def index
    authorize([:adherence_follow_up, Patient])

    @patients = policy_scope([:adherence_follow_up, Patient])
                  .not_contacted
                  .order(device_created_at: :asc)

    if current_facility.present?
      @patients = @patients.where(registration_facility: current_facility)
    end

    @patients = paginate(@patients)
  end

  #
  # This controller / page does not have unit-tests since it's potentially throwaway work.
  # If we decide to continue using this, we should invest in testing it.
  #
  def lookup
    set_page
    set_per_page
    set_facility_id
    authorize([:overdue_list, Patient])

    if current_facility
      @patients =
        paginate(policy_scope([:overdue_list, Patient])
                   .where(registration_facility: current_facility)
                   .search_by_address(search_query))
    else
      @patients =
        paginate(policy_scope([:overdue_list, Patient])
                   .search_by_address(search_query))
    end
  end

  def update
    if @patient.update(patient_params)
      redirect_to patients_url(params: {facility_id: selected_facility_id, page: page}),
        notice: "Saved. #{@patient.full_name} marked as \"#{@patient.call_result.humanize}\""
    else
      redirect_back fallback_location: root_path, alert: 'Something went wrong!'
    end
  end

  private

  def set_patient
    @patient = Patient.find(params[:id] || params[:patient_id])
    authorize([:adherence_follow_up, @patient])
  end

  def patient_params
    params.require(:patient).permit(:call_result)
  end

  def selected_facility_id
    params[:patient][:selected_facility_id]
  end

  def page
    params[:patient][:page]
  end
end
