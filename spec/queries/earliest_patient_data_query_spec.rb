require "rails_helper"

RSpec.describe EarliestPatientDataQuery do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }

  it "returns earliest between assigned and registered patients in a region" do
    facility_1, facility_2 = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1)
    region = facility_group_1.region
    other_facility = create(:facility)
    patient_1 = create(:patient, recorded_at: "July 5th 2018", assigned_facility: facility_2)
    _patient_2 = create(:patient, recorded_at: "June 1st 2018", assigned_facility: other_facility, registration_facility: facility_1)
    _patient_3 = create(:patient, recorded_at: "January 1 2018", assigned_facility: other_facility, registration_facility: other_facility)

    expect(EarliestPatientDataQuery.call(region)).to eq(Time.zone.parse("June 1st 2018"))
    patient_1.update! recorded_at: "May 31st 2018"
    expect(EarliestPatientDataQuery.call(region)).to eq(Time.zone.parse("May 31st 2018"))
  end

  it "returns nil if there are no patients for a region" do
    facility = create(:facility)
    region_1 = facility.region
    expect(EarliestPatientDataQuery.call(region_1)).to be_nil
  end

  it "returns nil if there are no facilities for a region" do
    facility_group = create(:facility_group)
    expect(EarliestPatientDataQuery.call(facility_group.region)).to be_nil
  end
end
