require "rails_helper"

RSpec.describe Api::V4::TeleconsultationTransformer do
  describe ".from_request" do
    let!(:teleconsultation) { create(:teleconsultation) }
    context "request" do
      it "retrieves nested request data from payload" do
        expect(described_class.from_request(build_teleconsultation_payload)).to include(*Teleconsultation::REQUEST_ATTRIBUTES)
      end

      it "removes the nested record map" do
        expect(described_class.from_request(build_teleconsultation_payload)).not_to include("request")
      end
    end

    context "record" do
      context "when retrieve_record is true" do
        it "retrieves nested record data in payload" do
          expect(described_class.from_request(
            build_teleconsultation_payload,
            retrieve_record: true
          )).to include(*Teleconsultation::RECORD_ATTRIBUTES)
        end
      end

      context "when retrieve_record is false" do
        it "does not retrieve the nested record data in payload" do
          expect(described_class.from_request(
            build_teleconsultation_payload,
            retrieve_record: false
          )).not_to include(*Teleconsultation::RECORD_ATTRIBUTES)
        end
      end

      it "removes the nested record map" do
        expect(described_class.from_request(build_teleconsultation_payload)).not_to include("record")
      end
    end
  end
end
