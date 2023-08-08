require "rails_helper"

RSpec.describe BulkApiImport::FhirObservationImporter do
  before { create(:facility) }
  let(:import_user) { ImportUser.find_or_create }
  let(:facility) { import_user.facility }
  let(:facility_identifier) do
    create(:facility_business_identifier, facility: facility, identifier_type: :external_org_facility_id)
  end
  let(:patient) { create(:patient) }
  let(:patient_identifier) do
    create(:patient_business_identifier, patient: patient, identifier_type: :external_import_id)
  end

  describe "#import" do
    it "imports an observation" do
      [
        build_observation_import_resource(:blood_pressure)
          .merge(performer: [{identifier: facility_identifier.identifier}],
            subject: {identifier: patient_identifier.identifier})
        # build_observation_import_resource(:blood_sugar)
      ].each do |resource|
        expect { described_class.new(resource).import }
          .to change(BloodPressure, :count).by(1)
        # .and change(BloodSugar, :count).by(1)
      end
    end
  end
end
