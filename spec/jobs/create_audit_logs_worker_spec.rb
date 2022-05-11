require "rails_helper"

RSpec.describe CreateAuditLogsWorker, type: :job do
  describe "#perform_later" do
    let!(:user) { create :user }
    let(:record_class) { "Patient" }
    let(:records) { create_list(record_class.underscore.to_sym, 3) }
    let(:record_ids) { records.pluck(:id) }

    let(:action) { "fetch" }

    it "queues the job on low" do
      expect {
        CreateAuditLogsWorker.perform_async({user_id: user.id,
                                             record_class: record_class,
                                             record_ids: record_ids,
                                             action: action,
                                             time: Time.current}.to_json)
      }.to change(Sidekiq::Queues["low"], :size).by(1)
      CreateAuditLogsWorker.clear
    end

    it "Writes fetch audit logs for the given records" do
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
        CreateAuditLogsWorker.perform_async({user_id: user.id,
                                             record_class: record_class,
                                             record_ids: record_ids,
                                             action: action,
                                             time: Time.current}.to_json)

        CreateAuditLogsWorker.drain
      end
    end
  end
end
