class PatientListDownloadJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(recipient_email, model_type, params, with_medication_history: false)
    case model_type
    when 'district' then
      district_name = params[:district_name]
      organization  = Organization.find(params[:organization_id])
      model = OrganizationDistrict.new(district_name, organization)
      model_name = district_name
    when 'facility' then
      model = Facility.find(params[:facility_id])
      model_name = model.name
    end

    exporter = with_medication_history ? PatientsWithHistoryExporter : PatientsExporter
    patients_csv = exporter.csv(
      model
        .registered_patients
        .order("facilities.state, facilities.district, facilities.name, patients.recorded_at ASC")
    )

    PatientListDownloadMailer.patient_list(recipient_email, model_type, model_name, patients_csv).deliver_later
  end
end
