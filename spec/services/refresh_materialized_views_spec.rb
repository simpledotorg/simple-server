require "rails_helper"

RSpec.describe RefreshMaterializedViews do
  it "returns nil if no time set" do
    expect(RefreshMaterializedViews.last_update_time).to be_nil
  end

  it "returns Time if time has been set" do
    Timecop.freeze("January 1st 2020 01:30 AM") do
      time = Time.current
      RefreshMaterializedViews.set_last_update_time

      expect(RefreshMaterializedViews.last_update_time).to eq(time)
    end
  end

  it "updates all materialized views and sets update time" do
    time = Time.current
    create_list(:blood_pressure, 2)

    expect {
      Timecop.freeze(time) do
        RefreshMaterializedViews.call
      end
    }.to change { LatestBloodPressuresPerPatientPerMonth.count }.from(0).to(2)
      .and change { LatestBloodPressuresPerPatient.count }.from(0).to(2)
      .and change { LatestBloodPressuresPerPatientPerQuarter.count }.from(0).to(2)
      .and change { BloodPressuresPerFacilityPerDay.count }.from(0).to(2)
      .and change { PatientRegistrationsPerDayPerFacility.count }.from(0).to(2)
      .and change { RefreshMaterializedViews.last_update_time }.from(nil).to(time)
  end
end
