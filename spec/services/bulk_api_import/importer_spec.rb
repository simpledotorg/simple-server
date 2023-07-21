require "rails_helper"

RSpec.describe BulkApiImport::Importer do
  before { FactoryBot.create(:facility) } # needed for our bot import user

  describe "#import" do
    let(:organization) { FactoryBot.create(:organization) }

    it "imports patient resources" do
      resources = 2.times.map { build_patient_import_resource }
      expect { described_class.new(resource_list: resources).import }.to change(Patient, :count).by(2)
    end
  end

  describe "#resource_importer" do
    it "fetches the correct importer" do
      importer = described_class.new(resource_list: [])

      expect(importer.resource_importer({resourceType: "Patient"}))
        .to be_an_instance_of(BulkApiImport::FhirPatientImporter)
    end
  end
end
