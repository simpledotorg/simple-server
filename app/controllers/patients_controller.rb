class PatientsController < AdminController
  before_action :set_patient, only: [:update]

  DEFAULT_PAGE_SIZE = 20

  def index
    authorize Patient, :index?

    @facility_id = params[:facility_id].present? ? params[:facility_id] : 'All'
    selected_facilities = @facility_id == 'All' ? policy_scope(Facility.all) : policy_scope(Facility.where(id: @facility_id))
    patients_to_show = policy_scope(Patient)
                         .not_contacted
                         .where(registration_facility: selected_facilities)

    @per_page = params[:per_page].present? ? params[:per_page] : DEFAULT_PAGE_SIZE
    per_page_count = @per_page == 'All' ? patients_to_show.size : @per_page.to_i
    @patients = patients_to_show
                  .order(device_created_at: :asc)
                  .page(params[:page])
                  .per(per_page_count)
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
