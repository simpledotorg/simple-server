class PatientListDownloadJob < ApplicationJob
  def perform(recipient_email, model_type, params, with_medication_history: false, with_exclusions: false)
    case model_type
    when "facility"
      model = Facility.find(params[:facility_id])
      model_name = model.name
    when "facility_group"
      model = FacilityGroup.find(params[:id])
      model_name = model.name
    when "facility_district"
      user = User.find(params[:user_id])
      model = FacilityDistrict.new(name: params[:name], scope: user.accessible_facilities(:view_pii))
      model_name = model.name
    else
      raise ArgumentError, "unknown model_type #{model_type.inspect}"
    end

    patients =
      if with_exclusions
        Patient.excluding_dead.where(id: model.assigned_patients)
      else
        model.assigned_patients
      end

    exporter = with_medication_history ? PatientsWithHistoryExporter : PatientsExporter
    patients_csv = exporter.csv(patients)

    PatientListDownloadMailer.patient_list(recipient_email, model_type, model_name, patients_csv).deliver_now
  end
end
