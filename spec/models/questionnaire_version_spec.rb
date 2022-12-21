require "rails_helper"

RSpec.describe QuestionnaireVersion, type: :model do
  describe "#localized_layout" do
    it "localized text attributes in items recursively" do
      allow(I18n).to receive(:t).with("test_translations.test_string").and_return "Test"
      layout = {"item" => [
        {"text" => "test_translations.test_string",
         "item" => [
           {"text" => "test_translations.test_string",
            "item" => [
              {"text" => "test_translations.test_string"}
            ]},
           {"text" => "test_translations.test_string",
            "item" => [
              {"text" => "test_translations.test_string"}
            ]}
         ]},
        {"text" => "test_translations.test_string"}
      ]}

      localized_layout = {"item" => [
        {"text" => "Test",
         "item" => [
           {"text" => "Test",
            "item" => [
              {"text" => "Test"}
            ]},
           {"text" => "Test",
            "item" => [
              {"text" => "Test"}
            ]}
         ]},
        {"text" => "Test"}
      ]}

      questionnaire = build(:questionnaire, layout: layout)
      expect(questionnaire.localized_layout).to eq(localized_layout)
    end
  end
end
