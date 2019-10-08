require 'rails_helper'

RSpec.describe ExportAuditLogsWorker, type: :job do
  include ActiveJob::TestHelper

  let(:date) { Date.parse('1999-01-01') }
  let!(:audit_logs) do
    Timecop.travel(date.to_time) do
      create_list(:audit_log, 10)
    end
  end
  let(:file_path) { "#{Rails.root}/log/audit.log-#{date.to_s.tr('-', '')}" }

  describe '#perform_async' do
    it 'queues the job on the audit_log_data_queue' do
      expect {
        ExportAuditLogsWorker.perform_async(date.to_s, AuditLog.limit(5).to_json)
      }.to change(Sidekiq::Queues['audit_log_data_queue'], :size).by(1)
      ExportAuditLogsWorker.clear
    end
  end

  describe '#perform' do
    it 'exports the audit logs to a file' do
      File.delete(file_path) if File.exist?(file_path)

      ExportAuditLogsWorker.perform_async(date, AuditLog.limit(5).to_json)
      ExportAuditLogsWorker.drain

      expect(File).to exist(file_path)
      expect(File.readlines(file_path).size).to eq(6)
    end
  end
end
