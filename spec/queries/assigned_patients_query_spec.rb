require "rails_helper"

RSpec.describe AssignedPatientsQuery do
  context "with_exclusions false" do
    it "should include only assigned hypertension patients" do
      facility = create(:facility)
      create(:patient, registration_facility: facility)
      create(:patient, :without_hypertension, registration_facility: facility)
      expect(AssignedPatientsQuery.new.count(facility, :month, with_exclusions: false).values.first).to eq 1
    end
  end
end
