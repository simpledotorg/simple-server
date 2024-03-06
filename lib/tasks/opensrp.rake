require "faker"

namespace :opensrp do
  desc "Export simple patient-related data as opensrp fhir resources"
  task :export, [:file_path] => :environment do |_task, args|
    patients = Patient.order(:created_at).take 20
    patients = remove_pii(patients)
    file_path = args[:file_path]
    resources = []

    patients.each do |patient|
      resources << OneOff::Opensrp::PatientExporter.new(patient).export
      resources << patient.blood_pressures.map do |bp|
        [OneOff::Opensrp::BloodPressureExporter.new(bp).export,
          OneOff::Opensrp::BloodPressureExporter.new(bp).export_encounter]
      end
      resources << patient.blood_sugars.map do |bs|
        [OneOff::Opensrp::BloodSugarExporter.new(bs).export,
          OneOff::Opensrp::BloodSugarExporter.new(bs).export_encounter]
      end
      resources << patient.prescription_drugs.map do |drug|
        [OneOff::Opensrp::PrescriptionDrugExporter.new(drug).export_medication,
          OneOff::Opensrp::PrescriptionDrugExporter.new(drug).export,
          OneOff::Opensrp::PrescriptionDrugExporter.new(drug).export_encounter]
      end
      resources << OneOff::Opensrp::MedicalHistoryExporter.new(patient.medical_history).export
      resources << patient.appointments.map do |appointment|
        next unless appointment.status_scheduled?
        [OneOff::Opensrp::AppointmentExporter.new(appointment).export,
          OneOff::Opensrp::AppointmentExporter.new(appointment).export_encounter]
      end
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
