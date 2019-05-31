require "rails_helper"

RSpec.describe FacilityPolicy do
  subject { described_class }

  let(:organization) { create(:organization) }

  let(:facility_group) { create(:facility_group, organization: organization) }
  let(:facility_group_2) { create(:facility_group, organization: organization) }
  let(:facility_in_facility_group) { create(:facility, facility_group: facility_group) }
  let(:facility_in_facility_group_2) { create(:facility, facility_group: facility_group_2) }
  let(:facility_outside_facility_group) { create(:facility) }

  let(:user_can_manage_all_organizations) do
    user = create(:master_user)
    create(:user_permission, user: user, permission_slug: :can_manage_all_organizations, resource: nil)
    user
  end

  let(:user_can_manage_facility_groups_in_organization) do
    user = create(:master_user)
    create(:user_permission,
           user: user,
           permission_slug: :can_manage_facility_groups_for_organization,
           resource: organization)
    user
  end

  let(:user_can_view_facilities_in_facility_group) do
    user = create(:master_user)
    create(:user_permission,
           user: user,
           permission_slug: :can_view_facilities_in_facility_group,
           resource: facility_group)
    user
  end

  let(:other_user) { create(:master_user) }

  permissions :show? do
    it "permits users who can manage all organizations" do
      expect(subject).to permit(user_can_manage_all_organizations, facility_in_facility_group)
      expect(subject).to permit(user_can_manage_all_organizations, facility_in_facility_group_2)
      expect(subject).to permit(user_can_manage_all_organizations, facility_outside_facility_group)
    end

    it "permits users who can manage facility groups for an organization" do
      expect(subject).to permit(user_can_manage_facility_groups_in_organization, facility_in_facility_group)
    end

    it 'permits users who can manage facilities in a facility group' do
      expect(subject).to permit(user_can_view_facilities_in_facility_group, facility_in_facility_group)
    end

    it "denies users who can manage facility groups for an organisation for facilities outside their organisation" do
      expect(subject).not_to permit(user_can_manage_facility_groups_in_organization, facility_outside_facility_group)
    end

    it 'denies users who can manage facilities in a facility group for facilities outside the facility group' do
      expect(subject).not_to permit(user_can_view_facilities_in_facility_group, facility_outside_facility_group)
    end

    it 'denies other users' do
      expect(subject).not_to permit(other_user, facility_in_facility_group)
    end
  end

  permissions :new?, :create?, :update?, :edit? do
    it "permits users who can manage all organizations" do
      expect(subject).to permit(user_can_manage_all_organizations, facility_in_facility_group)
      expect(subject).to permit(user_can_manage_all_organizations, facility_in_facility_group_2)
      expect(subject).to permit(user_can_manage_all_organizations, facility_outside_facility_group)
    end

    it "permits users who can manage facility groups for an organization" do
      expect(subject).to permit(user_can_manage_facility_groups_in_organization, facility_in_facility_group)
    end

    it 'permits users who can manage facilities in a facility group' do
      expect(subject).not_to permit(user_can_view_facilities_in_facility_group, facility_in_facility_group)
    end

    it "denies users who can manage facility groups for an organisation for facilities outside their organisation" do
      expect(subject).not_to permit(user_can_manage_facility_groups_in_organization, facility_outside_facility_group)
    end

    it 'denies users who can manage facilities in a facility group for facilities outside the facility group' do
      expect(subject).not_to permit(user_can_view_facilities_in_facility_group, facility_outside_facility_group)
    end

    it 'denies other users' do
      expect(subject).not_to permit(other_user, facility_in_facility_group)
    end
  end


  permissions :destroy? do
    it "permits users who can manage facility groups for an organization" do
      expect(subject).to permit(user_can_manage_facility_groups_in_organization, facility_in_facility_group)
      expect(subject).to permit(user_can_manage_facility_groups_in_organization, facility_in_facility_group_2)
    end

    it "permits users who can manage facility for an facility group" do
      expect(subject).to permit(user_can_manage_facility_groups_in_organization, facility_in_facility_group)
      expect(subject).to permit(user_can_manage_facility_groups_in_organization, facility_in_facility_group_2)
    end

    it "permits users who can manage all organizations" do
      expect(subject).to permit(user_can_manage_all_organizations, facility_in_facility_group)
      expect(subject).to permit(user_can_manage_all_organizations, facility_outside_facility_group)
    end

    it "denies users who can manage facility groups for an organisation for facilities outside their organisation" do
      expect(subject).not_to permit(user_can_manage_facility_groups_in_organization, facility_outside_facility_group)
    end

    it 'denies users who can manage facilities in a facility group for facilities outside the facility group' do
      expect(subject).not_to permit(user_can_view_facilities_in_facility_group, facility_outside_facility_group)
    end

    it 'denies other users' do
      expect(subject).not_to permit(other_user, facility_in_facility_group)
    end

    context "with associated patients" do
      before do
        create(:patient, registration_facility: facility_in_facility_group)
      end

      it "denies everyone" do
        expect(subject).not_to permit(user_can_manage_all_organizations, facility_in_facility_group)
        expect(subject).not_to permit(user_can_manage_facility_groups_in_organization, facility_in_facility_group)
        expect(subject).not_to permit(user_can_view_facilities_in_facility_group, facility_in_facility_group)
      end
    end

    context "with associated blood pressures" do
      before do
        create(:blood_pressure, facility: facility_in_facility_group)
      end

      it "denies everyone" do
        expect(subject).not_to permit(user_can_manage_all_organizations, facility_in_facility_group)
        expect(subject).not_to permit(user_can_manage_facility_groups_in_organization, facility_in_facility_group)
        expect(subject).not_to permit(user_can_view_facilities_in_facility_group, facility_in_facility_group)
      end
    end
  end
