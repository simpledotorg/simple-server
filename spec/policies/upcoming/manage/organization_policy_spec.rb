require "rails_helper"

RSpec.describe Upcoming::Manage::OrganizationPolicy do
  subject { described_class }

  context "user can manage all organizations" do
    let!(:super_admin) { create(:admin) }

    let!(:organization_1) { create(:organization) }
    let!(:organization_2) { create(:organization) }
    let!(:super_admin_access) { create(:access, user: super_admin, role: :super_admin, resource: nil) }

    permissions :allowed? do
      it "allows the user" do
        expect(subject).to permit(super_admin, organization_1)
        expect(subject).to permit(super_admin, organization_2)
      end
    end
  end

  context "user can manage an organization" do
    let!(:organization_1) { create(:organization) }
    let!(:organization_2) { create(:organization) }

    let!(:admin) { create(:admin) }

    let!(:admin_access) { create(:access, user: admin, role: :admin, resource: organization_1) }

    permissions :allowed? do
      it "allows the user" do
        expect(subject).to permit(admin, organization_1)
      end

      it "denies the user" do
        expect(subject).not_to permit(admin, organization_2)
      end
    end
  end
end

RSpec.describe Upcoming::Manage::OrganizationPolicy::Scope do
  let(:subject) { described_class }
  let(:organization_1) { create(:organization) }
  let(:organization_2) { create(:organization) }

  context "user can manage all organizations" do
    let!(:super_admin) { create(:admin) }
    let!(:super_admin_access) { create(:access, user: super_admin, role: :super_admin, resource: nil) }

    it "resolve all organizations" do
      resolved_records = subject.new(super_admin, Organization).resolve
      expect(resolved_records).to match_array(Organization.all)
    end
  end

  context "user can manage an organization" do
    let!(:admin) { create(:admin) }
    let!(:admin_access) { create(:access, user: admin, role: :admin, resource: organization_1) }

    it "resolves their organization" do
      resolved_records = subject.new(admin, Organization).resolve
      expect(resolved_records).to match_array([organization_1])
    end
  end

  context "other users" do
    let(:other_user) { create(:admin) }

    it "resolves an empty set" do
      resolved_records = subject.new(other_user, Organization).resolve
      expect(resolved_records).to be_empty
    end
  end
end
