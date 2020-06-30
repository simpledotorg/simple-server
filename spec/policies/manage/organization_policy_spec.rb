require "rails_helper"

RSpec.describe Manage::OrganizationPolicy do
  subject { described_class }
  let(:organization_1) { create(:organization) }
  let(:organization_2) { create(:organization) }

  context "user can manage all organizations" do
    let(:user_with_permission) do
      create(:admin, user_permissions: [build(:user_permission, permission_slug: :manage_organizations)])
    end

    permissions :index? do
      it "allows the user" do
        expect(subject).to permit(user_with_permission, Organization)
      end
    end

    permissions :show?, :new?, :create?, :edit?, :update?, :destroy? do
      it "allows the user" do
        expect(subject).to permit(user_with_permission, organization_1)
        expect(subject).to permit(user_with_permission, organization_2)
      end
    end
  end

  context "user can manage an organization" do
    let(:user_with_permission) do
      create(:admin, user_permissions: [
        build(:user_permission, permission_slug: :manage_organizations, resource: organization_1)
      ])
    end

    permissions :index? do
      it "allows the user" do
        expect(subject).to permit(user_with_permission, Organization)
      end
    end

    permissions :show?, :edit?, :update? do
      it "allows the user for their organization" do
        expect(subject).to permit(user_with_permission, organization_1)
      end

      it "denies the user for other organizations" do
        expect(subject).not_to permit(user_with_permission, organization_2)
      end
    end

    permissions :destroy?, :new?, :create? do
      it "denies the user" do
        expect(subject).not_to permit(user_with_permission, organization_1)
        expect(subject).not_to permit(user_with_permission, organization_2)
      end
    end
  end
end

RSpec.describe Manage::OrganizationPolicy::Scope do
  let(:subject) { described_class }
  let!(:organization_1) { create(:organization) }
  let!(:organization_2) { create(:organization) }

  context "user can manage all organizations" do
    let(:user_with_permission) do
      create(:admin, user_permissions: [build(:user_permission, permission_slug: :manage_organizations)])
    end

    it "resolve all organizations" do
      resolved_records = subject.new(user_with_permission, Organization.all).resolve
      expect(resolved_records).to match_array(Organization.all)
    end
  end

  context "user can manage an organization" do
    let(:user_with_permission) do
      create(:admin, user_permissions: [
        build(:user_permission, permission_slug: :manage_organizations, resource: organization_1)
      ])
    end

    it "resolves their organization" do
      resolved_records = subject.new(user_with_permission, Organization.all).resolve
      expect(resolved_records).to match_array([organization_1])
    end
  end

  context "other users" do
    let(:other_user) do
      create(:admin, user_permissions: [])
    end

    it "resolves an empty set" do
      resolved_records = subject.new(other_user, Organization.all).resolve
      expect(resolved_records).to be_empty
    end
  end
end
