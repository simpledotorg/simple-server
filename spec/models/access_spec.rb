# frozen_string_literal: true

require "rails_helper"

RSpec.describe Access, type: :model do
  let(:viewer_all) { create(:admin, :viewer_all) }
  let(:manager) { create(:admin, :manager) }

  describe "Associations" do
    it { is_expected.to belong_to(:user) }

    context "belongs to resource" do
      let(:facility) { create(:facility) }
      subject { create(:access, user: viewer_all, resource: facility) }
      it { expect(subject.resource).to be_present }
    end
  end

  describe "Validations" do
    context "resource" do
      let(:admin) { create(:admin) }
      let!(:resource) { create(:facility) }

      it "does not allow a power_user to have accesses (because they have all the access)" do
        power_user = create(:admin, :power_user)
        invalid_access = build(:access, user: power_user, resource: create(:facility))

        expect(invalid_access).to be_invalid
        expect(invalid_access.errors.messages[:user]).to eq ["cannot have accesses if they are a power user."]
      end

      it "is invalid if user has more than one access per resource" do
        __valid_access = create(:access, user: viewer_all, resource: resource)
        invalid_access = build(:access, user: viewer_all, resource: resource)

        expect(invalid_access).to be_invalid
        expect(invalid_access.errors.messages[:user]).to eq ["can only have 1 access per resource."]
      end

      it "must have a resource" do
        invalid_access = build(:access, user: viewer_all, resource: nil)

        expect(invalid_access).to be_invalid
        expect(invalid_access.errors.messages[:resource]).to eq ["must exist", "can't be blank"]
      end

      it "is invalid if resource_type is not in the allow-list" do
        valid_access_1 = build(:access, user: viewer_all, resource: create(:organization))
        valid_access_2 = build(:access, user: viewer_all, resource: create(:facility_group))
        valid_access_3 = build(:access, user: viewer_all, resource: create(:facility))
        invalid_access = build(:access, user: viewer_all, resource: create(:appointment))

        expect(valid_access_1).to be_valid
        expect(valid_access_2).to be_valid
        expect(valid_access_3).to be_valid
        expect(invalid_access).to be_invalid
        expect(invalid_access.errors.messages[:resource_type]).to eq ["is not included in the list"]
      end
    end
  end
end
