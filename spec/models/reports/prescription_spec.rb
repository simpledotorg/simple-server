# frozen_string_literal: true

require "rails_helper"

# Shorthand for adding prescription drugs, since we do it a lot in this spec
def add_drug(patient, name, dosage, time, do_not_delete: false)
  # emulate deletion of existing drug like on mobile app
  unless do_not_delete
    patient.prescription_drugs
      .where(name: name, is_deleted: false)
      .update(is_deleted: true, device_updated_at: time)
  end

  # create new drug
  FactoryBot.create(:prescription_drug,
    patient: patient,
    facility: patient.registration_facility,
    device_created_at: time,
    device_updated_at: time,
    name: name,
    dosage: dosage)
end

RSpec.describe Reports::Prescription, {type: :model, reporting_spec: true} do
  describe "Associations" do
    it { should belong_to(:patient) }
  end

  around do |example|
    freeze_time_for_reporting_specs(example)
  end

  describe "Cleanup and mapping" do
    it "cleans up drug names using lookup tables" do
      DrugLookup::MedicinePurpose.create(name: "Amlodipine", hypertension: true, diabetes: false)
      DrugLookup::RawToCleanMedicine.create({raw_name: "Amlo", raw_dosage: "5mg", rxcui: 123})
      DrugLookup::CleanMedicineToDosage.create({medicine: "Amlodipine", dosage: 5, rxcui: 123})

      patient = FactoryBot.create(:patient, recorded_at: june_2021[:over_12_months_ago])
      add_drug(patient, "Amlo", "5mg", june_2021[:under_3_months_ago])

      described_class.refresh
      expect(described_class.find_by(patient: patient, month_date: june_2021[:under_3_months_ago]).amlodipine).to eq 5
    end

    it "cleans up drug dosages using lookup tables" do
      DrugLookup::MedicinePurpose.create(name: "Telmisartan", hypertension: true, diabetes: false)
      DrugLookup::RawToCleanMedicine.create({raw_name: "Telmi", raw_dosage: "40 OD", rxcui: 123})
      DrugLookup::CleanMedicineToDosage.create({medicine: "Telmisartan", dosage: 40, rxcui: 123})

      patient = FactoryBot.create(:patient, recorded_at: june_2021[:over_12_months_ago])
      add_drug(patient, "Tel mi", "40od", june_2021[:under_3_months_ago])

      described_class.refresh
      expect(described_class.find_by(patient: patient, month_date: june_2021[:under_3_months_ago]).telmisartan).to eq 40
    end

    it "works correctly for combination medicines" do
      DrugLookup::RawToCleanMedicine.create({raw_name: "Los-H", raw_dosage: "125mg", rxcui: 111})

      DrugLookup::MedicinePurpose.create(name: "Losartan Potassium", hypertension: true, diabetes: false)
      DrugLookup::CleanMedicineToDosage.create({medicine: "Losartan Potassium", dosage: 100, rxcui: 111})

      DrugLookup::MedicinePurpose.create(name: "Hydrochlorothiazide", hypertension: true, diabetes: false)
      DrugLookup::CleanMedicineToDosage.create({medicine: "Hydrochlorothiazide", dosage: 25, rxcui: 111})

      patient = FactoryBot.create(:patient, recorded_at: june_2021[:over_12_months_ago])
      add_drug(patient, "Los-H", "125mg", june_2021[:under_3_months_ago])

      described_class.refresh
      expect(described_class.find_by(patient: patient, month_date: june_2021[:under_3_months_ago]).losartan).to eq 100
      expect(described_class.find_by(patient: patient, month_date: june_2021[:under_3_months_ago]).hydrochlorothiazide).to eq 25
    end
  end

  describe "Timeline" do
    it "picks up the latest dosage of drugs if there are more with the same name" do
      DrugLookup::MedicinePurpose.create(name: "Amlodipine", hypertension: true, diabetes: false)
      DrugLookup::RawToCleanMedicine.create({raw_name: "Amlo", raw_dosage: "5mg", rxcui: 111})
      DrugLookup::CleanMedicineToDosage.create({medicine: "Amlodipine", dosage: 5, rxcui: 111})

      DrugLookup::RawToCleanMedicine.create({raw_name: "Amlo", raw_dosage: "10mg", rxcui: 222})
      DrugLookup::CleanMedicineToDosage.create({medicine: "Amlodipine", dosage: 10, rxcui: 222})

      patient = FactoryBot.create(:patient, recorded_at: june_2021[:twelve_months_ago])
      add_drug(patient, "Amlo", "5mg", june_2021[:ten_months_ago])
      add_drug(patient, "Amlo", "10mg", june_2021[:ten_months_ago] + 1.minute, do_not_delete: true)

      described_class.refresh

      expect(described_class.find_by(patient: patient, month_date: june_2021[:ten_months_ago]).amlodipine).to eq 10
    end

    it "creates a correct timeline of medications the patient has been on every month" do
      with_reporting_time_zone do
        DrugLookup::MedicinePurpose.create(name: "Amlodipine", hypertension: true, diabetes: false)
        DrugLookup::MedicinePurpose.create(name: "Captopril", hypertension: true, diabetes: false)
        DrugLookup::MedicinePurpose.create(name: "Telmisartan", hypertension: true, diabetes: false)

        DrugLookup::RawToCleanMedicine.create({raw_name: "Amlo", raw_dosage: "5mg", rxcui: 111})
        DrugLookup::CleanMedicineToDosage.create({medicine: "Amlodipine", dosage: 5, rxcui: 111})

        DrugLookup::RawToCleanMedicine.create({raw_name: "Amlo", raw_dosage: "10mg", rxcui: 222})
        DrugLookup::CleanMedicineToDosage.create({medicine: "Amlodipine", dosage: 10, rxcui: 222})

        DrugLookup::RawToCleanMedicine.create({raw_name: "Telmi", raw_dosage: "40mg", rxcui: 333})
        DrugLookup::CleanMedicineToDosage.create({medicine: "Telmisartan", dosage: 40, rxcui: 333})

        DrugLookup::RawToCleanMedicine.create({raw_name: "Telmi", raw_dosage: "80mg", rxcui: 444})
        DrugLookup::CleanMedicineToDosage.create({medicine: "Telmisartan", dosage: 80, rxcui: 444})

        DrugLookup::RawToCleanMedicine.create({raw_name: "Capto", raw_dosage: "10mg", rxcui: 555})
        DrugLookup::CleanMedicineToDosage.create({medicine: "Captopril", dosage: 10, rxcui: 555})

        patient = FactoryBot.create(:patient, recorded_at: june_2021[:two_years_ago])
        add_drug(patient, "Amlo", "5mg", june_2021[:ten_months_ago])
        add_drug(patient, "Amlo", "5mg", june_2021[:nine_months_ago])
        add_drug(patient, "Amlo", "10mg", june_2021[:eight_months_ago])
        add_drug(patient, "Amlo", "10mg", june_2021[:seven_months_ago])
        # does not visit for 2 months
        add_drug(patient, "Telmi", "40mg", june_2021[:four_months_ago])

        add_drug(patient, "Amlo", "10mg", june_2021[:three_months_ago])
        add_drug(patient, "Telmi", "40mg", june_2021[:three_months_ago])
        # does not visit for 1 month
        add_drug(patient, "Telmi", "80mg", june_2021[:one_month_ago])
        add_drug(patient, "Capto", "10mg", june_2021[:one_month_ago])

        described_class.refresh

        expect(described_class.find_by(patient: patient, month_date: june_2021[:eleven_months_ago]).amlodipine).to eq(0)
        expect(described_class.find_by(patient: patient, month_date: june_2021[:eleven_months_ago]).telmisartan).to eq(0)

        expect(described_class.find_by(patient: patient, month_date: june_2021[:ten_months_ago]).amlodipine).to eq(5)
        expect(described_class.find_by(patient: patient, month_date: june_2021[:nine_months_ago]).amlodipine).to eq(5)
        expect(described_class.find_by(patient: patient, month_date: june_2021[:eight_months_ago]).amlodipine).to eq(10)
        expect(described_class.find_by(patient: patient, month_date: june_2021[:seven_months_ago]).amlodipine).to eq(10)
        expect(described_class.find_by(patient: patient, month_date: june_2021[:six_months_ago]).amlodipine).to eq(10)
        expect(described_class.find_by(patient: patient, month_date: june_2021[:five_months_ago]).amlodipine).to eq(10)

        expect(described_class.find_by(patient: patient, month_date: june_2021[:four_months_ago]).amlodipine).to eq(10)
        expect(described_class.find_by(patient: patient, month_date: june_2021[:four_months_ago]).telmisartan).to eq(40)

        expect(described_class.find_by(patient: patient, month_date: june_2021[:three_months_ago]).amlodipine).to eq(10)
        expect(described_class.find_by(patient: patient, month_date: june_2021[:three_months_ago]).telmisartan).to eq(40)

        expect(described_class.find_by(patient: patient, month_date: june_2021[:two_months_ago]).amlodipine).to eq(10)
        expect(described_class.find_by(patient: patient, month_date: june_2021[:two_months_ago]).telmisartan).to eq(40)

        expect(described_class.find_by(patient: patient, month_date: june_2021[:one_month_ago]).other_bp_medications).to eq(10)
        expect(described_class.find_by(patient: patient, month_date: june_2021[:one_month_ago]).amlodipine).to eq(10)
        expect(described_class.find_by(patient: patient, month_date: june_2021[:one_month_ago]).telmisartan).to eq(80)
      end
    end
  end
end
