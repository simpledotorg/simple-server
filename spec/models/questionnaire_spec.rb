require "rails_helper"

RSpec.describe Questionnaire, type: :model do
  it { is_expected.to belong_to(:questionnaire_version) }

  describe "delegated methods" do
    it { should delegate_method(:localized_layout).to(:questionnaire_version) }
    it { should delegate_method(:layout).to(:questionnaire_version) }
    it { should delegate_method(:id).to(:questionnaire_version) }
  end

  describe "Validations" do
    subject { create(:questionnaire) }
    it "validates uniqueness" do
      should validate_uniqueness_of(:dsl_version)
        .scoped_to(:questionnaire_type)
        .with_message("has already been taken for given questionnaire_type")
    end
  end

  describe ".for_sync" do
    it "includes discarded questionnaires" do
      discarded_questionnaire = create(:questionnaire, deleted_at: Time.now)

      expect(described_class.for_sync).to include(discarded_questionnaire)
    end

    it "includes nested sync resources" do
      _discarded_questionnaire = create(:questionnaire, deleted_at: Time.now)

      expect(described_class.for_sync.first.association(:questionnaire_version).loaded?).to eq true
    end
  end
end
