require "rails_helper"

RSpec.describe OverdueList::PatientPolicy do
  subject { described_class }

  let(:patient) { build(:patient) }

  context "user with permission to view overdue list" do
    let(:user_with_permission) do
      create(:admin, user_permissions: [
        build(:user_permission, permission_slug: :view_overdue_list)
      ])
    end

    permissions :lookup? do
      it "permits the user" do
        expect(subject).to permit(user_with_permission, Patient)
      end
    end
  end
end

RSpec.describe OverdueList::PatientPolicy::Scope do
  let(:subject) { described_class }

  let(:organization) { create(:organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }

  let(:facility1) { create(:facility, facility_group: facility_group) }
  let(:facility2) { create(:facility) }

  let!(:patient1) { create(:patient, registration_facility: facility1) }
  let!(:patient2) { create(:patient, registration_facility: facility2) }
  let!(:patient3) { create(:patient) }

  context "user with permission to access patient information for all organizations" do
    let(:user) do
      create(:admin, user_permissions: [
        build(:user_permission, permission_slug: :view_overdue_list)
      ])
    end

    it "resolves all patients for users who can access appointment information for all organizations" do
      resolved_records = subject.new(user, Patient).resolve
      expect(resolved_records).to match_array(Patient.all)
    end
  end

  context "user with permission to access patient information for an organization" do
    let(:user) do
      create(:admin, user_permissions: [
        build(:user_permission, permission_slug: :view_overdue_list, resource: organization)
      ])
    end

    it "resolves all patients in the organization" do
      resolved_records = subject.new(user, Patient).resolve
      expect(resolved_records).to match_array(Patient.where(registration_facility: organization.facilities))
    end
  end

  context "user with permission to access patient information for a facility group" do
    let(:user) do
      create(:admin, user_permissions: [
        build(:user_permission, permission_slug: :view_overdue_list, resource: facility_group)
      ])
    end

    it "resolves all patients in the facility group" do
      resolved_records = subject.new(user, Patient).resolve
      expect(resolved_records).to match_array(Patient.where(registration_facility: facility_group.facilities))
    end
  end

  context "other users" do
    let(:other_user) { create(:user) }

    it "resolves no appointments other users" do
      resolved_records = subject.new(other_user, Patient).resolve
      expect(resolved_records).to match_array(Patient.none)
    end
  end
end
