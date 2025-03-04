require "faker"
require "yaml"

namespace :opensrp do
  desc "Export simple patient-related data as opensrp fhir resources"
  task :export, [:config_file, :output_file] => :environment do |_task, args|
    raise "Usage: ./bin/rake 'opensrp:export[path/to/config.yml, name-of-output.json]'" unless args.to_a.size == 2
    # For now we are leaving in the PII.
    # patients = remove_pii(patients)
    output_file = args[:output_file]
    config_file = args[:config_file]

    raise "Config file should be YAML" unless %w[yaml yml].include?(config_file.split(".").last)
    raise "Output file should be JSON" unless output_file.split(".").last == "json"
    config = YAML.load_file(config_file)

    facilities_to_export = config["facilities"]

    resources = []
    encounters = []
    patients = Patient.where(assigned_facility_id: facilities_to_export.keys)
    patients.each do |patient|
      patient_exporter = OneOff::Opensrp::PatientExporter.new(patient, facilities_to_export)
      resources << patient_exporter.export
      resources << patient_exporter.export_registration_questionnaire_response
      encounters << patient_exporter.export_registration_encounter

      patient.blood_pressures.each do |bp|
        bp_exporter = OneOff::Opensrp::BloodPressureExporter.new(bp, facilities_to_export)
        resources << bp_exporter.export
        encounters << bp_exporter.export_encounter
      end

      patient.blood_sugars.each do |bs|
        bs_exporter = OneOff::Opensrp::BloodSugarExporter.new(bs, facilities_to_export)
        if patient.medical_history.diabetes_no?
          resources << bs_exporter.export_no_diabetes_observation
        end
        resources << bs_exporter.export
        encounters << bs_exporter.export_encounter
      end

      patient.prescription_drugs.each do |drug|
        drug_exporter = OneOff::Opensrp::PrescriptionDrugExporter.new(drug, facilities_to_export)
        resources << drug_exporter.export_dosage_flag
        encounters << drug_exporter.export_encounter
      end
      OneOff::Opensrp::MedicalHistoryExporter.new(patient.medical_history, facilities_to_export).then do |medical_history_exporter|
        resources << medical_history_exporter.export
        encounters << medical_history_exporter.export_encounter
      end
      patient.appointments.each do |appointment|
        next unless appointment.status_scheduled?
        appointment_exporter = OneOff::Opensrp::AppointmentExporter.new(appointment, facilities_to_export)
        resources << appointment_exporter.export
        if appointment.call_results.present?
          resources << appointment_exporter.export_call_outcome_task
          resources << appointment_exporter.export_call_outcome_flag
        end
        encounters << appointment_exporter.export_encounter
      end
    end
    resources << OneOff::Opensrp::EncounterGenerator.new(encounters).generate

    CSV.open("audit_trail.csv", "w") do |csv|
      csv << create_audit_record(facilities_to_export, patients.first).keys
      patients.each do |patient|
        csv << create_audit_record(facilities_to_export, patient).values
      end
    end

    File.open(output_file, "w+") do |f|
      resources.flatten.each do |resource|
        f.puts(resource.as_json.to_json)
      end
    end
  end

  def create_audit_record(facilities, patient)
    return {} if patient.nil?

    {
      patient_id: patient.id,
      sri_lanka_personal_health_number: patient.business_identifiers.where(identifier_type: "sri_lanka_personal_health_number")&.first&.identifier,
      patient_bp_passport_number: patient.business_identifiers.where(identifier_type: "simple_bp_passport")&.first&.identifier,
      patient_name: patient.full_name,
      patient_gender: patient.gender,
      patient_date_of_birth: patient.date_of_birth || patient.age_updated_at - patient.age.years,
      patient_address: patient.address.street_address,
      patient_telephone: patient.phone_numbers.pluck(:number).join(";"),
      patient_facility: facilities[patient.assigned_facility_id][:name],
      patient_preferred_language: "Sinhala",
      patient_active: patient.status_active?,
      patient_deceased: patient.status_dead?,
      condition: ("HTN" if patient.medical_history.hypertension_yes?) || ("DM" if patient.medical_history.diabetes_yes?),
      blood_pressure: patient.latest_blood_pressure&.values_at(:systolic, :diastolic)&.join("/"),
      bmi: nil,
      appointment_date: patient.appointments.order(device_updated_at: :desc).where(status: "scheduled")&.first&.device_updated_at&.to_date&.iso8601,
      medication: patient.prescription_drugs.order(device_updated_at: :desc).where(is_deleted: false)&.first&.values_at(:name, :dosage)&.join(" "),
      glucose_measure: patient.latest_blood_sugar&.blood_sugar_value.then { |bs| "%.2f" % bs if bs },
      glucose_measure_type: patient.latest_blood_sugar&.blood_sugar_type,
      call_outcome: patient.appointments.order(device_updated_at: :desc)&.first&.call_results&.order(device_created_at: :desc)&.first&.result_type
    }
  end

  def remove_pii(patients)
    country = Faker::Address.country
    patients.each do |patient|
      patient.full_name = Faker::Name.name
      address = patient.address
      address.street_address = Faker::Address.street_address
      address.district = Faker::Address.district
      address.state = Faker::Address.state
      address.pin = Faker::Address.zip
      address.country = country
      patient.phone_numbers.each do |phone_number|
        phone_number.number = Faker::PhoneNumber.phone_number
      end
    end
  end
end
