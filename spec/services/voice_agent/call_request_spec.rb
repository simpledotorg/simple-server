require "rails_helper"

RSpec.describe VoiceAgent::CallRequest do
  let(:facility) { create(:facility) }
  let(:patient) { create(:patient, full_name: "Zulhas Mia", assigned_facility: facility) }
  let(:appointment) { create(:appointment, patient: patient, facility: facility, scheduled_date: Date.new(2026, 9, 14)) }
  let(:notification) do
    create(:notification, subject: appointment, patient: patient, purpose: "overdue_voice_call", status: "scheduled")
  end

  subject(:call_request) { described_class.new(notification) }

  describe "#call_request_id" do
    it "is a UUID that is stable for a notification, so retries are idempotent" do
      expect(call_request.call_request_id).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
      expect(described_class.new(notification).call_request_id).to eq(call_request.call_request_id)
    end

    it "does not expose patient, appointment or notification IDs" do
      expect([patient.id, appointment.id, notification.id]).not_to include(call_request.call_request_id)
    end
  end

  describe "#payload" do
    it "contains what the voice agent needs to place the call" do
      payload = call_request.payload

      expect(payload).to include(
        call_request_id: call_request.call_request_id,
        country: CountryConfig.current[:abbreviation],
        phone_number: patient.latest_mobile_number,
        language: facility.locale,
        patient_name: "Zulhas Mia",
        facility_name: facility.short_name,
        appointment_date: "2026-09-14",
        tries: 3,
        callback_url: "#{ENV["SIMPLE_SERVER_HOST_PROTOCOL"]}://#{ENV["SIMPLE_SERVER_HOST"]}/api/v4/voice_call_outcomes"
      )
    end

    it "does not include patient or appointment IDs" do
      values = call_request.payload.values.map(&:to_s)

      expect(values).not_to include(patient.id, appointment.id)
    end

    it "includes the calling window in the country's time zone" do
      expect(call_request.payload[:calling_window]).to eq(
        start: "10:00",
        end: "17:00",
        tz: CountryConfig.current[:time_zone]
      )
    end

    it "reads the calling window and tries from the environment" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("VOICE_AGENT_CALLING_WINDOW_START", anything).and_return("09:30")
      allow(ENV).to receive(:fetch).with("VOICE_AGENT_CALLING_WINDOW_END", anything).and_return("18:00")
      allow(ENV).to receive(:fetch).with("VOICE_AGENT_MAX_TRIES", anything).and_return("5")

      payload = call_request.payload

      expect(payload[:calling_window]).to include(start: "09:30", end: "18:00")
      expect(payload[:tries]).to eq(5)
    end

    describe "bp_control_status" do
      it "is controlled when the latest BP is under control" do
        create(:blood_pressure, patient: patient, systolic: 120, diastolic: 80, recorded_at: 2.days.ago)

        expect(call_request.payload[:bp_control_status]).to eq("controlled")
      end

      it "is uncontrolled when the latest BP is hypertensive" do
        create(:blood_pressure, patient: patient, systolic: 120, diastolic: 80, recorded_at: 20.days.ago)
        create(:blood_pressure, patient: patient, systolic: 160, diastolic: 100, recorded_at: 2.days.ago)

        expect(call_request.payload[:bp_control_status]).to eq("uncontrolled")
      end

      it "is omitted when the patient has no BP" do
        expect(call_request.payload).not_to have_key(:bp_control_status)
      end
    end

    describe "medicines_in_stock" do
      it "is true when every drug in the facility's latest stock report is in stock" do
        create(:drug_stock, facility: facility, in_stock: 100)
        create(:drug_stock, facility: facility, in_stock: 5)

        expect(call_request.payload[:medicines_in_stock]).to eq(true)
      end

      it "is false when any drug in the facility's latest stock report is out of stock" do
        create(:drug_stock, facility: facility, in_stock: 100)
        create(:drug_stock, facility: facility, in_stock: 0)

        expect(call_request.payload[:medicines_in_stock]).to eq(false)
      end

      it "falls back to last month's report" do
        create(:drug_stock, facility: facility, in_stock: 10, for_end_of_month: 1.month.ago.end_of_month)

        expect(call_request.payload[:medicines_in_stock]).to eq(true)
      end

      it "is omitted when the facility has no recent stock report" do
        create(:drug_stock, facility: facility, in_stock: 10, for_end_of_month: 3.months.ago.end_of_month)

        expect(call_request.payload).not_to have_key(:medicines_in_stock)
      end
    end

    it "raises a missing reference error when the patient has no mobile number" do
      patient.phone_numbers.destroy_all

      expect { described_class.new(notification.reload).payload }
        .to raise_error(Messaging::MissingReferenceError)
    end
  end
end
