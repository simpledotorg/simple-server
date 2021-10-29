require "rails_helper"

RSpec.describe Reports::RegionCacheWarmer, type: :model do
  let(:facility_group) { create(:facility_group) }
  let(:user) { create(:user, organization: facility_group.organization) }
  let(:june_1_2020) { Time.parse("June 1, 2020 00:00:00+00:00") }
  let(:august_1_2020) { Time.parse("August 1, 2020 00:00:00+00:00") }
  let(:june_30_2020) { Time.parse("June 30, 2020 00:00:00+00:00") }
  let(:july_2020) { Time.parse("July 15, 2020 00:00:00+00:00") }

  before do
    memory_store = ActiveSupport::Cache.lookup_store(:memory_store)

    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  around do |ex|
    with_reporting_time_zone { ex.run }
  end

  it "skips caching if disabled via Flipper" do
    Flipper.enable(:disable_region_cache_warmer)
    expect(Reports::Repository).to receive(:new).never
    Reports::RegionCacheWarmer.call
  end

  it "sets bust cache to false before running queries" do
    allow(RequestStore.store).to receive(:[]=)
    warmer = Reports::RegionCacheWarmer.new
    expect(RequestStore.store).to receive(:[]=).with(:bust_cache, true).ordered
    expect(warmer).to receive(:warm_caches).once.ordered
    expect(RequestStore.store).to receive(:[]=).with(:bust_cache, false).ordered

    warmer.call
  end

  it "new data is cached with every run of the cache warmer" do
    facility_1 = create(:facility, facility_group: facility_group)
    slug = facility_1.region.slug
    patient = Timecop.freeze(june_1_2020) do
      user = create(:user, organization: facility_group.organization)
      create(:patient, registration_facility: facility_1, registration_user: user)
    end
    Timecop.freeze(august_1_2020) do
      create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, user: user)
    end

    Timecop.freeze("September 1st 2020 00:04:00+00:00:00") do
      RefreshReportingViews.call
      described_class.call
      repo = Reports::Repository.new(facility_1, periods: Period.current.downto(6), reporting_schema_v2: true)
      expect(repo.cumulative_assigned_patients[slug][Period.current]).to eq(1)
      expect(repo.uncontrolled[slug][Period.current]).to eq(0)
      expect(repo.controlled[slug][Period.current]).to eq(1)
    end
    Timecop.freeze("September 2st 2020 00:04:00+00:00:00") do
      create(:patient, registration_facility: facility_1, registration_user: user)
      create(:bp_with_encounter, :hypertensive, facility: facility_1, patient: patient, user: user)
      RefreshReportingViews.call
      described_class.call
      repo = Reports::Repository.new(facility_1, periods: Period.current.downto(6), reporting_schema_v2: true)
      expect(repo.cumulative_assigned_patients[slug][Period.current]).to eq(2)
      expect(repo.uncontrolled[slug][Period.current]).to eq(1)
      expect(repo.controlled[slug][Period.current]).to eq(0)
    end
  end

  it "completes successfully" do
    facility = create(:facility, facility_group: facility_group)
    create(:patient, registration_facility: facility, registration_user: user)
    RefreshReportingViews.call
    Reports::RegionCacheWarmer.call
  end

  context "warm_repository_cache" do
    it "caches all non root/org regions in the v2 schema" do
      facility_1 = create(:facility, facility_group: facility_group)
      user = create(:user, organization: facility_group.organization)
      patient = create(:patient, registration_facility: facility_1, recorded_at: 2.months.ago, registration_user: user)
      create(:bp_with_encounter, :under_control, facility: facility_1, patient: patient, recorded_at: 15.days.ago)

      RefreshReportingViews.call

      described_class.call
      repo = Reports::Repository.new(facility_1, periods: Period.current, reporting_schema_v2: true)
      expect(repo.schema).to receive(:controlled).never # ensure the cache is hit and we don't retrieve counts again for the rate calc
      repo.controlled_rates
      repo.controlled_rates(with_ltfu: true)
    end
  end

  context "#warm_patient_breakdown" do
    it "refreshes the patient breakdown cache" do
      facility = create(:facility)
      create(:patient, assigned_facility: facility, recorded_at: 1.month.ago)
      create(:patient, status: :dead, assigned_facility: facility)

      period = Period.month(Time.current.beginning_of_month)
      described_class.new(period: period).call

      expect(Patient).to receive(:with_hypertension).never

      result_1 = PatientBreakdownService.call(region: facility.region, period: period)
      result_2 = PatientBreakdownService.call(region: facility.region, period: period)
      expect(result_1).to eq(result_2)
    end
  end
end
