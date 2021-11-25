require "rails_helper"

RSpec.describe Reports::Prescription, {type: :model, reporting_spec: true} do
  describe "Associations" do
    it { should belong_to(:patient) }
  end

  around do |example|
    Timecop.freeze("June 30 2021 5:30 UTC") do
      # June 30th 23:00 IST time
      example.run
    end
  end

  context "Cleanup" do
    describe "Converts raw medicines to clean medicines as expected" do
      it "works" do
        DrugLookup::RawToCleanMedicine.create({raw_name: "Amlo", raw_dosage: "5mg", rxcui: 123})
        DrugLookup::RawToCleanMedicine.create({raw_name: "Amlo", raw_dosage: "5 OD", rxcui: 123})
        DrugLookup::RawToCleanMedicine.create({raw_name: "Aml", raw_dosage: "5mg", rxcui: 123})

        DrugLookup::CleanMedicineToDosage.create({medicine: "Amlodipine", dosage: 5, rxcui: 123})
        DrugLookup::MedicinePurpose.create(name: "Amlodipine", hypertension: true, diabetes: false)

        patient = create(:patient, recorded_at: june_2021[:over_12_months_ago])
        create(:prescription_drug,
          patient: patient,
          facility: patient.registration_facility,
          device_created_at: june_2021[:under_3_months_ago],
          device_updated_at: june_2021[:under_3_months_ago],
          name: "Amlo",
          dosage: "5mg")

        described_class.refresh

        expect(described_class.find_by(patient: patient, month_date: june_2021[:under_3_months_ago]).amlodipine).to eq 5
      end
    end
  end
end
