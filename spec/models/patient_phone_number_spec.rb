require 'rails_helper'

RSpec.describe PatientPhoneNumber, type: :model do
  describe 'Associations' do
    it { should belong_to(:patient) }
  end

  describe 'Validations' do
    it_behaves_like 'a record that validates device timestamps'
  end

  describe 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end

  describe 'Default scope' do
    let!(:patient) { create(:patient, phone_numbers: []) }
    let!(:first_phone) { create(:patient_phone_number, patient: patient, device_created_at: 5.days.ago) }
    let!(:middle_phone) { create(:patient_phone_number, patient: patient, device_created_at: 2.days.ago) }
    let!(:last_phone) { create(:patient_phone_number, patient: patient, device_created_at: 1.day.ago) }

    describe '.first' do
      it "returns oldest device_created_at number" do
        expect(PatientPhoneNumber.first).to eq(first_phone)
      end
    end

    describe '.last' do
      it "returns newest device_created_at number" do
        expect(PatientPhoneNumber.last).to eq(last_phone)
      end
    end
  end
end
