require 'rails_helper'

RSpec.describe WarmUpFacilityGroupAnalyticsCacheJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform_later' do
    let(:facility_group) { create(:facility_group) }
    let!(:facilities) { create_list(:facility, 2, facility_group: facility_group) }

    let(:from_time) { Date.new(2019, 1, 1).strftime('%Y-%m-%d') }
    let(:to_time) { Date.new(2019, 3, 31).strftime('%Y-%m-%d') }

    let(:job) { WarmUpFacilityGroupAnalyticsCacheJob.perform_later(facility_group, from_time, to_time) }

    it 'queues the job' do
      assert_enqueued_jobs 1 { job }
    end

    it 'queues the job on the default queue' do
      expect(job.queue_name).to eq('default')
    end

    it 'updates the cache for the facility group with analytics for the given time' do
      perform_enqueued_jobs { job }
      expect(Rails.cache.exist?(facility_group.analytics_cache_key(from_time.to_time, to_time.to_time))).to be_truthy
    end

    it 'updates the cache for the facilities in the facility group with analytics for the given time' do
      perform_enqueued_jobs { job }
      facilities.each do |facility|
        expect(Rails.cache.exist?(facility.analytics_cache_key(from_time.to_time, to_time.to_time))).to be_truthy
      end
    end
  end
end