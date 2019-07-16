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

  describe '.require_whitelisting' do

  end

  describe 'can_be_called?' do
    let(:patient) { create(:patient) }

    context 'phone number DND status is false' do
      let(:phone_number) { create(:patient_phone_number, patient: patient, dnd_status: false) }

      it 'returns true' do
        expect(phone_number.can_be_called?).to eq(true)
      end
    end

    context 'phone number DND status is true and exotel whitelist status is whitelisted and whitelist is not expired' do
      let(:phone_number) { create(:patient_phone_number, patient: patient, dnd_status: true) }
      let!(:exotel_phone_number_details) { create(:exotel_phone_number_detail,
                                                 patient_phone_number: phone_number,
                                                 whitelist_status: :whitelist,
                                                 whitelist_status_valid_until: 1.month.from_now) }

      it 'returns true' do
        expect(phone_number.can_be_called?).to eq(true)
      end
    end

    context 'phone number DND status is true and exotel whitelist status is whitelisted and whitelist is expired' do
      let(:phone_number) { create(:patient_phone_number, patient: patient, dnd_status: true) }
      let!(:exotel_phone_number_details) { create(:exotel_phone_number_detail,
                                                 patient_phone_number: phone_number,
                                                 whitelist_status: :whitelist,
                                                 whitelist_status_valid_until: 1.month.ago) }

      it 'returns false' do
        expect(phone_number.can_be_called?).to eq(false)
      end
    end


    context 'phone number DND status is true and exotel whitelist status is neutral' do
      let(:phone_number) { create(:patient_phone_number, patient: patient, dnd_status: true) }
      let!(:exotel_phone_number_details) { create(:exotel_phone_number_detail, patient_phone_number: phone_number, whitelist_status: :neutral) }

      it 'returns false' do
        expect(phone_number.can_be_called?).to eq(false)
      end
    end


    context 'phone number DND status is true and exotel whitelist status is blacklisted' do
      let(:phone_number) { create(:patient_phone_number, patient: patient, dnd_status: true) }
      let!(:exotel_phone_number_details) { create(:exotel_phone_number_detail, patient_phone_number: phone_number, whitelist_status: :blacklist) }

      it 'returns false' do
        expect(phone_number.can_be_called?).to eq(false)
      end
    end
  end
end
