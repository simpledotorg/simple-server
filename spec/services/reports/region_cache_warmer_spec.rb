require "rails_helper"

RSpec.describe Reports::RegionCacheWarmer, type: :model do
  it "skips caching if disabled via Flipper" do
    Flipper.enable(:disable_region_cache_warmer)
    expect(Reports::RegionService).to receive(:new).never
    Reports::RegionCacheWarmer.call
  end

  it "completes successfully" do
    create_list(:patient, 2)
    Reports::RegionCacheWarmer.call
  end

  it "queues a job on the default queue for every region" do
    create(:patient)
    reporting_regions = Region.where.not(region_type: ["root", "organization"])
    expect {
      Reports::RegionCacheWarmer.call
    }.to change(Sidekiq::Queues["default"], :size).by(reporting_regions.count)
  end
end
