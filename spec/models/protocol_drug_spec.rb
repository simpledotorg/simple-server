# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProtocolDrug, type: :model do
  describe "Associations" do
    it { should belong_to(:protocol) }
  end

  describe "Validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:dosage) }
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end
end
