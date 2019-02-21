class PatientsController < AdminController
  before_action :set_patient, only: [:update]

  def index
    authorize Patient, :index?

    @facility_id = params[:facility_id].present? ? params[:facility_id] : 'All'
    @per_page = params[:per_page] || 10

    patients_to_show = policy_scope(Patient)
                         .not_contacted
                         .where_or_all(:registration_facility_id, @facility_id)

    @patients = patients_to_show
                  .order(device_created_at: :asc)
                  .page(params[:page])
                  .per(@per_page == 'All' ? patients_to_show.count : @per_page.to_i)
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
