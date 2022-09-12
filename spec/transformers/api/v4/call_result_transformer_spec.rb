require "rails_helper"

RSpec.describe Api::V4::CallResultTransformer do
  describe "#from_request" do
    it "finds the appointment by appointment_id and sets patient_id if missing" do
      appointment = create(:appointment)
      expect(Api::V4::CallResultTransformer.from_request(
        {"appointment_id" => appointment.id, "patient_id" => nil}
      )["patient_id"]).to eq(appointment.patient_id)
    end

    it "returns the hash as is if the appointment is missing" do
      patient_id = SecureRandom.uuid
      expect(Api::V4::CallResultTransformer.from_request(
        {"appointment_id" => SecureRandom.uuid, "patient_id" => patient_id}
      )["patient_id"]).to eq(patient_id)
    end
  end
end
