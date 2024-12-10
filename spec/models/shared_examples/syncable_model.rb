require "rails_helper"

RSpec.shared_examples_for "a syncable model" do
  describe "Validations" do
    it_behaves_like "a record that validates device timestamps"
    it { should validate_presence_of(:device_updated_at) }
    it { should validate_presence_of(:device_created_at) }
  end

  context "Scopes" do
    describe ".for_sync" do
      it "includes discarded instances" do
        class_factory = described_class.to_s.underscore.to_sym
        discarded_instance = create(class_factory, deleted_at: Time.now)
        expect(described_class.for_sync).to include(discarded_instance)
      end
    end
  end
end
