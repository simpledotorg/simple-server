require "rails_helper"
require "./spec/support/twilio_sms_delivery_helper"

RSpec.configure do |c|
  c.include TwilioSMSDeliveryHelper
end

RSpec.describe Api::V3::TwilioSmsDeliveryController, type: :controller do
  describe "#create" do
    let(:callback_url) { api_v3_twilio_sms_delivery_url(host: request.host) }
    let(:base_session_id) { SecureRandom.uuid }
    let(:base_callback_params) do
      {"SmsSid" => base_session_id,
       "SmsStatus" => "delivered",
       "MessageSid" => base_session_id,
       "MessageStatus" => "delivered",
       "To" => Faker::PhoneNumber.phone_number,
       "AccountSid" => SecureRandom.uuid,
       "From" => "+15005550006",
       "ApiVersion" => "2010-04-01"}
    end

    context ":ok" do
      it "returns success when twilio signature is valid" do
        session_id = SecureRandom.uuid
        create(:twilio_sms_delivery_detail,
          session_id: session_id,
          result: "queued")
        params = base_callback_params.merge("MessageSid" => session_id)
        set_twilio_signature_header(callback_url, params)
        post :create, params: params

        expect(response).to have_http_status(200)
      end

      context "TwilioSmsDeliveryDetail" do
        it "updates the result for SmsSid and SmsStatus" do
          session_id = SecureRandom.uuid
          create(:twilio_sms_delivery_detail,
            session_id: session_id,
            result: "queued")
          params = base_callback_params.except("MessageSid", "MessageStatus")
            .merge("SmsSid" => session_id, "SmsStatus" => "sent")

          set_twilio_signature_header(callback_url, params)
          post :create, params: params

          twilio_sms_delivery_detail = TwilioSmsDeliveryDetail.find_by_session_id(session_id)
          expect(twilio_sms_delivery_detail.result).to eq("sent")
        end

        it "updates the result for MessageSid and MessageStatus" do
          session_id = SecureRandom.uuid
          create(:twilio_sms_delivery_detail,
            session_id: session_id,
            result: "queued")
          params = base_callback_params.merge("MessageSid" => session_id,
            "MessageStatus" => "sent")

          set_twilio_signature_header(callback_url, params)
          post :create, params: params

          twilio_sms_delivery_detail = TwilioSmsDeliveryDetail.find_by_session_id(session_id)
          expect(twilio_sms_delivery_detail.result).to eq("sent")
        end

        it "updates the result and delivered_on" do
          expect(Statsd.instance).to receive(:increment).with("twilio_callback.manual_call.delivered")
          session_id = SecureRandom.uuid
          twilio_sms_delivery_detail = create(:twilio_sms_delivery_detail,
            session_id: session_id,
            result: "sent")
          params = base_callback_params.merge("MessageSid" => session_id,
            "MessageStatus" => "delivered")

          set_twilio_signature_header(callback_url, params)
          post :create, params: params

          twilio_sms_delivery_detail.reload
          expect(twilio_sms_delivery_detail.result).to eq("delivered")
          expect(twilio_sms_delivery_detail.delivered_on).to_not be_nil
        end

        it "does not update delivered_on if status is not delivered" do
          session_id = SecureRandom.uuid
          twilio_sms_delivery_detail = create(:twilio_sms_delivery_detail, session_id: session_id, result: "queued")

          params = base_callback_params.merge(
            "MessageSid" => session_id,
            "MessageStatus" => "sent"
          )

          set_twilio_signature_header(callback_url, params)
          post :create, params: params

          expect(twilio_sms_delivery_detail.reload.delivered_on).to be_nil
        end

        it "updates the result and read_at when result is 'read'" do
          expect(Statsd.instance).to receive(:increment).with("twilio_callback.manual_call.read")
          session_id = SecureRandom.uuid
          twilio_sms_delivery_detail = create(:twilio_sms_delivery_detail,
            session_id: session_id,
            result: "queued")
          params = base_callback_params.merge("MessageSid" => session_id,
            "MessageStatus" => "read")

          set_twilio_signature_header(callback_url, params)
          post :create, params: params

          twilio_sms_delivery_detail.reload
          expect(twilio_sms_delivery_detail.result).to eq("read")
          expect(twilio_sms_delivery_detail.read_at).to_not be_nil
        end

        it "does not update read_at if status is not 'read'" do
          session_id = SecureRandom.uuid
          twilio_sms_delivery_detail = create(:twilio_sms_delivery_detail, session_id: session_id, result: "queued")

          params = base_callback_params.merge(
            "MessageSid" => session_id,
            "MessageStatus" => "sent"
          )

          set_twilio_signature_header(callback_url, params)
          post :create, params: params

          expect(twilio_sms_delivery_detail.reload.read_at).to be_nil
        end

        it "logs failure and does not queue a retry when there is no next communication type" do
          session_id = SecureRandom.uuid
          notification = create(:notification)
          create(:communication, :whatsapp, notification: notification)
          communication = create(:communication, :sms, notification: notification)
          create(:twilio_sms_delivery_detail, session_id: session_id, result: "queued", communication: communication)

          params = base_callback_params.merge(
            "MessageSid" => session_id,
            "MessageStatus" => "failed"
          )
          set_twilio_signature_header(callback_url, params)

          expect(AppointmentNotification::Worker).not_to receive(:perform_at)
          expect(Statsd.instance).to receive(:increment).with("twilio_callback.sms.failed")

          post :create, params: params
        end

        it "logs failure if the attempt failed, doesn't schedule a fallback message" do
          session_id = SecureRandom.uuid
          notification = create(:notification)
          communication = create(:communication, :whatsapp, notification: notification)
          create(:twilio_sms_delivery_detail, session_id: session_id, result: "queued", communication: communication)

          params = base_callback_params.merge(
            "MessageSid" => session_id,
            "MessageStatus" => "failed"
          )
          set_twilio_signature_header(callback_url, params)

          expect(AppointmentNotification::Worker).not_to receive(:perform_at)
          expect(Statsd.instance).to receive(:increment).with("twilio_callback.whatsapp.failed")

          post :create, params: params
        end

        context "For communication with no appointment" do
          it "logs failure if the attempt failed, doesn't schedule a fallback message" do
            twilio_client = double("TwilioClientDouble")
            twilio_response = double("TwilioClientResponseDouble")
            allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
            allow(twilio_client).to receive_message_chain("messages.create").and_return(twilio_response)
            allow(twilio_response).to receive(:sid).and_return(nil)
            allow(twilio_response).to receive(:status).and_return(nil)

            session_id = SecureRandom.uuid
            notification = create(:notification, message: "notifications.covid.medication_reminder", purpose: "covid_medication_reminder")
            communication = create(:communication, :whatsapp, notification: notification)
            create(:twilio_sms_delivery_detail, session_id: session_id, result: "queued", communication: communication)
            enable_flag(:experiment)

            params = base_callback_params.merge(
              "MessageSid" => session_id,
              "MessageStatus" => "failed"
            )
            set_twilio_signature_header(callback_url, params)
            expect(AppointmentNotification::Worker).not_to receive(:perform_at)
            expect(Statsd.instance).to receive(:increment).with("twilio_callback.whatsapp.failed")

            post :create, params: params
          end
        end
      end
    end

    context ":forbidden" do
      it "returns 403 when the twilio signature is invalid" do
        sig_with_invalid_params = {}
        set_twilio_signature_header(callback_url, sig_with_invalid_params)
        post :create, params: base_callback_params

        expect(response).to have_http_status(403)
        expect(TwilioSmsDeliveryDetail.count).to be(0)
      end
    end

    context ":not_found" do
      it "returns 404 when twilio detail is not found" do
        set_twilio_signature_header(callback_url, base_callback_params)
        post :create, params: base_callback_params
        expect(response).to have_http_status(404)
      end
    end
  end
end
