require "rails_helper"

describe Api::V4::PatientAttributeTransformer do
  let(:payload) do
    {
      "id" => SecureRandom.uuid,
      "patient_id" => SecureRandom.uuid,
      "height" => "123.4",
      "weight" => "67.8",
      "height_unit" => "ft",
      "weight_unit" => "lb"
    }
  end

  let(:payload_without_units) do
    {
      "id" => SecureRandom.uuid,
      "patient_id" => SecureRandom.uuid,
      "height" => "123.4",
      "weight" => "67.8"
    }
  end

  subject { Api::V4::PatientAttributeTransformer.from_request(patient_attribute) }

  context "from_request" do
    %w[height weight].each do |attribute|
      it "converts #{attribute} to a float" do
        transformed = Api::V4::PatientAttributeTransformer.from_request(payload)
        expect(transformed[attribute]).to be_an_instance_of(Float)
      end
    end

    {
      "height" => "cm",
      "weight" => "kg"
    }.each do |attribute, default_unit|
      it "defaults #{attribute} to '#{default_unit}'" do
        transformed = Api::V4::PatientAttributeTransformer.from_request(payload_without_units)
        expect(transformed[attribute + "_unit"]).to eq default_unit
      end
    end
  end
end
