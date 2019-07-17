require 'rails_helper'

RSpec.describe AutomaticPhoneNumberWhitelistingJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform_later' do
    let(:job) { AutomaticPhoneNumberWhitelistingJob.perform_later }

    it 'queues the job' do
      assert_enqueued_jobs 1 do
        job
      end
    end

    it 'queues the job on the exotel_phone_whitelist queue' do
      expect(job.queue_name).to eq('exotel_phone_whitelist')
    end

    it "calls the exotel whitelist api for all phone numbers that require whitelisting" do

    end
  end
end