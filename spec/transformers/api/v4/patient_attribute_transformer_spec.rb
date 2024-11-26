require "rails_helper"

describe Api::V4::PatientAttributeTransformer do
  let(:payload) do
    {
      id: SecureRandom.uuid,
      patient_id: SecureRandom.uuid,
      height: "123.4",
      weight: "67.8"
    }
  end

  subject { Api::V4::PatientAttributeTransformer.from_request(patient_attribute) }

  context "from_request" do
    %w[ height weight ].each do |attribute|
      it "converts #{attribute} to a float" do
        transformed = Api::V4::PatientAttributeTransformer.from_request(payload)
        expect(transformed[attribute]).to be_an_instance_of(Float)
      end
    end
  end
end
