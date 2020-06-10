require 'rails_helper'

RSpec.describe UserPermission, type: :model do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:resource).optional }
  end

  describe "validations" do
    it "must have a valid permissions_slug" do
      user = build(:user)
      permission = UserPermission.new(user: user, permission_slug: "unknown")
      expect(permission).to_not be_valid
      expect(permission.errors[:permission_slug]).to eq(["is not a known permission"])
      permission.permission_slug = :manage_admins
      expect(permission).to be_valid
    end
  end
end
