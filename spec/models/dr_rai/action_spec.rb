require "rails_helper"

RSpec.describe DrRai::Action, type: :model do
  describe "default scope" do
    let(:first_action) { DrRai::Action.create(description: "the first") }
    let(:second_action) { DrRai::Action.create(description: "the second") }

    it "orders by ascending created_at" do
      expect(DrRai::Action.all).to eq [first_action, second_action]
    end
  end
end
