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
      .and change { Reports::OverduePatient.count }.by(4)
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

  describe "#refresh" do
    let(:mock_view_class) { double("MockViewClass") }
    let(:partitioned_view_class) { double("PartitionedViewClass") }

    before do
      allow(mock_view_class).to receive(:refresh)
      allow(mock_view_class).to receive(:partitioned?).and_return(false)
      allow(mock_view_class).to receive(:table_name).and_return("mock_view_table")
      allow(mock_view_class).to receive(:partitioned_refresh)
      allow(partitioned_view_class).to receive(:refresh)
      allow(partitioned_view_class).to receive(:partitioned?).and_return(true)
      allow(partitioned_view_class).to receive(:get_refresh_months).and_return([Date.current.beginning_of_month])
      allow(partitioned_view_class).to receive(:partitioned_refresh)
      allow(partitioned_view_class).to receive(:table_name).and_return("partitioned_view_table")
      allow(Metrics).to receive(:benchmark_and_gauge).and_yield
    end

    it "calls refresh on each view class" do
      allow_any_instance_of(String).to receive(:constantize).and_return(mock_view_class)
      refresher = RefreshReportingViews.new(views: ["MockView"])
      refresher.send(:refresh)
      expect(mock_view_class).to have_received(:refresh)
    end

    it "calls partitioned_refresh for partitioned views" do
      allow_any_instance_of(String).to receive(:constantize).and_return(partitioned_view_class)
      refresher = RefreshReportingViews.new(views: ["PartitionedView"])
      refresher.send(:refresh)
      expect(partitioned_view_class).to have_received(:refresh)
      expect(partitioned_view_class).to have_received(:partitioned_refresh).with(Date.current.beginning_of_month)
    end

    it "does not call partitioned_refresh for non-partitioned views" do
      allow_any_instance_of(String).to receive(:constantize).and_return(mock_view_class)
      refresher = RefreshReportingViews.new(views: ["MockView"])
      refresher.send(:refresh)
      expect(mock_view_class).not_to have_received(:partitioned_refresh)
    end
  end

  describe "#benchmark_and_statsd" do
    let(:refresher) { RefreshReportingViews.new(views: ["Reports::PatientState"]) }

    it "calls Metrics.benchmark_and_gauge with correct parameters for regular refresh" do
      allow(Reports::PatientState).to receive(:table_name).and_return("reporting_patient_states")
      expect(Metrics).to receive(:benchmark_and_gauge).with(
        "reporting_views_refresh_duration_seconds",
        {view: "reporting_patient_states", partitioned_refresh: false}
      ).and_yield

      result = refresher.send(:benchmark_and_statsd, "Reports::PatientState") { "test_result" }
      expect(result).to eq("test_result")
    end

    it "calls Metrics.benchmark_and_gauge with partitioned_refresh flag when specified" do
      allow(Reports::PatientState).to receive(:table_name).and_return("reporting_patient_states")
      expect(Metrics).to receive(:benchmark_and_gauge).with(
        "reporting_views_refresh_duration_seconds",
        {view: "reporting_patient_states", partitioned_refresh: true}
      ).and_yield

      refresher.send(:benchmark_and_statsd, "Reports::PatientState", true) { "test_result" }
    end

    it "handles 'all' operation correctly" do
      expect(Metrics).to receive(:benchmark_and_gauge).with(
        "reporting_views_refresh_duration_seconds",
        {view: "all", partitioned_refresh: false}
      ).and_yield

      refresher.send(:benchmark_and_statsd, "all") { "test_result" }
    end
  end
end
