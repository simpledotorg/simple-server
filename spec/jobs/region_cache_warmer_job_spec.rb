require "rails_helper"

RSpec.describe RegionCacheWarmerJob, type: :job do
  include ActiveJob::TestHelper

  before do
    memory_store = ActiveSupport::Cache.lookup_store(:memory_store)

    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  it "queues the job on the default queue" do
    facility = create(:facility)
    period = Period.month(Time.current.beginning_of_month)

    expect {
      RegionCacheWarmerJob.perform_async(facility.region.id, period.attributes)
    }.to change(Sidekiq::Queues["default"], :size).by(1)
    RegionCacheWarmerJob.clear
  end

  it "calls RegionService for the region and period" do
    facility = create(:facility)
    period = Period.month(Time.current.beginning_of_month)

    expect(Reports::RegionService).to receive(:call).with(region: facility.region, period: period)
    expect(Reports::RegionService).to receive(:call).with(region: facility.region, period: period, with_exclusions: true)

    described_class.perform_async(facility.region.id, period.attributes)
    described_class.drain
  end

  it "refreshes the region service cache" do
    facility = create(:facility)
    period = Period.month(Time.current.beginning_of_month)

    described_class.perform_async(facility.region.id, period.attributes)
    described_class.drain
    initial_registrations = Reports::RegionService.new(region: facility.region, period: period).call[:cumulative_registrations]

    create(:patient, assigned_facility: facility, recorded_at: 1.month.ago)
    described_class.perform_async(facility.region.id, period.attributes)
    described_class.drain
    final_registrations = Reports::RegionService.new(region: facility.region, period: period).call[:cumulative_registrations]

    expect(final_registrations).not_to eq(initial_registrations)
  end

  it "refreshes the patient breakdown cache" do
    facility = create(:facility)
    period = Period.month(Time.current.beginning_of_month)

    described_class.perform_async(facility.region.id, period.attributes)
    described_class.drain
    initial_breakdown = PatientBreakdownService.call(region: facility.region, period: period)

    create(:patient, assigned_facility: facility, recorded_at: 1.month.ago)
    create(:patient, status: :dead, assigned_facility: facility)
    described_class.perform_async(facility.region.id, period.attributes)
    described_class.drain
    final_breakdown = PatientBreakdownService.call(region: facility.region, period: period)

    expect(final_breakdown).not_to eq(initial_breakdown)
  end
end
