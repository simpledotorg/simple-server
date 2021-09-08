require "rails_helper"

RSpec.describe EarliestPatientDataQuery do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }

  it "returns earliest between assigned and registered patients in a region" do
    facility_1, facility_2 = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1)
    region = facility_group_1.region
    other_facility = create(:facility)
    patient_1 = create(:patient, recorded_at: "July 5th 2018", assigned_facility: facility_2, registration_user: user)
    _patient_2 = create(:patient, recorded_at: "June 1st 2018", assigned_facility: other_facility, registration_facility: facility_1, registration_user: user)
    _patient_3 = create(:patient, recorded_at: "January 1 2018", assigned_facility: other_facility, registration_facility: other_facility, registration_user: user)

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

  context "in a reporting time zone" do
    around do |example|
      Time.use_zone(CountryConfig.current[:time_zone]) do
        Groupdate.time_zone = CountryConfig.current[:time_zone]
        example.run
        Groupdate.time_zone = nil
      end
    end

    it "returns the correct earliest registration/assigned time" do
      registration_time = Time.zone.local(2020, 6, 30, 23, 59, 59)

      facility = FactoryBot.create(:facility)
      region = facility.region
      patient = create(:patient, recorded_at: registration_time, assigned_facility: facility, registration_user: user)

      expect(EarliestPatientDataQuery.call(region).utc).to eq(patient.recorded_at.utc)
    end
  end
end
