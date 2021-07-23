require "rails_helper"

RSpec.describe RefreshMaterializedViews do
  around(:example) do |example|
    Rails.cache.clear
    example.run
    Rails.cache.clear
  end

  it "returns nil if no time set" do
    expect(RefreshMaterializedViews.last_updated_at).to be_nil
  end

  it "returns Time if time has been set" do
    Timecop.freeze("January 1st 2020 01:30 AM") do
      time = Time.current
      RefreshMaterializedViews.set_last_updated_at

      expect(RefreshMaterializedViews.last_updated_at).to eq(time)
    end
  end

  it "updates all materialized views and sets update time" do
    time = Time.current
    # Just adding enough data to smoke test this; we test these views
    # more thoroughly via various reporting specs

    expect {
      Timecop.freeze(time) do
        create_list(:blood_pressure, 2)
        RefreshMaterializedViews.call
      end
    }.to change { LatestBloodPressuresPerPatientPerMonth.count }.by(2)
      .and change { LatestBloodPressuresPerPatient.count }.by(2)
      .and change { LatestBloodPressuresPerPatientPerQuarter.count }.by(2)
      .and change { BloodPressuresPerFacilityPerDay.count }.by(2)
      .and change { PatientRegistrationsPerDayPerFacility.count }.by(2)
      .and change { RefreshMaterializedViews.last_updated_at }.from(nil).to(time)
  end

  it "updates v2 matviews" do
    time = Time.current
    expect {
      Timecop.freeze(time) do
        create_list(:blood_pressure, 2)
        RefreshMaterializedViews.call
      end
    }.to change { Reports::PatientBloodPressure.count }.by(2)
      .and change { Reports::PatientState.count }.by(2)
      .and change { Reports::PatientVisit.count }.by(2)
  end
end
