require "rails_helper"

RSpec.describe Api::V4::TeleconsultationTransformer do
  describe "to_response" do
    let!(:nurse) { create(:user) }
    let!(:medical_officer) { create(:user) }
    let!(:facility) { create(:facility) }
    let!(:teleconsultation) do
      FactoryBot.build(:teleconsultation,
        requester: nurse,
        medical_officer: medical_officer,
        facility: facility,
        request_completed: "yes")
    end

    it "sends the request data in a request hash" do
      response = described_class.to_response(teleconsultation)
      expect(response["request"]).to include("requested_at",
        "requester_id" => nurse.id,
        "facility_id" => facility.id,
        "request_completed" => "yes")
    end

    it "sends the record data in a record hash" do
      response = described_class.to_response(teleconsultation)
      expect(response["record"]).to include("recorded_at",
        "teleconsultation_type" => "audio",
        "patient_took_medicines" => "yes",
        "patient_consented" => "yes",
        "medical_officer_number" => "")
    end
  end

  describe ".from_request" do
    let!(:teleconsultation) { create(:teleconsultation) }
    context "request" do
      it "retrieves nested request data from payload" do
        expect(described_class.from_request(build_teleconsultation_payload)).to include(*Teleconsultation::REQUEST_ATTRIBUTES)
      end
    end

    context "record" do
      it "retrieves nested record data in payload" do
        expect(described_class.from_request(build_teleconsultation_payload)).to include(*Teleconsultation::RECORD_ATTRIBUTES)
      end
    end
  end
end
