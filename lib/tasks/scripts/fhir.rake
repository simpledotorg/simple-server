require "faker"

namespace :fhir do
  desc "Export simple patient-related data as fhir resources"
  task export: :environment do
    patients = Patient.last(3)
    patients = remove_pii(patients)
    file_path = "app/services/one_off/fhir/sample_exports_LK/sample_fhir_export.json"
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
      File.open(file_path, "w+") do |f|
        f.puts(resources.flatten)
      end
    end
  end

  def remove_pii(patients)
    patients.each do |patient|
      patient.update!(full_name: Faker::Name.name)
      patient.address.update!(
        street_address: Faker::Address.street_address,
        district: Faker::Address.district,
        state: Faker::Address.state,
        pin: Faker::Address.zip
      )
    end
  end
end
