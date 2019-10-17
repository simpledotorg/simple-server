class PatientsController < AdminController
  include FacilityFiltering
  include Pagination

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

  def update
    if @patient.update(patient_params)
      redirect_to patients_url, notice: "Saved. #{@patient.full_name} marked as \"#{@patient.call_result.humanize}\""
    else
      redirect_back fallback_location: root_path, alert: 'Something went wrong!'
    end
  end

  private

  def set_patient
    @patient = Patient.find(params[:id] || params[:patient_id])
    authorize @patient
  end

  def patient_params
    params.require(:patient).permit(:call_result)
  end
end
