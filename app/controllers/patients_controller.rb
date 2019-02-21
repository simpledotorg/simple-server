class PatientsController < AdminController
  before_action :set_patient, only: [:update]

  def index
    authorize Patient, :index?

    @facility_slug = params[:facility]
    @per_page = params[:per_page] || 10

    @patients = policy_scope(Patient)
                  .not_contacted
                  .order(device_created_at: :asc)
                  .page(params[:page])
                  .per(@per_page == 'All' ? Patient.count : @per_page.to_i)

    if @facility_slug.present?
      @patients = @patients.where(registration_facility: Facility.friendly.find(@facility_slug))
    end
  end

  def update
    if @patient.update(patient_params)
      redirect_to patients_url, notice: "Saved call result. #{@patient.full_name}: #{@patient.call_result.humanize}"
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
