require "rails_helper"

describe Communication, type: :model do
  context "Associations" do
    it { should belong_to(:user).optional }
    it { should belong_to(:appointment) }
    it { should belong_to(:detailable).optional }
  end

  context "Validations" do
    it_behaves_like "a record that validates device timestamps"
  end

  context "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  describe ".create_with_twilio_details!" do
    let(:appointment) { create(:appointment) }

    it "creates a communication with a TwilioSmsDeliveryDetail" do
      expect {
        Communication.create_with_twilio_details!(appointment: appointment,
                                                  twilio_sid: SecureRandom.uuid,
                                                  twilio_msg_status: "sent",
                                                  communication_type: :missed_visit_sms_reminder)
      }.to change { Communication.count }.by(1)
        .and change { TwilioSmsDeliveryDetail.count }.by(1)
    end
  end

  describe ".communication_result" do
    it "is successful is detailable is successful" do
      communication = create(:communication,
        :missed_visit_sms_reminder,
        detailable: create(:twilio_sms_delivery_detail, :delivered))

      expect(communication.communication_result).to eq("successful")
    end

    it "is successful if detailable is unsuccessful" do
      communication = create(:communication,
        :missed_visit_sms_reminder,
        detailable: create(:twilio_sms_delivery_detail, :failed))

      expect(communication.communication_result).to eq("unsuccessful")
    end

    it "is in_progress if detailable is in_progress" do
      communication_1 = create(:communication,
        :missed_visit_sms_reminder,
        detailable: create(:twilio_sms_delivery_detail, :queued))
      communication_2 = create(:communication,
        :missed_visit_sms_reminder,
        detailable: create(:twilio_sms_delivery_detail, :sent))

      expect(communication_1.communication_result).to eq("in_progress")
      expect(communication_2.communication_result).to eq("in_progress")
    end
  end

  context "anonymised data for communications" do
    describe "anonymized_data" do
      it "correctly retrieves the anonymised data for the communication" do
        communication = create(:communication,
          :missed_visit_sms_reminder,
          detailable: create(:twilio_sms_delivery_detail, :sent))

        anonymised_data =
          {id: hash_uuid(communication.id),
           appointment_id: hash_uuid(communication.appointment_id),
           patient_id: hash_uuid(communication.appointment.patient_id),
           user_id: hash_uuid(communication.user_id),
           created_at: communication.created_at,
           communication_type: communication.communication_type,
           communication_result: communication.communication_result}

        expect(communication.anonymized_data).to eq anonymised_data
      end
    end
  end
end
