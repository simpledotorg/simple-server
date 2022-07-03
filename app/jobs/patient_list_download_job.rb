class PatientListDownloadJob
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed,
    lock_timeout: 15.minutes,
    lock_ttl: 15.minutes,
    on_server_conflict: :reject

  def perform(recipient_email, model_type, params, diagnosis: :all)
    case model_type
    when "facility"
      model = Facility.find(params["facility_id"])
      model_name = model.name
      when "facility_group"
        model = FacilityGroup.find(params["id"])
        model_name = model.name
      else
        raise ArgumentError, "unknown model_type #{model_type.inspect}"
    end

    patients = get_patients(:diagnosis)

    exporter = PatientsWithHistoryExporter
    patients_csv = exporter.csv(patients)

    PatientListDownloadMailer.patient_list(recipient_email, model_type, model_name, patients_csv).deliver_now
  end

  private

  def get_patients(diagnosis)
    case diagnosis
    when :hypertension
      model.assigned_hypertension_patients.excluding_dead
    when :diabetes
      model.assigned_diabetes_patients.excluding_dead
    when :all
      model.assigned_patients.excluding_dead
    else
      raise ArgumentError, "unknown diagnosis #{diagnosis}"
    end
  end
end
