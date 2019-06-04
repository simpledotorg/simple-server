require 'rails_helper'

describe AuditLog, type: :model do
  include ActiveJob::TestHelper

  let(:user) { create :user }
  let(:record) { create :patient }

  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:auditable) }
  end

  context 'Validations' do
    it { validate_presence_of(:action) }
    it { validate_presence_of(:auditable) }
  end

  describe '.merge_log' do
    it 'creates a merge log for the user and record' do
      record.merge_status = :new
      expect {
        AuditLog.merge_log(user, record)
      }.to change(AuditLog, :count).by(1)
      audit_log = AuditLog.find_by(user: user, auditable: record)
      expect(audit_log).to be_present
      expect(audit_log.action).to eq(AuditLog::MERGE_STATUS_TO_ACTION[:new])
    end
  end

  describe '.fetch_log' do
    it 'creates a fetch log for the user and record' do
      expect {
        AuditLog.fetch_log(user, record)
      }.to change(AuditLog, :count).by(1)
      audit_log = AuditLog.find_by(user: user, auditable: record)
      expect(audit_log).to be_present
      expect(audit_log.action).to eq('fetch')
    end
  end

  describe '.login_log' do
    it 'creates a fetch log for the user and record' do
      expect {
        AuditLog.login_log(user)
      }.to change(AuditLog, :count).by(1)
      audit_log = AuditLog.find_by(user: user, auditable: user)
      expect(audit_log).to be_present
      expect(audit_log.action).to eq('login')
    end
  end

  describe '.create_logs_async' do
    let(:record_type) { 'Patient' }
    let(:records) { create_list(record_type.underscore.to_sym, 3) }
    let(:action) { 'fetch' }

    it 'schedules a job to create audit logs in the background' do
      assert_enqueued_jobs 1, only: CreateAuditLogsJob do
        AuditLog.create_logs_async(user, records, action)
      end
    end

    it 'creates audit logs for user and records when the job is completed' do
      perform_enqueued_jobs do
        AuditLog.create_logs_async(user, records, action)
      end

      records.each do |record|
        expect(AuditLog.find_by(user: user, auditable: record, action: action)).to be_present
      end
    end
  end
end
