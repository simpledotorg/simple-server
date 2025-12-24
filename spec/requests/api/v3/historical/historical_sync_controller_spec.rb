require "rails_helper"

class HistoricalSyncTestModel
  include ActiveModel::Model

  attr_accessor :id, :name, :status, :role

  def self.defined_enums
    {
      "status" => {"active" => "active", "inactive" => "inactive"},
      "role" => {"user" => "user", "admin" => "admin"}
    }
  end

  def assign_attributes(attrs)
    attrs.each { |key, value| public_send("#{key}=", value) }
  end
end

RSpec.describe Api::V3::Historical::HistoricalSyncController, type: :controller do
  controller(Api::V3::Historical::HistoricalSyncController) do
    def test_safe_assign(record, attrs)
      send(:safe_assign_attributes, record, attrs)
    end
  end

  describe "#safe_assign_attributes" do
    let(:record) { HistoricalSyncTestModel.new }

    it "assigns valid enum values as-is" do
      attributes = {status: "active", role: "admin"}

      controller.test_safe_assign(record, attributes)

      expect(record.status).to eq("active")
      expect(record.role).to eq("admin")
    end

    it "normalizes invalid enum values to nil" do
      attributes = {status: "zombie", role: "super_admin"}

      controller.test_safe_assign(record, attributes)

      expect(record.status).to be_nil
      expect(record.role).to be_nil
    end

    it "preserves non-enum attributes" do
      attributes = {name: "Test User", id: "123"}

      controller.test_safe_assign(record, attributes)

      expect(record.name).to eq("Test User")
      expect(record.id).to eq("123")
    end

    it "handles mixed valid and invalid enum attributes" do
      attributes = {
        name: "Valid User",
        status: "active",
        role: "god_mode"
      }

      controller.test_safe_assign(record, attributes)

      expect(record.name).to eq("Valid User")
      expect(record.status).to eq("active")
      expect(record.role).to be_nil
    end

    it "handles nil enum values gracefully" do
      attributes = {status: nil}

      controller.test_safe_assign(record, attributes)

      expect(record.status).to be_nil
    end
  end
end
