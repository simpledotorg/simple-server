require "rails_helper"

describe Communication, type: :model do
  context "Associations" do
    it { should belong_to(:user).optional }
    it { should belong_to(:notification).optional }
    it { should belong_to(:detailable).optional }
    it { should belong_to(:appointment).optional }
  end

  context "Validations" do
    it_behaves_like "a record that validates device timestamps"
  end

  context "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  context "Utilities" do
    describe ".next_messaging_time" do
      before do
        @original_time_zone = Time.zone
        Time.zone = Rails.application.config.country[:time_zone]
        allow(Communication).to receive(:messaging_start_hour).and_return(10)
        allow(Communication).to receive(:messaging_end_hour).and_return(16)
      end

      after do
        Time.zone = @original_time_zone
      end

      it "returns the current time if currently within the messaging window" do
        Timecop.freeze(Time.zone.parse("January 1, 2020 12:00pm")) do
          expect(Communication.next_messaging_time).to eq(Time.zone.parse("January 1, 2020 12:00pm"))
        end
      end

      it "returns the next time today if currently before the messaging window" do
        Timecop.freeze(Time.zone.parse("January 1, 2020 9:00am")) do
          expect(Communication.next_messaging_time).to eq(Time.zone.parse("January 1, 2020 10:00am"))
        end
      end

      it "returns the next time tomorrow if currently after the messaging window" do
        Timecop.freeze(Time.zone.parse("January 1, 2020 4:30pm")) do
          expect(Communication.next_messaging_time).to eq(Time.zone.parse("January 2, 2020 10:00am"))
        end
      end

      it "returns the current time if send_notifications_immediately flag is enabled" do
        Flipper.enable(:disregard_messaging_window)
        now = "January 1, 2020 4:00am"
        Timecop.freeze(Time.zone.parse(now)) do
          expect(Communication.next_messaging_time).to eq(Time.zone.parse(now))
        end
      end
    end

    describe ".create_with_twilio_details!" do
      it "creates a communication with a TwilioSmsDeliveryDetail" do
        patient = create(:patient)
        appt = create(:appointment, patient: patient)
        notification = create(:notification, subject: appt, patient: patient)
        expect {
          Communication.create_with_twilio_details!(appointment: notification.subject,
            twilio_sid: SecureRandom.uuid,
            twilio_msg_status: "sent",
            communication_type: :sms,
            notification: notification)
        }.to change { Communication.count }.by(1)
          .and change { TwilioSmsDeliveryDetail.count }.by(1)
      end

      it "does not require an appointment" do
        notification = create(:notification)
        expect {
          Communication.create_with_twilio_details!(appointment: nil,
            twilio_sid: SecureRandom.uuid,
            twilio_msg_status: "sent",
            communication_type: :sms,
            notification: notification)
        }.to change { Communication.count }.by(1)
          .and change { TwilioSmsDeliveryDetail.count }.by(1)
      end
    end
  end

  describe ".create_with_imo_details" do
    it "creates a communication with correct details" do
      patient = create(:patient)
      appt = create(:appointment, patient: patient)
      notification = create(:notification, subject: appt, patient: patient)
      expect {
        Communication.create_with_imo_details!(notification: notification, result: :sent, post_id: "imo_post_id")
      }.to change { notification.communications.count }.by(1)
      communication = notification.communications.last
      expect(communication.communication_type).to eq("imo")
      expect(communication.appointment_id).to eq(appt.id)
    end

    it "updates the patient's imo_authorization when the imo response is 'no_imo_account'" do
      patient = create(:patient)
      _imo_auth = create(:imo_authorization, status: "subscribed", patient: patient)
      notification = create(:notification, patient: patient)
      expect {
        Communication.create_with_imo_details!(notification: notification, result: :no_imo_account, post_id: "imo_post_id")
      }.to change { patient.imo_authorization.reload.status }.from("subscribed").to("no_imo_account")
    end

    it "updates the patient's imo_authorization when the imo response is 'not_subscribed'" do
      patient = create(:patient)
      _imo_auth = create(:imo_authorization, status: "subscribed", patient: patient)
      notification = create(:notification, patient: patient)
      expect {
        Communication.create_with_imo_details!(notification: notification, result: :not_subscribed, post_id: "imo_post_id")
      }.to change { patient.imo_authorization.reload.status }.from("subscribed").to("not_subscribed")
    end

    it "does not update the patient's imo_authorization with other imo results" do
      patient = create(:patient)
      _imo_auth = create(:imo_authorization, status: "subscribed", patient: patient)
      notification = create(:notification, patient: patient)
      expect {
        Communication.create_with_imo_details!(notification: notification, result: :sent, post_id: "imo_post_id")
        Communication.create_with_imo_details!(notification: notification, result: :read, post_id: "imo_post_id")
      }.not_to change { patient.imo_authorization.reload.status }
    end
  end

  describe "#communication_result" do
    it "is successful is detailable is successful" do
      communication = create(:communication,
        :sms,
        detailable: create(:twilio_sms_delivery_detail, :delivered))

      expect(communication.communication_result).to eq("successful")
    end

    it "is successful if detailable is unsuccessful" do
      communication = create(:communication,
        :sms,
        detailable: create(:twilio_sms_delivery_detail, :failed))

      expect(communication.communication_result).to eq("unsuccessful")
    end

    it "is in_progress if detailable is in_progress" do
      communication_1 = create(:communication,
        :sms,
        detailable: create(:twilio_sms_delivery_detail, :queued))
      communication_2 = create(:communication,
        :sms,
        detailable: create(:twilio_sms_delivery_detail, :sent))

      expect(communication_1.communication_result).to eq("in_progress")
      expect(communication_2.communication_result).to eq("in_progress")
    end
  end

  context "anonymised data for communications" do
    describe "anonymized_data" do
      it "correctly retrieves the anonymised data for the communication" do
        create(:patient)
        communication = create(:communication,
          :sms,
          detailable: create(:twilio_sms_delivery_detail, :sent))

        anonymised_data =
          {id: Hashable.hash_uuid(communication.id),
           user_id: Hashable.hash_uuid(communication.user_id),
           created_at: communication.created_at,
           communication_type: communication.communication_type,
           communication_result: communication.communication_result}

        expect(communication.anonymized_data).to eq anonymised_data
      end
    end
  end
end
