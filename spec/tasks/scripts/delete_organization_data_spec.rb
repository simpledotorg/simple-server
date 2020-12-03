require "rails_helper"
require "tasks/scripts/delete_organization_data"

RSpec.describe DeleteOrganizationData do
  describe ".delete_path_data" do
    let!(:organization_id) { "7e896fa8-5e8f-4902-b814-b58d12332d0f" }
    let!(:organization) { create(:organization, id: organization_id) }
    let!(:facility_group) { create(:facility_group, organization: organization) }
    let!(:facilities) { create_list(:facility, 2, facility_group: facility_group, facility_type: "Standalone") }
    let!(:patients) { facilities.map { |facility| create_list(:patient, 2, registration_facility: facility) }.flatten }
    let!(:blood_pressures) { patients.map { |patient| create_list(:blood_pressure, 2, patient: patient) }.flatten }
    let!(:blood_sugars) { patients.map { |patient| create_list(:blood_sugar, 2, patient: patient) }.flatten }
    # TODO: add more things

    before do
      allow(SimpleServer).to receive_message_chain(:env, :production?).and_return(true)
      allow(CountryConfig).to receive(:current).and_return({name: "India"})
      # Accidentally delete PATH and it's FGs. Womp womp.
      facility_group.destroy
      organization.destroy
    end

    it "deletes PATH and associated data" do
      described_class.delete_path_data(organization_id, dry_run: false)

      facilities.each { |facility| expect { facility.reload }.to raise_error ActiveRecord::RecordNotFound }
      patients.each { |patient| expect { patient.reload }.to raise_error ActiveRecord::RecordNotFound }
      blood_pressures.each { |blood_pressure| expect { blood_pressure.reload }.to raise_error ActiveRecord::RecordNotFound }
      blood_sugars.each { |blood_sugar| expect { blood_sugar.reload }.to raise_error ActiveRecord::RecordNotFound }
    end

    it "does not delete things from other orgs" do
      other_organizations = create_list(:organization, 2)
      other_facility_groups = other_organizations.map { |org| create_list(:facility_group, 2, organization: org) }.flatten
      other_facilities = other_facility_groups.map { |fg| create_list(:facility, 2, facility_group: fg) }.flatten

      described_class.delete_path_data(organization_id, dry_run: false)
      other_organizations.map { |org| expect(org.reload).to eq org }
      other_facility_groups.map { |fg| expect(fg.reload).to eq fg }
      other_facilities.map { |facility| expect(facility.reload).to eq facility }
    end
  end

  describe ".call" do
    let!(:organization) { create(:organization) }
    let!(:facility_group) { create(:facility_group, organization: organization) }
    let!(:facilities) { create_list(:facility, 2, facility_group: facility_group) }
    let!(:patients) { facilities.map { |facility| create_list(:patient, 2, registration_facility: facility) }.flatten }
    let!(:blood_pressures) { patients.map { |patient| create_list(:blood_pressure, 2, patient: patient) }.flatten }
    let!(:blood_sugars) { patients.map { |patient| create_list(:blood_sugar, 2, patient: patient) }.flatten }
    # TODO: add more things

    it "deletes an org and associated data" do
      described_class.call(organization_id: organization.id, dry_run: false)

      expect { organization.reload }.to raise_error ActiveRecord::RecordNotFound
      expect { facility_group.reload }.to raise_error ActiveRecord::RecordNotFound
      facilities.each { |facility| expect { facility.reload }.to raise_error ActiveRecord::RecordNotFound }
      patients.each { |patient| expect { patient.reload }.to raise_error ActiveRecord::RecordNotFound }
      blood_pressures.each { |blood_pressure| expect { blood_pressure.reload }.to raise_error ActiveRecord::RecordNotFound }
      blood_sugars.each { |blood_sugar| expect { blood_sugar.reload }.to raise_error ActiveRecord::RecordNotFound }
    end

    it "does not delete things from other orgs" do
      other_organizations = create_list(:organization, 2)
      other_facility_groups = other_organizations.map { |org| create_list(:facility_group, 2, organization: org) }.flatten
      other_facilities = other_facility_groups.map { |fg| create_list(:facility, 2, facility_group: fg) }.flatten

      described_class.call(organization_id: organization.id, dry_run: false)
      other_organizations.map { |org| expect(org.reload).to eq org }
      other_facility_groups.map { |fg| expect(fg.reload).to eq fg }
      other_facilities.map { |facility| expect(facility.reload).to eq facility }
    end
  end
end
