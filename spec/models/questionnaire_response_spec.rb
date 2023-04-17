require "rails_helper"

RSpec.describe QuestionnaireResponse, type: :model do
  describe ".merge" do
    it "returns record with errors if invalid, and does not merge" do
      invalid_questionnaire_response = FactoryBot.build(:questionnaire_response, device_created_at: nil)
      questionnaire_response = QuestionnaireResponse.merge(invalid_questionnaire_response.attributes)
      expect(questionnaire_response).to be_invalid
      expect(QuestionnaireResponse.count).to eq 0
      expect(QuestionnaireResponse).to_not receive(:create)
    end

    it "does not update a discarded record" do
      discarded_questionnaire_response = FactoryBot.create(:questionnaire_response, deleted_at: Time.now)
      update_attributes = discarded_questionnaire_response.attributes.merge(
        content: {1 => 2},
        updated_at: 3.years.from_now
      )

      expect(QuestionnaireResponse.merge(update_attributes).attributes.with_int_timestamps)
        .to eq(discarded_questionnaire_response.attributes.with_int_timestamps)
    end

    it "creates a new record if there is no existing record" do
      new_questionnaire_response = FactoryBot.build(:questionnaire_response)
      QuestionnaireResponse.merge(new_questionnaire_response.attributes)
      expect(QuestionnaireResponse.first.attributes.except("updated_at", "created_at").with_int_timestamps)
        .to eq(new_questionnaire_response.attributes.except("updated_at", "created_at").with_int_timestamps)
    end

    it "updates the existing record and merges new keys in content, if it exists" do
      existing_questionnaire_response = FactoryBot.create(:questionnaire_response, content: {a: :a})
      updated_questionnaire_response = QuestionnaireResponse.find(existing_questionnaire_response.id)
      updated_questionnaire_response.updated_at = 10.minutes.from_now
      updated_questionnaire_response.content = {a: :b, c: :c}

      questionnaire_response = QuestionnaireResponse.merge(updated_questionnaire_response.attributes)

      expect(questionnaire_response).to_not have_changes_to_save
      expect(QuestionnaireResponse.find(existing_questionnaire_response.id).attributes.with_int_timestamps.except("updated_at"))
        .to eq(updated_questionnaire_response.attributes.with_int_timestamps.except("updated_at"))
      expect(QuestionnaireResponse.count).to eq 1
      expect(existing_questionnaire_response.reload.content).to eq({"a" => "b", "c" => "c"})
    end

    it "skips existing keys in content and merges new keys when input record is older" do
      ten_minutes_ago = 10.minutes.ago
      existing_questionnaire_response = FactoryBot.create(
        :questionnaire_response,
        updated_at: ten_minutes_ago,
        device_updated_at: ten_minutes_ago,
        content: {a: :a}
      )
      updated_questionnaire_response = QuestionnaireResponse.find(existing_questionnaire_response.id)
      now = Time.current
      updated_questionnaire_response.device_updated_at = 20.minutes.ago
      updated_questionnaire_response.content = {a: :b, c: :c}

      Timecop.freeze(now) do
        QuestionnaireResponse.merge(updated_questionnaire_response.attributes)
      end

      existing_questionnaire_response.reload
      expect(existing_questionnaire_response.updated_at.to_i).to eq now.to_i
      expect(existing_questionnaire_response.device_updated_at.to_i).to eq ten_minutes_ago.to_i
      expect(existing_questionnaire_response.content).to eq({"a" => "a", "c" => "c"})
      expect(QuestionnaireResponse.count).to eq 1
    end

    it "merges new keys in content when input record is equally up-to-date" do
      ten_minutes_ago = 10.minutes.ago
      existing_questionnaire_response = FactoryBot.create(
        :questionnaire_response,
        updated_at: ten_minutes_ago,
        device_updated_at: ten_minutes_ago,
        content: {a: :a}
      )
      updated_questionnaire_response = QuestionnaireResponse.find(existing_questionnaire_response.id)
      now = Time.current
      updated_questionnaire_response.device_updated_at = ten_minutes_ago
      updated_questionnaire_response.content = {a: :b, c: :c}

      Timecop.freeze(now) do
        QuestionnaireResponse.merge(updated_questionnaire_response.attributes)
      end

      existing_questionnaire_response.reload
      expect(existing_questionnaire_response.updated_at.to_i).to eq now.to_i
      expect(existing_questionnaire_response.device_updated_at.to_i).to eq ten_minutes_ago.to_i
      expect(existing_questionnaire_response.content).to eq({"a" => "b", "c" => "c"})
      expect(QuestionnaireResponse.count).to eq 1
    end

    it "counts metrics for old merges" do
      existing_questionnaire_response = FactoryBot.create(:questionnaire_response)
      updated_questionnaire_response = QuestionnaireResponse.find(existing_questionnaire_response.id)

      updated_questionnaire_response.device_updated_at = 10.minutes.ago

      expect(Statsd.instance).to receive(:increment).with("merge.QuestionnaireResponse.updated")
      QuestionnaireResponse.merge(updated_questionnaire_response.attributes)
    end

    it "counts metrics if the existing record device_updated_at is the same as the new one" do
      timestamp = Time.zone.parse("March 1st 04:00:00 IST")
      existing_questionnaire_response = FactoryBot.create(:questionnaire_response, device_updated_at: timestamp)
      updated_questionnaire_response = QuestionnaireResponse.find(existing_questionnaire_response.id)

      updated_questionnaire_response.device_updated_at = existing_questionnaire_response.device_updated_at

      expect(Statsd.instance).to receive(:increment).with("merge.QuestionnaireResponse.updated")
      QuestionnaireResponse.merge(updated_questionnaire_response.attributes)
    end

    it "acquires a lock before merging to avoid race conditions" do
      existing_response = create(:questionnaire_response)
      expect(QuestionnaireResponse).to receive(:lock).and_call_original
      QuestionnaireResponse.merge(existing_response.attributes)
    end

    it "doesn't allow facility_id to be changed" do
      existing_questionnaire_response = create(:questionnaire_response)
      facility = create(:facility)
      update_attributes = existing_questionnaire_response.attributes.merge(
        facility_id: facility.id
      )

      updated_questionnaire_response = QuestionnaireResponse.merge(update_attributes)
      expect(updated_questionnaire_response.merge_status).to eq(:invalid)
    end
  end
end
