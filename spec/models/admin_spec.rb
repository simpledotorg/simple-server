require 'rails_helper'

RSpec.describe Admin, type: :model do
  describe 'Associations' do
    it { should have_many(:admin_access_controls) }
  end

  context 'Validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:password) }
    it { should validate_presence_of(:role) }

    it { should define_enum_for(:role).with([:owner, :supervisor, :analyst, :organization_owner, :counsellor]) }
  end

  context 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end

  context 'Utility methods' do
    describe "#has_role?" do
      let(:owner) { create(:admin, :owner) }
      let(:supervisor) { create(:admin, :supervisor) }

      it "returns true for matching roles as strings" do
        expect(owner.has_role?("owner", "analyst")).to eq(true)
      end

      it "returns true for matching roles as symbols" do
        expect(owner.has_role?(:owner, :analyst)).to eq(true)
      end

      it "returns true when passed a single matching role" do
        expect(supervisor.has_role?(:supervisor)).to eq(true)
      end

      it "returns false for no matching roles" do
        expect(supervisor.has_role?(:fake_role)).to eq(false)
      end
    end
  end
end
