require "rails_helper"

RSpec.describe UserPolicy do
  subject { described_class }

  let!(:organization) { FactoryBot.create(:organization) }
  let!(:facility_group) { FactoryBot.create(:facility_group, organization: organization) }
  let!(:facility) { FactoryBot.create(:facility, facility_group: facility_group) }

  let(:owner) { FactoryBot.create(:admin, :owner) }
  let(:organization_owner) { FactoryBot.create(:admin, :organization_owner, admin_access_controls: [AdminAccessControl.new(access_controllable: organization)]) }
  let(:supervisor) { FactoryBot.create(:admin, :supervisor, admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group)]) }
  let(:analyst) { FactoryBot.create(:admin, :supervisor, admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group)]) }
  let(:counsellor) { FactoryBot.create(:admin, :counsellor) }

  permissions :index? do
    it "permits owners" do
      expect(subject).to permit(owner, User)
    end

    it "permits organization owners" do
      expect(subject).to permit(owner, User)
    end

    it "permits supervisors" do
      expect(subject).to permit(owner, User)
    end

    it "permits analysts" do
      expect(subject).to permit(analyst, User)
    end

    it "denies counsellors" do
      expect(subject).not_to permit(counsellor, User)
    end
  end

  permissions :new?, :create?, :destroy? do
    it "denies owners" do
      expect(subject).not_to permit(owner, User)
    end

    it "denies organization owners" do
      expect(subject).not_to permit(owner, User)
    end

    it "denies supervisors" do
      expect(subject).not_to permit(owner, User)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, User)
    end

    it "denies counsellors" do
      expect(subject).not_to permit(counsellor, User)
    end
  end

  permissions :show? do
    it "permits owners" do
      expect(subject).to permit(owner, User)
    end

    it "permits organization owners for facilities in their organizations" do
      user = FactoryBot.create(:user, registration_facility: organization_owner.facilities.first)
      expect(subject).to permit(organization_owner, user)
    end

    it "denies organization owners for facilities outside their organizations" do
      user = FactoryBot.create(:user)
      expect(subject).not_to permit(organization_owner, user)
    end

    it "permits supervisors for facilities in their facility group" do
      user = FactoryBot.create(:user, registration_facility: supervisor.facilities.first)
      expect(subject).to permit(supervisor, user)
    end

    it "denies supervisors for facilities outside their facility group" do
      user = FactoryBot.create(:user)
      expect(subject).not_to permit(supervisor, user)
    end

    it "permits analysts for facilities in their facility group" do
      user = FactoryBot.create(:user, registration_facility: analyst.facilities.first)
      expect(subject).to permit(analyst, user)
    end

    it "denies analysts for facilities outside their facility group" do
      user = FactoryBot.create(:user)
      expect(subject).not_to permit(analyst, user)
    end

    it "denies counsellors" do
      expect(subject).not_to permit(counsellor, User)
    end
  end

  permissions :update?, :edit?, :disable_access?, :enable_access?, :reset_otp? do
    it "permits owners" do
      expect(subject).to permit(owner, User)
    end

    it "permits organization owners for facilities in their organizations" do
      user = FactoryBot.create(:user, registration_facility: organization_owner.facilities.first)
      expect(subject).to permit(organization_owner, user)
    end

    it "denies organization owners for facilities outside their organizations" do
      user = FactoryBot.create(:user)
      expect(subject).not_to permit(organization_owner, user)
    end

    it "permits supervisors for facilities in their facility group" do
      user = FactoryBot.create(:user, registration_facility: supervisor.facilities.first)
      expect(subject).to permit(supervisor, user)
    end

    it "denies supervisors for facilities outside their facility group" do
      user = FactoryBot.create(:user)
      expect(subject).not_to permit(supervisor, user)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, User)
    end

    it "denies counsellors" do
      expect(subject).not_to permit(counsellor, User)
    end
  end
end

RSpec.describe UserPolicy::Scope do
  let(:subject) { described_class }
  let!(:organization) { create(:organization) }
  let!(:facility_group) { create(:facility_group, organization: organization) }
  let!(:facility) { create(:facility, facility_group: facility_group) }
  let!(:user_1) { create(:user, registration_facility: facility) }
  let!(:user_2) { create(:user, registration_facility: facility) }
  let!(:user_3) { create(:user) }

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
             admin_access_controls: [AdminAccessControl.new(access_controllable: organization)]
      ) }
    it "resolves user for their organizations" do
      resolved_records = subject.new(organization_owner, User.all).resolve
      expect(resolved_records).to match_array([user_1, user_2])
    end
  end

  describe "supervisor" do
    let(:supervisor) {
      create(:admin,
             :supervisor,
             admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group)])
    }
    it "resolves users of their facility groups" do
      resolved_records = subject.new(supervisor, User.all).resolve
      expect(resolved_records).to match_array([user_1, user_2])
    end
  end

  describe "analyst" do
    let(:analyst) {
      create(:admin,
             :analyst,
             admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group)])
    }
    it "resolves users of their facility groups" do
      resolved_records = subject.new(analyst, User.all).resolve
      expect(resolved_records).to match_array([user_1, user_2])
    end
  end

  describe "counsellor" do
    let(:counsellor) {
      create(:admin,
             :counsellor,
             admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group)])
    }
    it "resolves to no users" do
      resolved_records = subject.new(counsellor, User.all).resolve
      expect(resolved_records).to be_empty
    end
  end
end
