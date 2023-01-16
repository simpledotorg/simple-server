require "rails_helper"

RSpec.describe Api::V4::QuestionnaireTransformer do
  describe "to_response" do
    it "transforms a questionnaire" do
      questionnaire = create(:questionnaire)

      expect(described_class.to_response(questionnaire)).to eq({
        id: questionnaire.id,
        questionnaire_type: questionnaire.questionnaire_type,
        deleted_at: nil,
        layout: questionnaire.localized_layout
      }.as_json)
    end
  end
end
