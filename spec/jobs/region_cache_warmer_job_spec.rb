require "rails_helper"

RSpec.describe RegionCacheWarmerJob, type: :job do
  include ActiveJob::TestHelper

  let!(:facility) { create(:facility).region }
  let!(:region) { facility.region }
  let!(:period) { Period.month(Time.current) }

  it "queues the job on the low queue" do
    expect {
      RegionCacheWarmerJob.perform_async(region.id, period.attributes)
    }.to change(Sidekiq::Queues["default"], :size).by(1)
    RegionCacheWarmerJob.clear
  end

  it "calls RegionService for the region and period" do
    expect(Reports::RegionService).to receive(:call).with(region: region, period: period)
    expect(Reports::RegionService).to receive(:call).with(region: region, period: period, with_exclusions: true)

    described_class.perform_async(region.id, period.attributes)
    described_class.drain
  end
end
