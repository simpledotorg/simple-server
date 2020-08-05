require "rails_helper"

RSpec.describe UserResource, type: :model do
  describe "Validations" do
    context "resource" do
      let!(:resource) { create(:facility) }

      it "is invalid if user has more than one user_resource per resource" do
        admin = create(:admin, access_level: :viewer)

        __valid_user_resource = create(:user_resource, user: admin, resource: resource)
        invalid_user_resource = build(:user_resource, user: admin, resource: resource)

        expect(invalid_user_resource).to_not be_valid
        expect(invalid_user_resource.errors.messages[:user]).to eq ["user resource already exists."]
      end

      it "is invalid if non super-admins don't have a resource" do
        admin = create(:admin, access_level: :viewer)
        invalid_user_resource = build(:user_resource, user: admin, resource: nil)

        expect(invalid_user_resource).to_not be_valid
        expect(invalid_user_resource.errors.messages[:resource]).to eq ["must exist"]
      end

      it "is invalid if resource_type is not in the allow-list" do
        admin = create(:admin, access_level: :viewer)
        valid_user_resource_1 = build(:user_resource, user: admin, resource: create(:organization))
        valid_user_resource_2 = build(:user_resource, user: admin, resource: create(:facility_group))
        valid_user_resource_3 = build(:user_resource, user: admin, resource: create(:facility))
        invalid_user_resource = build(:user_resource, user: admin, resource: create(:appointment))

        expect(valid_user_resource_1).to be_valid
        expect(valid_user_resource_2).to be_valid
        expect(valid_user_resource_3).to be_valid
        expect(invalid_user_resource).to_not be_valid
        expect(invalid_user_resource.errors.messages[:resource_type]).to eq ["is not included in the list"]
      end
    end
  end

  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:resource) }
  end
end
