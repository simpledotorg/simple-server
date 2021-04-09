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
    reporting_regions = Region.where.not(region_type: ["organization", "root"])
    expect {
      Reports::RegionCacheWarmer.call
    }.to change(Sidekiq::Queues["default"], :size).by(reporting_regions.count)
  end

  it "queues a job for organization(s) if the organization_reports feature is enabled" do
    user = create(:user)
    Flipper.enable(:organization_reports, user)
    Reports::RegionCacheWarmer.call
    org_job_queued = Sidekiq::Queues["default"].any? { |job|
      job["args"].first == Region.organization_regions.first.id
    }
    expect(org_job_queued).to be true
  end
end
