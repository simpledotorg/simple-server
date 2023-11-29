require "faker"

namespace :fhir do
  desc "Export simple patient-related data as fhir resources"
  task :export, [:file_path] => :environment do |_task, args|
    patients = Patient.order(:created_at).last(10)
    patients = remove_pii(patients)
    patients = clean_up_drug_names(patients)
    file_path = args[:file_path]
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

    File.open(file_path, "w+") do |f|
      resources.flatten.each do |resource|
        f.puts(resource.as_json.to_json)
      end
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
      address.country = "Sri Lanka"
      patient.phone_numbers.each do |phone_number|
        phone_number.number = Faker::PhoneNumber.phone_number
      end
    end
  end

  def clean_up_drug_names(patients)
    clean_drug_names = %w[Amlodipine Atenolol Captopril Chlorthalidone Enalapril Hydrochlorothiazide Losartan Metoprolol Spironolactone Telmisartan Lisinopril]
    patients.each do |patient|
      patient.prescription_drugs.each do |drug|
        drug.name = clean_drug_names.sample
        print "drug name is #{drug.name}"
      end
    end
  end
end
