require 'rails_helper'

RSpec.describe WarmUpAnalyticsCacheJob, type: :job do
  include ActiveJob::TestHelper

  let!(:facility_groups) { create_list(:facility_group, 2) }
  let(:to_time) { Time.new(2019, 3, 31).strftime('%Y-%m-%d') }
  let(:from_time) { (to_time.to_time - 90.days).strftime('%Y-%m-%d') }

  describe '.perform_later' do
    let(:job) { WarmUpAnalyticsCacheJob.perform_later('FacilityGroup', facility_groups.first.id, from_time, to_time) }

    it 'queues the job on the default queue' do
      expect(job.queue_name).to eq('default')
    end

    it 'queues the job' do
      assert_enqueued_jobs 1 do
        job
      end
    end

    it 'updates the cache for facility group with analytics for the given time' do
      perform_enqueued_jobs { job }
      expect(Rails.cache.exist?(facility_groups.first.analytics_cache_key(from_time.to_time, to_time.to_time))).to be_truthy
    end


    it 'updates the cache for facility with analytics for the given time' do
      perform_enqueued_jobs { job }
      expect(Rails.cache.exist?(facility_groups.first.analytics_cache_key(from_time.to_time, to_time.to_time))).to be_truthy
    end

    it 'updates the cache for the facilities in the facility group with analytics for the given time' do
      facility = create(:facility)

      perform_enqueued_jobs { WarmUpAnalyticsCacheJob.perform_later('Facility', facility.id, from_time, to_time) }

      expect(Rails.cache.exist?(facility.analytics_cache_key(from_time.to_time, to_time.to_time))).to be_truthy
    end
  end
end