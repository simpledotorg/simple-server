require "rails_helper"

RSpec.describe Reports::RegionCacheWarmer, type: :model do
  let(:facility_group) { create(:facility_group) }

  before do
    memory_store = ActiveSupport::Cache.lookup_store(:memory_store)

    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  it "skips caching if disabled via Flipper" do
    Flipper.enable(:disable_region_cache_warmer)
    expect(Reports::Repository).to receive(:new).never
    Reports::RegionCacheWarmer.call
  end

  it "completes successfully" do
    facility_1, facility_2 = create_list(:facility, 2, facility_group: facility_group)
    user = create(:user, organization: facility_group.organization)
    create(:patient, registration_facility: facility_1, registration_user: user)
    create(:patient, registration_facility: facility_2, registration_user: user)
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
