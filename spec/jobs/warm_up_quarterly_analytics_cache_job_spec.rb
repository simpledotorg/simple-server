require 'rails_helper'

RSpec.describe WarmUpQuarterlyAnalyticsCacheJob, type: :job do
  include ActiveJob::TestHelper

  let!(:facility_groups) { create_list(:facility_group, 2) }
  let(:current_date) { Date.new(2019, 2, 1) }

  describe '.perform_later' do
    let(:job) { WarmUpQuarterlyAnalyticsCacheJob.perform_later }

    it 'queues the job' do
      assert_enqueued_jobs 1 do
        job
      end
    end

    it 'queues the job on the default queue' do
      expect(job.queue_name).to eq('default')
    end

    it 'enqueues one WarmUpFacilityGroupAnalyticsCacheJob for every facility group for the last 4 quarters' do
      quarter_1 = { from_time: Date.new(2018, 1, 1), to_time: Date.new(2018, 3, 31) }
      quarter_2 = { from_time: Date.new(2018, 4, 1), to_time: Date.new(2018, 6, 30) }
      quarter_3 = { from_time: Date.new(2018, 7, 1), to_time: Date.new(2018, 9, 30) }
      quarter_4 = { from_time: Date.new(2018, 10, 1), to_time: Date.new(2018, 12, 31) }
      Timecop.travel(current_date) do
        facility_groups.each do |facility_group|
          [quarter_1, quarter_2, quarter_3, quarter_4].each do |quarter|
            expect(WarmUpFacilityGroupAnalyticsCacheJob)
              .to receive(:perform_later)
                    .with(facility_group,
                          quarter[:from_time].strftime('%Y-%m-%d'),
                          quarter[:to_time].strftime('%Y-%m-%d'))
          end
        end
        perform_enqueued_jobs { job }
      end
    end
  end
end