require "rails_helper"

RSpec.describe Manage::Facility::FacilityPolicy do
  subject { described_class }

  let(:organization) { create(:organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }

  let(:facility_1) { build(:facility, facility_group: facility_group) }
  let(:facility_2) { build(:facility) }

  context "user can manage all organizations" do
    let(:user_with_permission) do
      create(:admin, user_permissions: [build(:user_permission, permission_slug: :manage_facilities)])
    end

    permissions :index? do
      it "allows the user" do
        expect(subject).to permit(user_with_permission, Facility)
      end
    end

    permissions :show?, :new?, :create?, :edit?, :update?, :destroy? do
      it "allows the user for all facilities" do
        expect(subject).to permit(user_with_permission, facility_1)
        expect(subject).to permit(user_with_permission, facility_2)
      end
    end
  end

  context "user can manage facilities for an organization" do
    let(:user_with_permission) do
      create(:admin, user_permissions: [
        build(:user_permission, permission_slug: :manage_facilities, resource: organization)
      ])
    end

    permissions :index? do
      it "allows the user" do
        expect(subject).to permit(user_with_permission, Facility)
      end
    end

    permissions :show?, :new?, :create?, :edit?, :update?, :destroy? do
      it "allows the user for facility in their organization" do
        expect(subject).to permit(user_with_permission, facility_1)
      end

      it "denies the user for facility outside their organization" do
        expect(subject).not_to permit(user_with_permission, facility_2)
      end
    end
  end

  context "user can manage facilities for a facility group" do
    let(:facility_group_1) { create(:facility_group) }
    let(:facility_group_2) { create(:facility_group) }

    let(:user_with_permission) do
      create(:admin, user_permissions: [
        build(:user_permission, permission_slug: :manage_facilities, resource: facility_group)
      ])
    end

    permissions :index? do
      it "allows the user" do
        expect(subject).to permit(user_with_permission, FacilityGroup)
      end
    end

    permissions :show?, :new?, :create?, :edit?, :update?, :destroy? do
      it "allows the user for facilities in their facility groups" do
        expect(subject).to permit(user_with_permission, facility_1)
      end

      it "denies the user for facilities outside facility groups" do
        expect(subject).not_to permit(user_with_permission, facility_2)
      end
    end
  end
end

RSpec.describe Manage::Facility::FacilityPolicy::Scope do
  let(:subject) { described_class }
  let(:organization) { create(:organization) }
  let(:facility_group_1) { create(:facility_group, organization: organization) }
  let(:facility_group_2) { create(:facility_group, organization: organization) }
  let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
  let!(:facility_2) { create(:facility, facility_group: facility_group_2) }
  let!(:facility_3) { create(:facility) }

  context "user can manage all organizations" do
    let(:user_with_permission) do
      create(:admin, user_permissions: [build(:user_permission, permission_slug: :manage_facilities)])
    end

    it "resolve all facilities " do
      resolved_records = subject.new(user_with_permission, Facility.all).resolve
      expect(resolved_records).to match_array(Facility.all)
    end
  end

  context "user can manage facilities for an organization" do
    let(:user_with_permission) do
      create(:admin, user_permissions: [
        build(:user_permission, permission_slug: :manage_facilities, resource: organization)
      ])
    end

    it "resolve all facilities in their organization" do
      resolved_records = subject.new(user_with_permission, Facility.all).resolve
      expect(resolved_records).to match_array([facility_1, facility_2])
    end
  end

  context "user can manage facilities for a facility group" do
    let(:user_with_permission) do
      create(:admin, user_permissions: [
        build(:user_permission, permission_slug: :manage_facilities, resource: facility_group_1)
      ])
    end

    it "resolve to their facilities in their facility group" do
      resolved_records = subject.new(user_with_permission, Facility.all).resolve
      expect(resolved_records).to match_array([facility_1])
    end
  end

  context "other users" do
    let(:other_user) do
      create(:admin, user_permissions: [])
    end

    it "resolves an empty set" do
      resolved_records = subject.new(other_user, Facility.all).resolve
      expect(resolved_records).to be_empty
    end
  end
end
