require "faker"

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
    patients = remove_pii(patients)
    file_path = args[:file_path]

    opensrp_org_map = {
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

    resources = []
    encounters = []
    patients.each do |patient|
      resources << OneOff::Opensrp::PatientExporter.new(patient, opensrp_org_map).export
      encounters << OneOff::Opensrp::PatientExporter.new(patient, opensrp_org_map).export_registration_encounter
      patient.blood_pressures.each do |bp|
        bp_exporter = OneOff::Opensrp::BloodPressureExporter.new(bp, opensrp_org_map)
        resources << bp_exporter.export
        encounters << bp_exporter.export_encounter
      end
      patient.blood_sugars.each do |bs|
        bs_exporter = OneOff::Opensrp::BloodSugarExporter.new(bs, opensrp_org_map)
        resources << bs_exporter.export
        encounters << bs_exporter.export_encounter
      end
      patient.prescription_drugs.each do |drug|
        drug_exporter = OneOff::Opensrp::PrescriptionDrugExporter.new(drug, opensrp_org_map)
        resources << drug_exporter.export_medication
        resources << drug_exporter.export
        encounters << drug_exporter.export_encounter
      end
      OneOff::Opensrp::MedicalHistoryExporter.new(patient.medical_history, opensrp_org_map).then do |medical_history_exporter|
        resources << medical_history_exporter.export
        encounters << medical_history_exporter.export_encounter
      end
      patient.appointments.each do |appointment|
        next unless appointment.status_scheduled?
        appointment_exporter = OneOff::Opensrp::AppointmentExporter.new(appointment, opensrp_org_map)
        resources << appointment_exporter.export
        encounters << appointment_exporter.export_encounter
      end
    end
    resources << OneOff::Opensrp::EncounterGenerator.new(encounters).generate

    File.open(file_path, "w+") do |f|
      resources.flatten.each do |resource|
        f.puts(resource.as_json.to_json)
      end
    end
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
