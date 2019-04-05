require 'rails_helper'

RSpec.describe WarmUpAnalyticsCacheJob, type: :job do
  include ActiveJob::TestHelper

  let!(:facility_groups) { create_list(:facility_group, 2) }
  let(:to_time) { Time.new(2019, 3, 31).strftime('%Y-%m-%d') }
  let(:from_time) { (to_time.to_time - 90.days).strftime('%Y-%m-%d') }

  describe '.perform_later' do
    let(:job) { WarmUpAnalyticsCacheJob.perform_later }

    it 'queues the job' do
      assert_enqueued_jobs 1 do
        job
      end
    end

    it 'queues the job on the default queue' do
      expect(job.queue_name).to eq('default')
    end

    it 'enqueues one WarmUpFacilityGroupAnalyticsCacheJob for every facility group' do
      Timecop.travel(to_time) do
        facility_groups.each do |facility_group|
          expect(WarmUpFacilityGroupAnalyticsCacheJob).to receive(:perform_later).with(facility_group, from_time, to_time)
        end
        perform_enqueued_jobs { job }
      end
    end
  end
end