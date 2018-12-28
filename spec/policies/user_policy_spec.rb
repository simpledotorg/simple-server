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
