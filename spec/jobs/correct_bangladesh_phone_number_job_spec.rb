require 'rails_helper'

RSpec.describe CorrectBangladeshPhoneNumberJob, type: :job do
  describe '#perform' do
    let(:patient) { double }

    it 'invokes the CorrectBangladeshPhoneNumber service' do
      expect(CorrectBangladeshPhoneNumber).to receive(:perform).with(patient)

      described_class.perform_now(patient)
    end
  end
end
