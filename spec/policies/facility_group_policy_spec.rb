require "rails_helper"

RSpec.describe FacilityGroupPolicy do
  subject { described_class }

  let(:organization) { FactoryBot.create(:organization) }
  let!(:facility_group_in_organization) { FactoryBot.create(:facility_group, organization: organization) }
  let!(:facility_group_outside_organization) { FactoryBot.create(:facility_group) }

  let(:user_can_manage_facility_groups_in_organization) do
    user = create(:master_user)
    create(:user_permission,
           user: user,
           permission_slug: :can_manage_facility_groups_for_organization,
           resource: organization)
    user
  end

  let(:user_can_manage_all_organizations) do
    user = create(:master_user)
    create(:user_permission, user: user, permission_slug: :can_manage_all_organizations, resource: nil)
    user
  end

  permissions :show?, :new?, :create?, :update?, :edit? do
    it "permits users who can manage facility groups for an organization" do
      expect(subject).to permit(user_can_manage_facility_groups_in_organization, facility_group_in_organization)
      expect(subject).not_to permit(user_can_manage_facility_groups_in_organization, facility_group_outside_organization)
    end

    it "permits users who can manage all organizations" do
      expect(subject).to permit(user_can_manage_all_organizations, facility_group_in_organization)
      expect(subject).to permit(user_can_manage_all_organizations, facility_group_outside_organization)
    end
  end

  permissions :destroy? do
    it "permits users who can manage facility groups for an organization" do
      expect(subject).to permit(user_can_manage_facility_groups_in_organization, facility_group_in_organization)
      expect(subject).not_to permit(user_can_manage_facility_groups_in_organization, facility_group_outside_organization)
    end

    it "permits users who can manage all organizations" do
      expect(subject).to permit(user_can_manage_all_organizations, facility_group_in_organization)
      expect(subject).to permit(user_can_manage_all_organizations, facility_group_outside_organization)
    end

    context "with associated facilities" do
      before do
        create(:facility, facility_group: facility_group_in_organization)
      end

      it "denies everyone" do
        expect(subject).not_to permit(user_can_manage_facility_groups_in_organization, facility_group_in_organization)
        expect(subject).not_to permit(user_can_manage_all_organizations, facility_group_in_organization)
      end
    end

    context "with associated patients" do
      before do
        facility = create(:facility, facility_group: facility_group_in_organization)
        create(:patient, registration_facility: facility)
      end

      it "denies everyone" do
        expect(subject).not_to permit(user_can_manage_facility_groups_in_organization, facility_group_in_organization)
        expect(subject).not_to permit(user_can_manage_all_organizations, facility_group_in_organization)
      end
    end

    context "with associated blood pressures" do
      before do
        facility = create(:facility, facility_group: facility_group_in_organization)
        create(:blood_pressure, facility: facility)
      end

      it "denies everyone" do
        expect(subject).not_to permit(user_can_manage_facility_groups_in_organization, facility_group_in_organization)
        expect(subject).not_to permit(user_can_manage_all_organizations, facility_group_in_organization)
      end
    end
  end
end

RSpec.describe FacilityGroupPolicy::Scope do
  let(:subject) { described_class }
  let(:organization) { create(:organization) }
  let!(:facility_group_1) { create(:facility_group, organization: organization) }
  let!(:facility_group_2) { create(:facility_group, organization: organization) }
  let!(:facility_group_3) { create(:facility_group) }

  let(:user_can_manage_facility_groups_in_organization) do
    user = create(:master_user)
    create(:user_permission,
           user: user,
           permission_slug: :can_manage_facility_groups_for_organization,
           resource: organization)
    user
  end

  let(:user_can_manage_all_organizations) do
    user = create(:master_user)
    create(:user_permission, user: user, permission_slug: :can_manage_all_organizations, resource: nil)
    user
  end

  describe 'user has permission to manage all organizations' do
    it "resolves all facility groups" do
      resolved_records = subject.new(user_can_manage_all_organizations, FacilityGroup.all).resolve
      expect(resolved_records.to_a).to match_array(FacilityGroup.all.to_a)
    end

    it "resolves all facility groups" do
      resolved_records = subject.new(user_can_manage_facility_groups_in_organization, FacilityGroup.all).resolve
      expect(resolved_records.to_a).to match_array([facility_group_1, facility_group_2])
    end
  end
end
