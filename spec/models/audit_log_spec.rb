require "rails_helper"
describe AuditLog, type: :model do
  let(:user) { create :user }
  let(:record) { create :patient }

  describe ".merge_log" do
    it "creates a merge log for the user and record" do
      AuditLog::MERGE_STATUS_TO_ACTION.each do |status, action|
        record.merge_status = status

        Timecop.freeze do
          expect(AuditLogger)
            .to receive(:info).with({user: user.id,
                                     auditable_type: record.class.to_s,
                                     auditable_id: record.id,
                                     action: action,
                                     time: Time.current}.to_json)

          AuditLog.merge_log(user, record)
        end
      end
    end
  end

  describe ".fetch_log" do
    it "creates a fetch log for the user and record" do
      Timecop.freeze do
        expect(AuditLogger)
          .to receive(:info).with({user: user.id,
                                   auditable_type: record.class.to_s,
                                   auditable_id: record.id,
                                   action: "fetch",
                                   time: Time.current}.to_json)

        AuditLog.fetch_log(user, record)
      end
    end
  end

  describe ".login_log" do
    it "creates a login log for the user and record" do
      Timecop.freeze do
        expect(AuditLogger)
          .to receive(:info).with({user: user.id,
                                   auditable_type: "User",
                                   auditable_id: user.id,
                                   action: "login",
                                   time: Time.current}.to_json)

        AuditLog.login_log(user)
      end
    end
  end

  describe ".create_logs_async" do
    let(:record_type) { "Patient" }
    let(:records) { create_list(record_type.underscore.to_sym, 3) }
    let(:action) { "fetch" }

    it "schedules a job to create audit logs in the background" do
      expect {
        AuditLog.create_logs_async(user, records, action, Time.current)
      }.to change(CreateAuditLogsWorker.jobs, :size).by(1)
      CreateAuditLogsWorker.clear
    end

    it "creates audit logs for user and records when the job is completed" do
      Timecop.freeze do
        Sidekiq::Testing.inline! do
          records.each do |record|
            expect(AuditLogger)
              .to receive(:info).with({user: user.id,
                                       auditable_type: "Patient",
                                       auditable_id: record.id,
                                       action: "fetch",
                                       time: Time.current}.to_json)
          end
        end

        AuditLog.create_logs_async(user, records, action, Time.current)
        CreateAuditLogsWorker.drain
      end
    end
  end
end
