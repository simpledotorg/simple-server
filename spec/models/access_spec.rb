require "rails_helper"

RSpec.describe Access, type: :model do
  describe "Validations" do
    it { is_expected.to validate_presence_of(:mode) }
    it {
      is_expected.to define_enum_for(:mode)
        .with_values(super_admin: "super_admin", manager: "manager", viewer: "viewer")
        .backed_by_column_of_type(:string)
    }

    context "resource" do
      let!(:admin) { create(:admin) }
      let!(:resource) { create(:facility) }

      it "is invalid if user has more than one access per resource" do
        __valid_access = create(:access, :viewer, user: admin, resource: resource)
        invalid_access = build(:access, :manager, user: admin, resource: resource)

        expect(invalid_access).to_not be_valid
        expect(invalid_access.errors.messages[:user]).to eq ["can only have one access per resource."]
      end

      it "is invalid if non super-admins don't have a resource" do
        invalid_access = build(:access, :viewer, user: admin, resource: nil)

        expect(invalid_access).to_not be_valid
        expect(invalid_access.errors.messages[:resource]).to eq ["must exist", "is required if not a super_admin."]
      end

      it "is invalid if super_admin has a resource" do
        invalid_access = build(:access, :super_admin, user: admin, resource: create(:facility))

        expect(invalid_access).to_not be_valid
        expect(invalid_access.errors.messages[:resource]).to eq ["must be nil if super_admin"]
      end

      it "is invalid if resource_type is not in the allow-list" do
        valid_access_1 = build(:access, :viewer, user: admin, resource: create(:organization))
        valid_access_2 = build(:access, :viewer, user: admin, resource: create(:facility_group))
        valid_access_3 = build(:access, :viewer, user: admin, resource: create(:facility))
        invalid_access = build(:access, :viewer, user: admin, resource: create(:appointment))

        expect(valid_access_1).to be_valid
        expect(valid_access_2).to be_valid
        expect(valid_access_3).to be_valid
        expect(invalid_access).to_not be_valid
        expect(invalid_access.errors.messages[:resource_type]).to eq ["is not included in the list"]
      end
    end
  end

  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:resource) }
  end
end
