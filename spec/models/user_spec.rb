require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'Associations' do
    it { should have_many(:user_facilities) }
    it { should have_many(:facilities).through(:user_facilities) }
    it { should have_many(:blood_pressures) }
    it { should have_many(:patients).through(:blood_pressures) }
    it 'deletes all dependent user facilities' do
      user = FactoryBot.create(:user)
      FactoryBot.create_list(:user_facility, 5, user: user)
      expect { user.destroy }.to change { UserFacility.count }.by(-5)
    end
  end

  describe 'Validations' do
    it { should validate_presence_of(:full_name) }
    it { should validate_presence_of(:phone_number) }
    it { should validate_uniqueness_of(:phone_number) }
  end

  describe 'Helper Scopes' do
    describe ".requested_sync_approval" do
      let!(:requested_users) { create_list(:user, 2, :sync_requested) }
      let!(:allowed_user) { create(:user, :sync_allowed) }
      let!(:denied_user) { create(:user, :sync_denied) }

      it "should return users requested approval" do
        expect(User.requested_sync_approval).to match_array(requested_users)
      end

      it "should not return users already allowed or denied" do
        expect(User.requested_sync_approval).not_to include(allowed_user)
        expect(User.requested_sync_approval).not_to include(denied_user)
      end
    end
  end
end
