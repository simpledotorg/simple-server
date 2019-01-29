require "rails_helper"

RSpec.describe UserPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:supervisor) { create(:admin, :supervisor) }
  let(:analyst) { create(:admin, :analyst) }
  let(:organization_owner) { create(:admin, :organization_owner) }

  permissions :index? do
    it "permits owners" do
      expect(subject).to permit(owner, User)
    end

    it "permits supervisors" do
      expect(subject).to permit(supervisor, User)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, User)
    end
  end

  permissions :show?, :enable_access?, :disable_access?, :reset_otp? do
    it "permits supervisors belonging to users facility groups" do
      facility = FactoryBot.build(:facility)
      facility_group = FactoryBot.create(:facility_group, facilities: [facility])
      supervisor = FactoryBot.create(
        :admin,
        :supervisor,
        admin_access_controls: [FactoryBot.create(:admin_access_control, access_controllable: facility_group)])

      user = FactoryBot.create(:user, facility: facility_group.facilities.first)

      expect(subject).to permit(supervisor, user)
    end

    it "denies supervisors outside of users facility groups" do
      facility = FactoryBot.build(:facility)
      facility_group = FactoryBot.create(:facility_group, facilities: [facility])
      user = FactoryBot.create(:user, facility: facility_group.facilities.first)

      expect(subject).not_to permit(supervisor, user)
    end

    it "permits organization_owners belonging to users organization" do
      facility = FactoryBot.build(:facility)
      facility_group = FactoryBot.create(:facility_group, facilities: [facility])
      organization_owner = FactoryBot.create(
        :admin,
        :organization_owner,
        admin_access_controls: [FactoryBot.create(:admin_access_control, access_controllable: facility_group.organization)])

      user = FactoryBot.create(:user, facility: facility_group.facilities.first)

      expect(subject).to permit(organization_owner, user)
    end

    it "denies organization_owners outside of users organization" do
      facility = FactoryBot.build(:facility)
      facility_group = FactoryBot.create(:facility_group, facilities: [facility])
      user = FactoryBot.create(:user, facility: facility_group.facilities.first)

      expect(subject).not_to permit(organization_owner, user)
    end
  end

  permissions :new?, :create?, :update?, :edit?, :destroy? do
    it "permits owners" do
      expect(subject).to permit(owner, User)
    end

    it "denies supervisors" do
      expect(subject).not_to permit(supervisor, User)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, User)
    end
  end
end

RSpec.describe UserPolicy::Scope do
  let(:subject) { described_class }
  let(:organization_1) { create(:organization) }
  let(:organization_2) { create(:organization) }

  let!(:facility_group_1) { create(:facility_group, organization: organization_1, facilities: create_list(:facility, 1)) }
  let!(:facility_group_2) { create(:facility_group, organization: organization_2, facilities: create_list(:facility, 1)) }

  let!(:_facility_group_1) { create(:facility_group, organization: organization_1, facilities: create_list(:facility, 1)) }
  let!(:_facility_group_2) { create(:facility_group, organization: organization_2, facilities: create_list(:facility, 1)) }


  let!(:user_1) { create(:user, facility: facility_group_1.facilities.first) }
  let!(:user_2) { create(:user, facility: facility_group_2.facilities.first) }
  let!(:user_3) { create(:user, facility: _facility_group_1.facilities.first) }
  let!(:user_4) { create(:user, facility: _facility_group_2.facilities.first) }

  before :each do
  end

  describe "owner" do
    let(:owner) { create(:admin, :owner) }
    it "resolves all users" do
      resolved_records = subject.new(owner, User.all).resolve
      expect(resolved_records.to_a).to match_array(User.all.to_a)
    end
  end

  describe "organization owner" do
    let(:organization_owner) {
      create(:admin,
             :organization_owner,
             admin_access_controls: [AdminAccessControl.new(access_controllable: organization_1)]
      ) }
    it "resolves all protocol drugs their organizations" do
      resolved_records = subject.new(organization_owner, User.all).resolve
      expect(resolved_records).to match_array([user_1, user_3])
    end
  end

  describe "supervisor" do
    let(:supervisor) {
      create(:admin,
             :supervisor,
             admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group_1)])
    }
    it "resolves all protocol drugs their facility groups" do
      resolved_records = subject.new(supervisor, User.all).resolve
      expect(resolved_records).to match_array([user_1])
    end
  end

  describe "analyst" do
    let(:analyst) {
      create(:admin,
             :analyst,
             admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group_1)])
    }
    it "resolves all protocol drugs facility group" do
      resolved_records = subject.new(analyst, User.all).resolve
      expect(resolved_records).to match_array([user_1])
    end
  end
end
