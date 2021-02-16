require "rails_helper"

RSpec.describe RegionCacheWarmerJob, type: :job do
  include ActiveJob::TestHelper

  let!(:facility) { create(:facility) }
  let!(:region) { facility.region }
  let!(:period) { Period.month(Time.current.beginning_of_month) }

  let!(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
  let!(:cache) { Rails.cache }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

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

  it "refreshes the cache" do
    described_class.perform_async(region.id, period.attributes)
    described_class.drain
    initial_registrations = Reports::RegionService.new(region: region, period: period).call[:cumulative_registrations]

    create(:patient, assigned_facility: facility, recorded_at: 1.month.ago)
    described_class.perform_async(region.id, period.attributes)
    described_class.drain
    final_registrations = Reports::RegionService.new(region: region, period: period).call[:cumulative_registrations]

    expect(final_registrations).not_to eq(initial_registrations)
  end
end
