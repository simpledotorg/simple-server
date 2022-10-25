require "rails_helper"

RSpec.describe Reports::RegionCacheWarmer, type: :model do
  it "calls RegionCacheWarmerJob in batches with limits and offsets" do
    batch_size = 2
    organization = create(:organization)
    states = create_list(:region, 5, :state, reparent_to: organization.region)
    states.each do |state|
      create_list(:facility_group, 2, organization: organization, state: state.name)
    end

    expect(Reports::RegionCacheWarmerJob).to receive(:perform_async).with("organization", batch_size, 0).exactly(1).times
    expect(Reports::RegionCacheWarmerJob).to receive(:perform_async).with("state", batch_size, 0).exactly(1).times
    expect(Reports::RegionCacheWarmerJob).to receive(:perform_async).with("state", batch_size, 2).exactly(1).times
    expect(Reports::RegionCacheWarmerJob).to receive(:perform_async).with("state", batch_size, 4).exactly(1).times
    expect(Reports::RegionCacheWarmerJob).to receive(:perform_async).with("district", batch_size, 0).exactly(1).times
    expect(Reports::RegionCacheWarmerJob).to receive(:perform_async).with("district", batch_size, 2).exactly(1).times
    expect(Reports::RegionCacheWarmerJob).to receive(:perform_async).with("district", batch_size, 4).exactly(1).times
    expect(Reports::RegionCacheWarmerJob).to receive(:perform_async).with("district", batch_size, 6).exactly(1).times
    expect(Reports::RegionCacheWarmerJob).to receive(:perform_async).with("district", batch_size, 8).exactly(1).times

    described_class.call(batch_size: batch_size)
  end
end
