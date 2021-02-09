require "rails_helper"

RSpec.describe Reports::RegionCacheWarmer, type: :model do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :manager, :with_access, resource: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }

  let(:jan_2019) { Time.parse("January 1st, 2019") }
  let(:jan_2020) { Time.parse("January 1st, 2020") }
  let(:june_1) { Time.parse("June 1st, 2020") }
  let(:july_1_2019) { Time.parse("July 1st, 2019") }
  let(:july_2020) { Time.parse("July 1st, 2020") }

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatientPerQuarter.refresh
      PatientRegistrationsPerDayPerFacility.refresh
    end
  end

  it "skips caching if disabled via Flipper" do
    Flipper.enable(:disable_region_cache_warmer)
    expect(Reports::RegionService).to receive(:new).never
    Reports::RegionCacheWarmer.call
  end

  it "sets force_cache to true on creation" do
    expect(RequestStore.store[:force_cache]).to be_nil
    Reports::RegionCacheWarmer.new
    expect(RequestStore.store[:force_cache]).to be true
  end

  it "completes successfully" do
    _facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1)
    Reports::RegionCacheWarmer.call
  end

  it "warms the cache for all regions" do
    _facilities = FactoryBot.create_list(:facility, 5, block: "Block 1", facility_group: facility_group_1)

    # we don't cache the Root or Organization regions
    regions_to_cache = Region.count - 2
    expect(Reports::RegionService).to receive(:call).with(hash_including(region: instance_of(Region))).exactly(regions_to_cache).times
    Reports::RegionCacheWarmer.call
  end
end