end

RSpec.describe FacilityPolicy::Scope do
  let(:subject) { described_class }
  let(:organization) { create(:organization) }
  let!(:facility_group_1) { create(:facility_group, organization: organization) }
  let!(:facility_group_2) { create(:facility_group, organization: organization) }

  let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
  let!(:facility_2) { create(:facility, facility_group: facility_group_2) }
  let!(:facility_3) { create(:facility) }

  let(:user_can_manage_facility_groups_in_organization) do
    user = create(:master_user)
    create(:user_permission,
           user: user,
           permission_slug: :can_manage_facility_groups_for_organization,
           resource: organization)
    user
  end

  let(:user_can_manage_facility_in_facility_groups) do
    user = create(:master_user)
    create(:user_permission,
           user: user,
           permission_slug: :can_view_facilities_in_facility_group,
           resource: facility_group_1)
    user
  end

  let(:user_can_manage_all_organizations) do
    user = create(:master_user)
    create(:user_permission, user: user, permission_slug: :can_manage_all_organizations, resource: nil)
    user
  end

  let(:other_user) { create(:master_user) }

  context 'user has permission to manage all organizations' do
    it "resolves all facility" do
      resolved_records = subject.new(user_can_manage_all_organizations, Facility.all).resolve
      expect(resolved_records.to_a).to match_array(Facility.all.to_a)
    end
  end
  context 'user has permission to manage facility groups in an organization' do
    it "resolves all facilities in the organization" do
      resolved_records = subject.new(user_can_manage_facility_groups_in_organization, Facility.all).resolve
      expect(resolved_records.to_a).to match_array([facility_1, facility_2])
    end
  end
  context 'user has permission to manage all facilites in a facility group' do
    it "resolves all facilities in a facility group" do
      resolved_records = subject.new(user_can_manage_facility_in_facility_groups, Facility.all).resolve
      expect(resolved_records.to_a).to match_array([facility_1])
    end
  end
  context 'other users' do
    it "resolves no facilities " do
      resolved_records = subject.new(other_user, Facility.all).resolve
      expect(resolved_records.to_a).to be_empty
    end
  end
end
