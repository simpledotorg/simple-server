require 'rails_helper'

RSpec.describe WarmUpDistrictAnalyticsCacheJob, type: :job do
  include ActiveJob::TestHelper

  let(:district) { 'Bathinda' }
  let(:organization) { create(:organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let!(:facilities) { create_list(:facility, 2, facility_group: facility_group, district: district) }

  let(:organization_district) { OrganizationDistrict.new(district, organization) }

  let(:to_time) { Time.new(2019, 3, 31).strftime('%Y-%m-%d') }
  let(:from_time) { (to_time.to_time - 90.days).strftime('%Y-%m-%d') }

  describe '.perform_later' do
    let(:job) { WarmUpDistrictAnalyticsCacheJob.perform_later(district, organization.id, from_time, to_time) }

    it 'queues the job on the default queue' do
      expect(job.queue_name).to eq('analytics_warmup')
    end

    it 'queues the job' do
      assert_enqueued_jobs 1 do
        job
      end
    end

    it 'updates the cache for organization district with analytics for the given time' do
      perform_enqueued_jobs { job }
      expect(Rails.cache.exist?(organization_district.analytics_cache_key(from_time.to_time, to_time.to_time)))
        .to be_truthy
    end
  end
end