require "rails_helper"

RSpec.describe Permissions, type: :model do
  it "top level permission names match the slug" do
    Permissions::ALL_PERMISSIONS.each do |name, hsh|
      expect(name).to eq(hsh[:slug])
    end
  end
end
