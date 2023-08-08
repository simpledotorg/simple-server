require "rails_helper"

RSpec.describe Questionnaire, type: :model do
  describe "Associations" do
    it { is_expected.to have_many(:questionnaire_responses) }
  end

  describe "Validations" do
    it "allows only one active form per type" do
      expect {
        create_list(:questionnaire,
          2,
          questionnaire_type: "monthly_screening_reports",
          dsl_version: "1",
          is_active: true)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "allows multiple inactive forms per type" do
      expect {
        create_list(:questionnaire, 2, questionnaire_type: "monthly_screening_reports", dsl_version: "1", is_active: false)
        create(:questionnaire, questionnaire_type: "monthly_screening_reports", dsl_version: "1", is_active: true)
      }.to change { Questionnaire.count }.by 3
    end

    it "validates DSL version follows X.Y semver" do
      allow_any_instance_of(Questionnaire).to receive(:validate_layout)

      ["1a", "1.a", "1.", "a1", "a.1", "-1.1", "+2.2", ".1"].each do |dsl_version|
        expect {
          create(:questionnaire, dsl_version: dsl_version)
        }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Dsl version should be a Semver of pattern X.Y where X & Y are integers")
      end
    end

    it "validates the specimen layout for dsl_version_1 using the swagger schema" do
      questionnaire = build(:questionnaire, dsl_version: "1", layout: Api::V4::Models::Questionnaires::SpecimenLayout::DSLVERSION1)
      expect(questionnaire).to receive(:validate_layout).and_call_original

      questionnaire.save!
    end

    it "validates the specimen layout for dsl_version_1_1 using the swagger schema" do
      questionnaire = build(:questionnaire, dsl_version: "1.1", layout: Api::V4::Models::Questionnaires::SpecimenLayout::DSLVERSION1DOT1)
      expect(questionnaire).to receive(:validate_layout).and_call_original

      questionnaire.save!
    end

    it "validates the specimen layout for dsl_version_1_2 using the swagger schema" do
      questionnaire = build(:questionnaire, dsl_version: "1.2", layout: Api::V4::Models::Questionnaires::SpecimenLayout::DSLVERSION1DOT2)
      expect(questionnaire).to receive(:validate_layout).and_call_original

      questionnaire.save!
    end

    it "raises error for unsupported dsl_version" do
      expect { FactoryBot.create(:questionnaire, dsl_version: 100) }.to raise_error(StandardError)
    end

    it "ensures IDs are generated before validation" do
      questionnaire = build(:questionnaire)
      expect(questionnaire).to receive(:generate_ids_for_layout).and_call_original

      questionnaire.save!
      expect(Questionnaire.find(questionnaire.id).layout["id"]).to be_present
    end
  end

  describe ".for_sync" do
    it "includes discarded questionnaires" do
      questionnaire = create(:questionnaire, :active, deleted_at: Time.now)

      expect(described_class.for_sync).to include(questionnaire)
    end

    it "doesn't include discarded questionnaires that have been marked inactive" do
      questionnaire = create(:questionnaire, is_active: false, deleted_at: Time.now)

      expect(described_class.for_sync).not_to include(questionnaire)
    end

    it "includes only the active forms" do
      active_questionnaire = create(:questionnaire, questionnaire_type: "monthly_screening_reports", dsl_version: "1", is_active: true)
      _inactive_questionnaire = create(:questionnaire, questionnaire_type: "monthly_screening_reports", dsl_version: "1", is_active: false)

      expect(described_class.for_sync).to include(active_questionnaire)
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
        {"text" => "test_translations.test_string"},
        {"text" => ""}
      ]}

      localized_layout = {"item" => [
        {"text" => "Test",
         "item" => [
           {"text" => "Test"},
           {"text" => "Test"}
         ]},
        {"text" => "Test"},
        {"text" => ""}
      ]}

      questionnaire = build(:questionnaire, layout: layout)
      expect(questionnaire.localized_layout).to eq(localized_layout)
    end

    it "raises an exception when key is missing" do
      layout = {"text" => "undefined_translation_key"}
      questionnaire = build(:questionnaire, layout: layout)

      expect { questionnaire.localized_layout }.to raise_error(I18n::MissingTranslationData)
    end
  end

  describe "#validate_layout" do
    it "adds errors if the layout schema is invalid" do
      invalid_questionnaire = build(:questionnaire, layout: {"broken" => "layout"})
      valid_questionnaire = build(:questionnaire)

      # Run pre-validation callbacks manually.
      invalid_questionnaire.generate_ids_for_layout
      valid_questionnaire.generate_ids_for_layout

      invalid_questionnaire.validate_layout
      valid_questionnaire.validate_layout

      expect(valid_questionnaire.errors).to be_empty
      expect(invalid_questionnaire.errors).not_to be_empty
    end
  end

  describe "#layout_valid?" do
    it "returns false if the layout schema is invalid" do
      invalid_questionnaire = build(:questionnaire, layout: {"broken" => "layout"})
      valid_questionnaire = build(:questionnaire)

      # Run pre-validation callbacks manually.
      invalid_questionnaire.generate_ids_for_layout
      valid_questionnaire.generate_ids_for_layout

      expect(invalid_questionnaire.layout_valid?).to eq false
      expect(valid_questionnaire.layout_valid?).to eq true
    end
  end
end
