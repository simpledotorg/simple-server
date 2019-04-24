require 'rails_helper'

describe Communication, type: :model do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:appointment) }
    it { should belong_to(:detailable) }
  end

  describe 'Validations' do
    it_behaves_like 'a record that validates device timestamps'
  end

  describe 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end

  describe '.create_with_twilio_details!' do
    let(:user) { create(:user) }
    let(:appointment) { create(:appointment) }

    it 'creates a communication with a TwilioSmsDeliveryDetail' do
      expect {
        Communication.create_with_twilio_details!(user: user,
                                                  appointment: appointment,
                                                  twilio_session_id: SecureRandom.uuid,
                                                  twilio_msg_status: 'sent')
      }.to change { Communication.count }.by(1)
             .and change { TwilioSmsDeliveryDetail.count }.by(1)
    end

    it 'does not create a TwilioSmsDeliveryDetail if Communication fails to save' do
      expect {
        Communication.create_with_twilio_details!(user: nil,
                                                  appointment: appointment,
                                                  twilio_session_id: SecureRandom.uuid,
                                                  twilio_msg_status: 'sent')
      }.to raise_error(StandardError)
             .and change { Communication.count }.by(0)
                    .and change { TwilioSmsDeliveryDetail.count }.by(0)
    end
  end
end
