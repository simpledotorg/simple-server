# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserAuthentication, type: :model do
  describe "Associations" do
    it { should belong_to(:user) }
    it { should belong_to(:authenticatable) }
  end

  describe "Validations" do
    describe "#authenticatable uniqueness" do
      let!(:existing_auth) { create(:user_authentication) }
      let(:new_auth) { existing_auth.dup }

      it "should not be valid if everything is duplicated" do
        new_auth.valid?
        expect(new_auth.errors[:authenticatable_id]).to include("has already been taken")
      end

      it "should be valid if user is different" do
        new_auth.user = create(:user)
        new_auth.valid?
        expect(new_auth.errors[:authenticatable_id]).to be_empty
      end

      it "should be valid if authenticatable_type is different" do
        new_auth.authenticatable_type = "PhoneNumberAuthentication"
        new_auth.valid?
        expect(new_auth.errors[:authenticatable_id]).to be_empty
      end

      it "should be valid if authenticatable_id is different" do
        new_auth.authenticatable_id = SecureRandom.uuid
        new_auth.valid?
        expect(new_auth.errors[:authenticatable_id]).to be_empty
      end
    end
  end
end
