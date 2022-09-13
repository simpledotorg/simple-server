require "rails_helper"

RSpec.describe Api::V4::CallResultTransformer do
  describe "#from_request" do
    context "when patient_id is missing in payload" do
      it "adds a fallback patient_id using the appointment_id if missing" do
        appointment = create(:appointment)
        expect(Api::V4::CallResultTransformer.from_request(
          {"appointment_id" => appointment.id, "patient_id" => nil}
        )["patient_id"]).to eq(appointment.patient_id)
      end

      it "includes discarded appointments while filling up fallback patient_id" do
        appointment = create(:appointment, deleted_at: Time.now)
        expect(Api::V4::CallResultTransformer.from_request(
          {"appointment_id" => appointment.id, "patient_id" => nil}
        )["patient_id"]).to eq(appointment.patient_id)
      end

      it "returns the hash as is if the appointment is missing" do
        expect(Api::V4::CallResultTransformer.from_request(
          {"appointment_id" => SecureRandom.uuid, "patient_id" => nil}
        )["patient_id"]).to eq(nil)
      end
    end

    context "when patient_id is supplied in payload" do
      it "doesn't use a fallback patient_id" do
        patient_id = SecureRandom.uuid
        expect(Api::V4::CallResultTransformer.from_request(
          {"appointment_id" => SecureRandom.uuid, "patient_id" => patient_id}
        )["patient_id"]).to eq(patient_id)
      end
    end

    context "when facility_id is missing in payload" do
      it "adds a fallback facility ID if it is supplied" do
        fallback_id = SecureRandom.uuid
        expect(Api::V4::CallResultTransformer.from_request(
          {"appointment_id" => SecureRandom.uuid, "facility_id" => nil},
          fallback_facility_id: fallback_id
        )["facility_id"]).to eq(fallback_id)
      end
    end

    context "when facility_id is supplied in payload" do
      it "doesn't add the fallback facility ID" do
        facility_id = SecureRandom.uuid
        expect(Api::V4::CallResultTransformer.from_request(
          {"appointment_id" => SecureRandom.uuid, "facility_id" => facility_id}
        )["facility_id"]).to eq(facility_id)
      end
    end
  end
end
