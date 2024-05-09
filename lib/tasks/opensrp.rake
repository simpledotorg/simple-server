require "faker"

OPENSRP_ORG_MAP = {
  "27ed8faa-e36d-4de9-b25d-c87ea1b66b06" => {
    name: "Simple Health Facility",
    practitioner_id: "4bbd81b2-f997-4500-afad-0203caf96764",
    organization_id: "2c29c69f-c2d1-463f-a4b2-d90a5c2fd05d",
    care_team_id: "8a4c8a26-1e44-4483-bd3f-fa223d22b4a1",
    location_id: "ABC6789"
  },
  "4be64aa8-7f86-4a0b-97b7-1da8e93a7d68" => {
    name: "Resolve Health Facility",
    practitioner_id: "7e3a4ce3-218c-4e1e-a91c-4cb1a162807b",
    organization_id: "0954ab5a-8919-451e-a57b-557ca6ba4fd5",
    care_team_id: "cc149842-9b37-4723-9724-f863d16252a3",
    location_id: "XYZ12345"
  }
}

namespace :opensrp do
  desc "Export simple patient-related data as opensrp fhir resources"
  task :export, [:file_path] => :environment do |_task, args|
    patients = Patient
      .where(assigned_facility_id: "27ed8faa-e36d-4de9-b25d-c87ea1b66b06")
      .order(:created_at).take 2
    patients.concat(Patient
      .where(assigned_facility_id: "4be64aa8-7f86-4a0b-97b7-1da8e93a7d68")
      .order(:created_at).take(3))
    patients.each do |patient|
      if rand(2) == 0 && !patient.business_identifiers.pluck(:identifier_type).include?("sri_lanka_personal_health_number")
        identifier_value = ["#{("A".."Z").to_a.sample(4).join}/#{rand(100..999)}/#{rand(1000..9999)}",
          rand(1000..9999).to_s,
          rand(100).to_s].sample
        patient.business_identifiers.create!(identifier_type: "sri_lanka_personal_health_number",
          identifier: identifier_value,
          device_created_at: Time.current,
          device_updated_at: Time.current)
      end
    end
    # patients = remove_pii(patients)
    file_path = args[:file_path]

    resources = []
    encounters = []
    patients.each do |patient|
      patient_exporter = OneOff::Opensrp::PatientExporter.new(patient, OPENSRP_ORG_MAP)
      resources << patient_exporter.export
      resources << patient_exporter.export_registration_questionnaire_response
      encounters << patient_exporter.export_registration_encounter

      patient.blood_pressures.each do |bp|
        bp_exporter = OneOff::Opensrp::BloodPressureExporter.new(bp, OPENSRP_ORG_MAP)
        resources << bp_exporter.export
        encounters << bp_exporter.export_encounter
      end
      patient.blood_sugars.each do |bs|
        bs_exporter = OneOff::Opensrp::BloodSugarExporter.new(bs, OPENSRP_ORG_MAP)
        resources << bs_exporter.export
        encounters << bs_exporter.export_encounter
      end
      patient.prescription_drugs.each do |drug|
        drug_exporter = OneOff::Opensrp::PrescriptionDrugExporter.new(drug, OPENSRP_ORG_MAP)
        resources << drug_exporter.export_medication
        resources << drug_exporter.export
        encounters << drug_exporter.export_encounter
      end
      OneOff::Opensrp::MedicalHistoryExporter.new(patient.medical_history, OPENSRP_ORG_MAP).then do |medical_history_exporter|
        resources << medical_history_exporter.export
        encounters << medical_history_exporter.export_encounter
      end
      patient.appointments.each do |appointment|
        next unless appointment.status_scheduled?
        appointment_exporter = OneOff::Opensrp::AppointmentExporter.new(appointment, OPENSRP_ORG_MAP)
        resources << appointment_exporter.export
        encounters << appointment_exporter.export_encounter
      end
    end
    resources << OneOff::Opensrp::EncounterGenerator.new(encounters).generate

    CSV.open("audit_trail.csv", "w") do |csv|
      csv << create_audit_record(patients.first).keys
      patients.each do |patient|
        csv << create_audit_record(patient).values
      end
    end

    File.open(file_path, "w+") do |f|
      resources.flatten.each do |resource|
        f.puts(resource.as_json.to_json)
      end
    end
  end

  def create_audit_record(patient)
    {
      patient_id: patient.id,
      sri_lanka_personal_health_number: patient.business_identifiers.where(identifier_type: "sri_lanka_personal_health_number")&.first&.identifier,
      patient_bp_passport_number: patient.business_identifiers.where(identifier_type: "simple_bp_passport")&.first&.identifier,
      patient_name: patient.full_name,
      patient_gender: patient.gender,
      patient_date_of_birth: patient.date_of_birth || patient.age_updated_at - patient.age.years,
      patient_address: patient.address.street_address,
      patient_telephone: patient.phone_numbers.pluck(:number).join(";"),
      patient_facility: OPENSRP_ORG_MAP[patient.assigned_facility_id][:name],
      patient_preferred_language: "Sinhala",
      patient_active: patient.status_active?,
      patient_deceased: patient.status_dead?,
      condition: ("HTN" if patient.medical_history.hypertension_yes?) || ("DM" if patient.medical_history.diabetes_yes?),
      blood_pressure: patient.latest_blood_pressure&.values_at(:systolic, :diastolic)&.join("/"),
      bmi: nil,
      appointment_date: patient.appointments.order(device_updated_at: :desc).where(status: "scheduled")&.first&.device_updated_at&.to_date&.iso8601,
      medication: patient.prescription_drugs.order(device_updated_at: :desc).where(is_deleted: false)&.first&.values_at(:name, :dosage)&.join(" "),
      glucose_measure: patient.latest_blood_sugar&.blood_sugar_value.then { |bs| "%.2f" % bs if bs },
      glucose_measure_type: patient.latest_blood_sugar&.blood_sugar_type
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
