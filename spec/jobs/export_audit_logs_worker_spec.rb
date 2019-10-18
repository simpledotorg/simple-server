require 'rails_helper'

RSpec.describe ExportAuditLogsWorker, type: :job do
  include ActiveJob::TestHelper

  let(:date) { '1999-01-01' }
  let!(:audit_logs) do
    Timecop.travel(date) do
      create_list(:audit_log, 10)
    end
  end

  let(:gzip_size) do

  end

  let(:file_path) { "#{Rails.root}/log/audit.log-#{date.tr('-', '')}" }
  let(:gzipped_file_path) { "#{file_path}.gz" }

  describe '#perform_async' do
    it 'queues the job on the audit_log_data_queue' do
      expect {
        ExportAuditLogsWorker.perform_async(date)
      }.to change(Sidekiq::Queues['audit_log_data_queue'], :size).by(1)
      ExportAuditLogsWorker.clear
    end
  end

  describe '#perform' do
    before do
      File.delete(file_path) if File.exist?(file_path)
      File.delete(gzipped_file_path) if File.exist?(gzipped_file_path)
    end

    it 'exports the audit logs to a file' do
      ExportAuditLogsWorker.perform_async(date)
      ExportAuditLogsWorker.drain


      expect(File).to exist(gzipped_file_path)
    end

    it 'gzip file contains compressed audit log' do
      ExportAuditLogsWorker.perform_async(date)
      ExportAuditLogsWorker.drain

      Zlib::GzipReader.open(gzipped_file_path) do |gz|
        file_contents = gz.read

        audit_logs.each do |audit_log|
          expect(file_contents).to match(/"auditable_id":"#{audit_log.auditable_id}"/)
        end
      end
    end

    it 'deletes uncompressed audit log file' do
      expect(File).to receive(:delete).with(file_path)

      ExportAuditLogsWorker.perform_async(date)
      ExportAuditLogsWorker.drain
    end
  end
end
