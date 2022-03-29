require "rails_helper"

describe Configuration, type: :model do
  context "Validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:value) }
  end

  context "Behavior" do
    it_behaves_like "a record that is deletable"
  end
end
