class PatientListDownloadJob
  include Sidekiq::Worker

  sidekiq_options lock: :while_executing,
                  lock_timeout: 1,
                  lock_ttl: 15.minutes.to_i,
                  on_conflict: {
                    server: :reject
                  }

  def perform(recipient_email, model_type, params)
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

    patients = model.assigned_patients.excluding_dead

    exporter = PatientsWithHistoryExporter
    patients_csv = exporter.csv(patients)

    sleep 10.seconds
    PatientListDownloadMailer.patient_list(recipient_email, model_type, model_name, patients_csv).deliver_now
  end
end
