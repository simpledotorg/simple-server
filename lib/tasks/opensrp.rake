require "faker"

namespace :opensrp do
  desc "Export simple patient-related data as opensrp fhir resources"
  task :export, [:file_path] => :environment do |_task, args|
    patients = Patient.order(:created_at).take 5
    patients = remove_pii(patients)
    file_path = args[:file_path]

    resources = []
    encounters = []
    patients.each do |patient|
      resources << OneOff::Opensrp::PatientExporter.new(patient).export
      patient.blood_pressures.each do |bp|
        bp_exporter = OneOff::Opensrp::BloodPressureExporter.new(bp)
        resources << bp_exporter.export
        encounters << bp_exporter.export_encounter
      end
      patient.blood_sugars.each do |bs|
        bs_exporter = OneOff::Opensrp::BloodSugarExporter.new(bs)
        resources << bs_exporter.export
        encounters << bs_exporter.export_encounter
      end
      patient.prescription_drugs.each do |drug|
        drug_exporter = OneOff::Opensrp::PrescriptionDrugExporter.new(drug)
        resources << drug_exporter.export_medication
        resources << drug_exporter.export
        encounters << drug_exporter.export_encounter
      end
      OneOff::Opensrp::MedicalHistoryExporter.new(patient.medical_history).then do |medical_history_exporter|
        resources << medical_history_exporter.export
        encounters << medical_history_exporter.export_encounter
      end
      patient.appointments.each do |appointment|
        next unless appointment.status_scheduled?
        appointment_exporter = OneOff::Opensrp::AppointmentExporter.new(appointment)
        resources << appointment_exporter.export
        encounters << appointment_exporter.export_encounter
      end
      resources << OneOff::Opensrp::EncounterGenerator.new(encounters).export_deduplicated
    end

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
