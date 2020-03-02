require 'rails_helper'

describe CorrectBangladeshPhoneNumber do
  describe '.perform' do
    let(:patient) { double }
    let(:corrector) { double }

    before { allow(described_class).to receive(:new).with(patient).and_return(corrector) }

    it 'invokes perform on an instance' do
      expect(corrector).to receive(:perform)

      described_class.perform(patient)
    end
  end

  describe '#perform' do
    let(:patient) { create(:patient, phone_numbers: []) }
    let!(:phone_number) { create(:patient_phone_number, active: true, number: number, patient: patient) }

    subject(:corrector) { described_class.new(patient) }

    # Refresh associations
    before { patient.reload }

    context 'when phone number does not start with a leading zero' do
      let(:number) { '1234567890' }

      it 'adds a leading zero' do
        corrector.perform
        expect(phone_number.reload.number).to eq('01234567890')
      end
    end

    context 'when phone number contains dashes' do
      let(:number) { '01234-56789' }

      it 'adds a leading zero' do
        corrector.perform
        expect(phone_number.reload.number).to eq('0123456789')
      end
    end

    context 'when patient has multiple phone numbers' do
      let(:number) { '011111-11111' }
      let(:another_number) { '2222222222' }
      let!(:another_phone_number) do
        create(:patient_phone_number, active: true, number: another_number, patient: patient)
      end

      it 'corrects both numbers' do
        corrector.perform
        expect(phone_number.reload.number).to eq('01111111111')
        expect(another_phone_number.reload.number).to eq('02222222222')
      end
    end
  end
end
