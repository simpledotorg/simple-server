require "rails_helper"

RSpec.describe Questionnaire, type: :model do
  describe "Validations" do
    subject { create(:questionnaire) }
    it "validates uniqueness" do
      should validate_uniqueness_of(:dsl_version)
        .scoped_to(:questionnaire_type)
        .with_message("has already been taken for given questionnaire_type")
    end

    it "allows only one active form per type" do

    end
  end

  describe ".for_sync" do
    it "includes discarded questionnaires" do
      discarded_questionnaire = create(:questionnaire, deleted_at: Time.now)

      expect(described_class.for_sync).to include(discarded_questionnaire)
    end

    it "includes only the active forms" do

    end
  end

  describe "#localized_layout" do
    it "localized text attributes in items recursively" do
      allow(I18n).to receive(:t!).with("test_translations.test_string").and_return "Test"
      layout = {"item" => [
        {"text" => "test_translations.test_string",
         "item" => [
           {"text" => "test_translations.test_string"},
           {"text" => "test_translations.test_string"}
         ]},
        {"text" => "test_translations.test_string"}
      ]}

      localized_layout = {"item" => [
        {"text" => "Test",
         "item" => [
           {"text" => "Test"},
           {"text" => "Test"}
         ]},
        {"text" => "Test"}
      ]}

      questionnaire = build(:questionnaire, layout: layout)
      expect(questionnaire.localized_layout).to eq(localized_layout)
    end
  end
end
