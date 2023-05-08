require "rails_helper"

RSpec.describe RefreshReportingViews do
  around(:example) do |example|
    Rails.cache.clear
    with_reporting_time_zone do
      example.run
    end
    Rails.cache.clear
  end

  it "returns nil if no time set" do
    expect(RefreshReportingViews.last_updated_at).to be_nil
  end

  it "returns Time if time has been set" do
    Timecop.freeze("January 1st 2020 01:30 AM") do
      time = Time.current
      RefreshReportingViews.set_last_updated_at

      expect(RefreshReportingViews.last_updated_at).to eq(time)
    end
  end

  it "updates all materialized views and sets update time" do
    time = Time.current
    # Just adding enough data to smoke test this; we test these views
    # more thoroughly via various reporting specs

    expect {
      Timecop.freeze(time) do
        create_list(:blood_pressure, 2)
        RefreshReportingViews.call
      end
    }.to change { LatestBloodPressuresPerPatientPerMonth.count }.by(2)
      .and change { LatestBloodPressuresPerPatient.count }.by(2)
      .and change { BloodPressuresPerFacilityPerDay.count }.by(2)
      .and change { RefreshReportingViews.last_updated_at }.from(nil).to(time)
  end

  it "updates v2 matviews" do
    time = Time.current
    expect {
      Timecop.freeze(time) do
        patients = create_list(:patient, 2, recorded_at: 1.month.ago)
        patients.each do |patient|
          create(:blood_pressure, patient: patient, recorded_at: 1.month.ago)
          create(:blood_sugar, patient: patient, recorded_at: 1.month.ago)
        end
        create(:blood_pressure, patient: patients.first, recorded_at: Time.current)

        RefreshReportingViews.call
      end
    }.to change { Reports::PatientBloodPressure.count }.by(4)
      .and change { Reports::PatientBloodSugar.count }.by(4)
      .and change { Reports::PatientState.count }.by(4)
      .and change { Reports::PatientVisit.count }.by(4)
      .and change { Reports::PatientFollowUp.count }.by(1)
  end

  it "updates only the specified view when views are passed in" do
    time = Time.current
    expect {
      Timecop.freeze(time) do
        facility = create(:facility)
        patient = create(:patient, :diabetes, recorded_at: 1.month.ago, registration_facility: facility)
        create(:blood_pressure, patient: patient, recorded_at: 2.days.ago, facility: facility)
        create(:appointment, patient: patient, recorded_at: 2.day.ago, facility: facility)

        RefreshReportingViews.call(views: ["Reports::FacilityDailyFollowUpAndRegistration"])
      end
    }.to change { Reports::FacilityDailyFollowUpAndRegistration.count }.to be > 0
    expect(Reports::PatientState.count).to eq(0)
  end
end
