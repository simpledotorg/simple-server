require 'rails_helper'

RSpec.describe CreateAuditLogsWorker, type: :job do
  include ActiveJob::TestHelper

  describe '#perform_later' do
    let!(:user) { create :user }
    let(:record_class) { 'Patient' }
    let(:record_ids) { create_list(record_class.underscore.to_sym, 3).pluck(:id) }
    let(:action) { 'fetch' }

    it 'queues the job on audit_log_queue' do
      expect {
        CreateAuditLogsWorker.perform_async(user.id, 'Patient', record_ids, action)
      }.to change(Sidekiq::Queues['audit_log_queue'], :size).by(1)
      CreateAuditLogsWorker.clear
    end

    it 'updates the cache for the facility group with analytics for the given time' do
      CreateAuditLogsWorker.perform_async(user.id, 'Patient', record_ids, action)
      CreateAuditLogsWorker.drain
      user_audit_logs = AuditLog.where(user: user)
      expect(user_audit_logs.count).to eq(3)
      expect(user_audit_logs.pluck(:auditable_id)).to match_array(record_ids)
    end
  end
end