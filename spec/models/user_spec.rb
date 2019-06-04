require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'Associations' do
    it { should belong_to(:facility) }
    it { should have_many(:blood_pressures) }
    it { should have_many(:patients).through(:blood_pressures) }

    it { should have_many(:registered_patients).class_name("Patient").with_foreign_key("registration_user_id") }

    it 'has distinct patients' do
      user = FactoryBot.create(:user)
      patient = FactoryBot.create(:patient)
      FactoryBot.create_list(:blood_pressure, 5, user: user, patient: patient)
      expect(user.patients.count).to eq(1)
    end
  end

  describe 'Validations' do
    it { should validate_presence_of(:full_name) }
    it { should validate_presence_of(:phone_number) }
    it { should validate_uniqueness_of(:phone_number).ignoring_case_sensitivity }
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

  describe '#has_never_logged_in?' do
    context 'user has never logged in' do
      it 'returns true' do
        user = User.new(logged_in_at: nil)
        expect(user.has_never_logged_in?).to be true
      end
    end

    context 'user has logged in atleast once' do
      it 'returns false' do
        user = User.new(logged_in_at: DateTime.yesterday)
        expect(user.has_never_logged_in?).to be false
      end
    end
  end

  describe 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end
end
