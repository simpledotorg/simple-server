require 'rails_helper'
require 'tasks/scripts/correct_bangladesh_medication_dosages'

RSpec.describe CorrectBangladeshMedicationDosages do
  describe '#call' do
    it 'set zero-dose Amlodipine records to 5mg' do
      zero_amlo = create(:prescription_drug, name: 'Amlodipine', dosage: '0 mg')
      nonzero_amlo = create(:prescription_drug, name: 'Amlodipine', dosage: '10 mg')

      CorrectBangladeshMedicationDosages.call

      expect(zero_amlo.reload.dosage).to eq('5 mg')
      expect(nonzero_amlo.reload.dosage).to eq('10 mg')
    end

    it 'set zero-dose Losartan Potassium records to 50mg' do
      zero_losartan = create(:prescription_drug, name: 'Losartan Potassium', dosage: '0 mg')
      nonzero_losartan = create(:prescription_drug, name: 'Losartan Potassium', dosage: '100 mg')

      CorrectBangladeshMedicationDosages.call

      expect(zero_losartan.reload.dosage).to eq('50 mg')
      expect(nonzero_losartan.reload.dosage).to eq('100 mg')
    end

    it 'set zero-dose Hydrochlorothiazide records to 12.5mg' do
      zero_hct = create(:prescription_drug, name: 'Hydrochlorothiazide', dosage: '0 mg')
      nonzero_hct = create(:prescription_drug, name: 'Hydrochlorothiazide', dosage: '25 mg')

      CorrectBangladeshMedicationDosages.call

      expect(zero_hct.reload.dosage).to eq('12.5 mg')
      expect(nonzero_hct.reload.dosage).to eq('25 mg')
    end

    it 'leaves other zero-dose drugs alone' do
      zero_drug_1 = create(:prescription_drug, name: 'Donuts', dosage: '0 mg')
      zero_drug_2 = create(:prescription_drug, name: 'Flowers', dosage: '0 mg')

      CorrectBangladeshMedicationDosages.call

      expect(zero_drug_1.reload.dosage).to eq('0 mg')
      expect(zero_drug_2.reload.dosage).to eq('0 mg')
    end
  end
end
