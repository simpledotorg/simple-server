require 'rails_helper'

RSpec.describe CreateAuditLogsJob, type: :job do
  include ActiveJob::TestHelper

  describe '#perform_later' do
    let(:user) { create :master_user }
    let(:record_class) { 'Patient' }
    let(:record_ids) { create_list(record_class.underscore.to_sym, 3).pluck(:id) }
    let(:action) { 'fetch' }
    let(:job) { CreateAuditLogsJob.perform_later(user.id, 'Patient', record_ids, action) }

    it 'queues the job' do
      assert_enqueued_jobs 1 do
        job
      end
    end

    it 'queues the job on the default queue' do
      expect(job.queue_name).to eq('default')
    end

    it 'updates the cache for the facility group with analytics for the given time' do
      perform_enqueued_jobs { job }
      user_audit_logs = AuditLog.where(user: user)
      expect(user_audit_logs.count).to eq(3)
      expect(user_audit_logs.pluck(:auditable_id)).to match_array(record_ids)
    end
  end
end