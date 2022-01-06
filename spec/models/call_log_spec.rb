# frozen_string_literal: true

require "rails_helper"

RSpec.describe CallLog, type: :model do
  describe "Validations" do
    it { should validate_presence_of(:caller_phone_number) }
    it { should validate_presence_of(:callee_phone_number) }
  end

  context "anonymised data for call logs" do
    describe "anonymized_data" do
      it "correctly retrieves the anonymised data for the call log" do
        call_log = create(:call_log)

        anonymised_data =
          {id: Hashable.hash_uuid(call_log.id),
           created_at: call_log.created_at,
           result: call_log.result,
           duration: call_log.duration,
           start_time: call_log.start_time,
           end_time: call_log.end_time}

        expect(call_log.anonymized_data).to eq anonymised_data
      end
    end
  end
end
