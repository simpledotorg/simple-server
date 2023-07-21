require "rails_helper"

RSpec.describe QuestionnaireResponsesHelper do
  describe "#latest_active_questionnaire_id" do
    it "returns latest active questionnaire for given type" do
      type = Questionnaire.questionnaire_types.keys.sample
      _active_questionnaire = create(:questionnaire, :active, dsl_version: "1", questionnaire_type: type)
      latest_active_questionnaire = create(:questionnaire, :active, dsl_version: "1.1", questionnaire_type: type)
      _inactive_questionnaire = create(:questionnaire, dsl_version: "1.2", questionnaire_type: type)
      _questionnaire_different_type = create(:questionnaire, :active, dsl_version: "1.2",
                                            questionnaire_type: Questionnaire.questionnaire_types.except(type).keys.sample)

      expect(latest_active_questionnaire_id(type)).to eq(latest_active_questionnaire.id)
    end
  end
end
