require "rails_helper"

RSpec.describe BulkApiImport::FhirObservationImporter do
  before { create(:facility) }
  let(:import_user) { ImportUser.find_or_create }
  let(:facility) { import_user.facility }
  let(:facility_identifier) do
    create(:facility_business_identifier, facility: facility, identifier_type: :external_org_facility_id)
  end
  let(:identifier) { SecureRandom.uuid }
  let(:patient) { create(:patient, id: Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, identifier)) }
  let(:patient_identifier) do
    create(:patient_business_identifier, patient: patient,
           identifier: identifier,
           identifier_type: :external_import_id)
  end

  describe "#import" do
    it "imports a blood pressure observation" do
      expect {
        described_class.new(
          build_observation_import_resource(:blood_pressure)
            .merge(performer: [{identifier: facility_identifier.identifier}],
              subject: {identifier: patient_identifier.identifier})
        ).import
      }.to change(BloodPressure, :count).by(1)
        .and change(Encounter, :count).by(1)
        .and change(Observation, :count).by(1)
    end

    it "imports a blood sugar observation" do
      expect {
        described_class.new(
          build_observation_import_resource(:blood_sugar)
            .merge(performer: [{identifier: facility_identifier.identifier}],
              subject: {identifier: patient_identifier.identifier})
        ).import
      }.to change(BloodSugar, :count).by(1)
        .and change(Encounter, :count).by(1)
        .and change(Observation, :count).by(1)
    end
  end

  describe "#build_blood_pressure_attributes" do
    it "correctly builds valid attributes across different blood pressure resources" do
      10.times.map { build_observation_import_resource(:blood_pressure) }.each do |resource|
        bp_resource = resource
          .merge(performer: [{identifier: facility_identifier.identifier}],
            subject: {identifier: patient_identifier.identifier})

        attributes = described_class.new(bp_resource).build_blood_pressure_attributes

        expect(Api::V3::BloodPressurePayloadValidator.new(attributes)).to be_valid
        expect(attributes[:patient_id]).to eq(patient.id)
      end
    end
  end

  describe "#build_blood_sugar_attributes" do
    it "correctly builds valid attributes across different blood sugar resources" do
      10.times.map { build_observation_import_resource(:blood_sugar) }.each do |resource|
        bs_resource = resource
          .merge(performer: [{identifier: facility_identifier.identifier}],
            subject: {identifier: patient_identifier.identifier})

        attributes = described_class.new(bs_resource).build_blood_sugar_attributes

        expect(Api::V4::BloodSugarPayloadValidator.new(attributes)).to be_valid
        expect(attributes[:patient_id]).to eq(patient.id)
      end
    end
  end

  describe "#dig_blood_pressure" do
    it "extracts systolic and diastolic readings" do
      expect(
        described_class.new({
          component: [
            {code: {coding: [system: "http://loinc.org", code: "8480-6"]}, valueQuantity: {value: 120}},
            {code: {coding: [system: "http://loinc.org", code: "8462-4"]}, valueQuantity: {value: 80}}
          ]
        }).dig_blood_pressure
      ).to eq({systolic: 120, diastolic: 80})
    end
  end

  describe "#dig_blood_sugar" do
    it "extracts blood sugar types and values" do
      [
        {code: "88365-2", value: 80, expected_type: :fasting, expected_value: 80},
        {code: "87422-2", value: 130, expected_type: :post_prandial, expected_value: 130},
        {code: "2339-0", value: 100, expected_type: :random, expected_value: 100},
        {code: "4548-4", value: 4, expected_type: :hba1c, expected_value: 4}
      ].each do |code:, value:, expected_type:, expected_value:|
        expect(described_class.new(
          {
            component: [{code: {coding: [system: "http://loinc.org", code: code]},
                         valueQuantity: {value: value}}]
          }
        ).dig_blood_sugar).to eq({blood_sugar_type: expected_type, blood_sugar_value: expected_value})
      end
    end
  end
end
