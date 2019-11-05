require "rails_helper"

RSpec.describe AdminPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:supervisor) { create(:admin, :supervisor) }
  let(:analyst) { create(:admin, :analyst) }

  permissions :index?, :show?, :new?, :create?, :update?, :edit?, :destroy? do
    it "permits owners" do
      expect(subject).to permit(owner, Admin)
    end

    it "denies supervisors" do
      expect(subject).not_to permit(supervisor, Admin)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, Admin)
    end
  end
end

RSpec.describe AdminPolicy::Scope do
  let(:subject) { described_class }

  before :each do
    FactoryBot.create_list(:admin, 2, :owner)
    FactoryBot.create_list(:admin, 2, :organization_owner)
    FactoryBot.create_list(:admin, 2, :supervisor)
    FactoryBot.create_list(:admin, 2, :analyst)
  end

  describe "owner" do
    let(:owner) { FactoryBot.create(:admin, :owner) }

    it "resolves all admins" do
      resolved_records = subject.new(owner, Admin.all).resolve
      expect(resolved_records.to_a).to match_array(Admin.all.to_a)
    end
  end

  describe "organization owner" do
    let(:organization) { FactoryBot.create(:organization) }
    let(:facility_group) { FactoryBot.create(:facility_group, organization: organization) }
    let(:organization_owner) {
      FactoryBot.create(
        :admin,
        :organization_owner,
        admin_access_controls: [AdminAccessControl.new(access_controllable: organization)]
      )
    }

    let!(:organization_owners_in_same_organization) {
      organization_owners = []
      2.times do
        organization_owners << FactoryBot.create(
          :admin,
          :organization_owner,
          admin_access_controls: [AdminAccessControl.new(access_controllable: organization)])
      end
      organization_owners
    }

    let!(:supervisors_in_same_organization) {
      supervisors = []
      2.times do
        supervisors << FactoryBot.create(
          :admin,
          :supervisor,
          admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group)])
      end
      supervisors
    }

    it "resolves all admins belonging to the same organization" do
      resolved_records = subject.new(organization_owner, Admin.all).resolve
      expect(resolved_records.to_a)
        .to match_array([organization_owner] +
                          organization_owners_in_same_organization +
                          supervisors_in_same_organization)
    end
  end

  describe "supervisor" do
    let(:supervisor) { FactoryBot.create(:admin, :supervisor) }
    it "resolves no admins" do
      resolved_records = subject.new(supervisor, Admin.all).resolve
      expect(resolved_records).to be_empty
    end
  end

  describe "analyst" do
    let(:analyst) { FactoryBot.create(:admin, :analyst) }
    it "resolves no admins" do
      resolved_records = subject.new(analyst, Admin.all).resolve
      expect(resolved_records).to be_empty
    end
  end
end
