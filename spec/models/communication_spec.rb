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
                                                  twilio_sid: SecureRandom.uuid,
                                                  twilio_msg_status: 'sent',
                                                  communication_type: :follow_up_reminder)
      }.to change { Communication.count }.by(1)
             .and change { TwilioSmsDeliveryDetail.count }.by(1)
    end

    it 'does not create a TwilioSmsDeliveryDetail if Communication fails to save' do
      user_not_present = nil

      expect {
        Communication.create_with_twilio_details!(user: user_not_present,
                                                  appointment: appointment,
                                                  twilio_sid: SecureRandom.uuid,
                                                  twilio_msg_status: 'sent',
                                                  communication_type: :follow_up_reminder)
      }.to raise_error(StandardError)
             .and change { Communication.count }.by(0)
                    .and change { TwilioSmsDeliveryDetail.count }.by(0)
    end
  end

  describe '.communication_result' do
    it 'returns successful is detailable is successful' do
      communication = create(:communication,
                             :follow_up_reminder,
                             detailable: create(:twilio_sms_delivery_detail, :delivered))

      expect(communication.communication_result).to eq('successful')
    end

    it 'returns successful is detailable is unsuccessful' do
      communication = create(:communication,
                             :follow_up_reminder,
                             detailable: create(:twilio_sms_delivery_detail, :failed))

      expect(communication.communication_result).to eq('unsuccessful')

    end

    it 'returns in_progress is detailable is in_progress' do
      communication = create(:communication,
                             :follow_up_reminder,
                             detailable: create(:twilio_sms_delivery_detail, :queued))

      expect(communication.communication_result).to eq('in_progress')

    end
  end
end
