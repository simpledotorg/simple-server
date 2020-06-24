require "rails_helper"

RSpec.describe OverdueList::PatientSummaryPolicy do
  subject { described_class }
  let(:user_with_permission) do
    create(
      :admin,
      user_permissions: [build(:user_permission, permission_slug: :download_overdue_list)]
    )
  end
  let(:user_without_permission) { create(:admin) }

  permissions :download? do
    it "permits user with the appropriate permissions" do
      expect(subject).to permit(user_with_permission, PatientSummary)
    end

    it "does not permit users without the appropriate permissions" do
      expect(subject).not_to permit(user_without_permission, PatientSummary)
    end
  end
end

RSpec.describe OverdueList::PatientSummaryPolicy::Scope do
  let(:subject) { described_class }
  let(:organization) { create(:organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let(:facility1) { create(:facility, facility_group: facility_group) }
  let(:facility2) { create(:facility) }
  let!(:appointment1) { create(:appointment, :overdue, facility: facility1) }
  let!(:appointment2) { create(:appointment, :overdue, facility: facility2) }

  context "user with permission to access patient summaries for all organizations" do
    let(:user) { create(:admin, user_permissions: [build(:user_permission, permission_slug: :view_overdue_list)]) }

    it "resolves all patient summaries for users who can access appointment information for all organizations" do
      resolved_records = subject.new(user, PatientSummary.all).resolve
      expect(resolved_records).to match_array(PatientSummary.all)
    end
  end

  context "user with permission to access patient summaries for an organization" do
    let(:user) do
      create(
        :admin,
        user_permissions: [build(:user_permission, permission_slug: :view_overdue_list, resource: organization)]
      )
    end

    it "resolves all patient summaries in the organization" do
      resolved_records = subject.new(user, PatientSummary.all).resolve
      expect(resolved_records)
        .to match_array(PatientSummary.where(next_appointment_facility_id: organization.facilities.pluck(:id)))
    end
  end

  context "user with permission to access patient summaries for a facility group" do
    let(:user) do
      create(
        :admin,
        user_permissions: [build(:user_permission, permission_slug: :view_overdue_list, resource: facility_group)]
      )
    end

    it "resolves all patient summaries in the facility group" do
      resolved_records = subject.new(user, PatientSummary.all).resolve
      expect(resolved_records)
        .to match_array(PatientSummary.where(next_appointment_facility_id: facility_group.facilities.pluck(:id)))
    end
  end

  context "other users" do
    let(:other_user) { create(:user) }

    it "resolves no patient summaries other users" do
      resolved_records = subject.new(other_user, PatientSummary.all).resolve
      expect(resolved_records).to be_empty
    end
  end
end
