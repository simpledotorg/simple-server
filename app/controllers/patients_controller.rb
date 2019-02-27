class PatientsController < AdminController
  include FacilityFiltering
  include Pagination

  before_action :set_patient, only: [:update]

  def index
    authorize Patient, :index?

    @patients = policy_scope(Patient)
                  .not_contacted
                  .where(registration_facility: selected_facilities)
                  .order(device_created_at: :asc)

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
