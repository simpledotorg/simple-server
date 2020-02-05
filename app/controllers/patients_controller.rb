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

    respond_to do |format|
      format.html { @patients = paginate(@patients) }
      format.csv do
        send_data(render_to_string('index.csv.erb'), filename: download_filename)
      end
    end
  end

  def update
    if @patient.update(patient_params)
      redirect_to patients_url(params: { facility_id: selected_facility_id, page: page }),
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

  def download_filename
    facility_name = current_facility.present? ? current_facility.name.parameterize : 'all'
    "adherence-follow-up-patients_#{facility_name}_#{Date.current}.csv"
  end
end
