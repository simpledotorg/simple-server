require "rails_helper"

RSpec.describe Reports::RegionAndPeriodFetcher, type: :model do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }

  let(:june_1_2018) { Time.parse("June 1, 2018 00:00:00+00:00") }
  let(:june_1_2020) { Time.parse("June 1, 2020 00:00:00+00:00") }
  let(:june_30_2020) { Time.parse("June 30, 2020 00:00:00+00:00") }
  let(:july_2020) { Time.parse("July 15, 2020 00:00:00+00:00") }
  let(:jan_2019) { Time.parse("January 1st, 2019 00:00:00+00:00") }
  let(:jan_2020) { Time.parse("January 1st, 2020 00:00:00+00:00") }
  let(:july_2018) { Time.parse("July 1st, 2018 00:00:00+00:00") }
  let(:july_2020) { Time.parse("July 1st, 2020 00:00:00+00:00") }

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatientPerQuarter.refresh
      PatientRegistrationsPerDayPerFacility.refresh
    end
  end

  it "works" do
    facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1).sort_by(&:slug)
    facility_1, facility_2 = facilities.take(2)

    _facility_1_registered = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
    _facility_2_registered = create(:patient, full_name: "other facility", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)
    region = facility_1.region
    period = jan_2019.to_period

    repo = Reports::Repository.new(region, periods: period)
    fetcher = repo.for_region_and_period(region, period)
    expect(fetcher.assigned_patients_count).to eq 2
  end

  it "raises if trying to fetch things outside the scope of the repository" do
    period = jan_2019.to_period
    other_period = jan_2020.to_period
    district = facility_group_1.region
    region_1 = create(:region, :facility, reparent_to: district)
    region_2 = create(:region, :facility, reparent_to: district)
    repo = Reports::Repository.new(region_1, periods: period)
    expect {
      repo.for_region_and_period(region_2, period)
    }.to raise_error(ArgumentError, "Repository does not include region #{region_2.slug}")
    expect {
      repo.for_region_and_period(region_1, other_period)
    }.to raise_error(ArgumentError, "Repository does not include period #{other_period}")
  end

  it "gets registration counts for single region" do
    facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1).sort_by(&:slug)
    facility_1, facility_2 = facilities.take(2)

    _facility_1_registered = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
    _facility_2_registered = create(:patient, full_name: "other facility", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)

    repo = Reports::Repository.new(facility_1.region, periods: jan_2019.to_period)
    expected = {
      facility_1.slug => {
        jan_2019.to_period => 2
      }
    }
    expect(repo.assigned_patients_count).to eq(expected)
  end

end