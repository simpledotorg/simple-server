require "faker"

namespace :fhir do
  desc "Export simple patient-related data as fhir resources"
  task export: :environment do
    patients = Patient.last(3)
    patients = remove_pii(patients)
    file_path = "app/services/one_off/fhir/sample_exports/sample_fhir_export.json"
    resources = []

    patients.each do |patient|
      resources << OneOff::Fhir::PatientExporter.new(patient).export
      resources << patient.blood_pressures.map { |bp|
        OneOff::Fhir::BloodPressureExporter.new(bp).export
      }
      resources << patient.blood_sugars.map { |bs|
        OneOff::Fhir::BloodSugarExporter.new(bs).export
      }
      resources << patient.prescription_drugs.map { |drug|
        OneOff::Fhir::PrescriptionDrugExporter.new(drug).export
      }
      resources << OneOff::Fhir::MedicalHistoryExporter.new(patient.medical_history).export
      resources << patient.appointments.map { |appointment|
        OneOff::Fhir::AppointmentExporter.new(appointment).export
      }
    end

    resources = resources.flatten.map(&:as_json.to_json)
    File.open(file_path, "w") do |f|
      f.puts(resources)
    end
  end

  def remove_pii(patients)
    patients.each do |patient|
      patient.full_name = Faker::Name.name
      address = patient.address
      address.street_address = Faker::Address.street_address
      address.district = Faker::Address.district
      address.state = Faker::Address.state
      address.pin = Faker::Address.zip
      patient.phone_numbers.each do |phone_number|
        phone_number.number = Faker::PhoneNumber
      end
    end
  end
end
