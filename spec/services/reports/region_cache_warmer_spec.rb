require "rails_helper"

RSpec.describe Reports::RegionCacheWarmer, type: :model do
  before do
    memory_store = ActiveSupport::Cache.lookup_store(:memory_store)

    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  it "skips caching if disabled via Flipper" do
    Flipper.enable(:disable_region_cache_warmer)
    expect(Reports::RegionService).to receive(:new).never
    Reports::RegionCacheWarmer.call
  end

  it "completes successfully" do
    facility_group = create(:facility_group)
    facility_1, facility_2 = create_list(:facility, 2, facility_group: facility_group)
    user = create(:user, organization: facility_group.organization)
    create(:patient, registration_facility: facility_1, registration_user: user)
    create(:patient, registration_facility: facility_2, registration_user: user)
    Reports::RegionCacheWarmer.call
  end

  it "warms cache for organization(s) if the organization_reports feature is enabled" do
    create(:organization)
    Flipper.enable(:organization_reports)

    instance = described_class.new
    expect(instance).to receive(:warm_region_cache).with(Organization.first.region)

    instance.call
  end

  it "doesn't warm cache for organization(s) if the organization_reports feature is disabled" do
    create(:organization)

    instance = described_class.new
    expect(instance).not_to receive(:warm_region_cache).with(Organization.first.region)

    instance.call
  end

  context "#warm_region_cache" do
    it "calls RegionService for the region and period" do
      facility = create(:facility)
      period = Period.month(Time.current.beginning_of_month)

      expect(Reports::RegionService).to receive(:call).with(region: facility.region, period: period)

      described_class.new(period: period).warm_region_cache(facility.region)
    end

    it "refreshes the region service cache" do
      facility = create(:facility)
      period = Period.month(Time.current.beginning_of_month)

      described_class.new(period: period).warm_region_cache(facility.region)
      initial_registrations = Reports::RegionService.new(region: facility.region, period: period).call[:cumulative_registrations]

      create(:patient, registration_facility: facility, recorded_at: 1.month.ago)
      described_class.new(period: period).warm_region_cache(facility.region)

      final_registrations = Reports::RegionService.new(region: facility.region, period: period).call[:cumulative_registrations]

      expect(final_registrations).not_to eq(initial_registrations)
    end

    it "refreshes the patient breakdown cache" do
      facility = create(:facility)
      period = Period.month(Time.current.beginning_of_month)

      described_class.new(period: period).warm_region_cache(facility.region)
      initial_breakdown = PatientBreakdownService.call(region: facility.region, period: period)

      create(:patient, assigned_facility: facility, recorded_at: 1.month.ago)
      create(:patient, status: :dead, assigned_facility: facility)

      described_class.new(period: period).warm_region_cache(facility.region)
      final_breakdown = PatientBreakdownService.call(region: facility.region, period: period)

      expect(final_breakdown).not_to eq(initial_breakdown)
    end
  end
end
