require "rails_helper"

RSpec.describe FacilityPolicy do
  subject { described_class }

  let(:organization) { FactoryBot.create(:organization) }
  let!(:facility_group) { FactoryBot.create(:facility_group, organization: organization) }

  let(:owner) { FactoryBot.create(:admin, :owner) }
  let(:organization_owner) { FactoryBot.create(:admin, :organization_owner, admin_access_controls: [AdminAccessControl.new(access_controllable: organization)]) }
  let(:supervisor) { FactoryBot.create(:admin, :supervisor, admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group)]) }
  let(:analyst) { FactoryBot.create(:admin, :analyst) }

  permissions :show? do
    it "denies organization owners for facilities outside their organizations" do
      facility = FactoryBot.create(:facility)
      expect(subject).not_to permit(organization_owner, facility)
    end

    it "denies supervisors for facilities outside their facility group" do
      facility = FactoryBot.create(:facility)
      expect(subject).not_to permit(supervisor, facility)
    end
  end

  permissions :index?, :show? do
    it "permits owners" do
      expect(subject).to permit(owner, Facility)
    end

    it "permits organization owners for facilities in their organizations" do
      facility = FactoryBot.create(:facility, facility_group: organization_owner.facility_groups.first)
      expect(subject).to permit(organization_owner, facility)
    end

    it "permits supervisors for facilities in their facility group" do
      facility = FactoryBot.create(:facility, facility_group: supervisor.facility_groups.first)
      expect(subject).to permit(supervisor, facility)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, Facility)
    end
  end

  permissions :new?, :create?, :update?, :edit? do
    it "permits owners" do
      expect(subject).to permit(owner, Facility)
    end

    it "permits organization owners" do
      expect(subject).to permit(owner, Facility)
    end

    it "denies supervisors" do
      expect(subject).not_to permit(supervisor, Facility)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, Facility)
    end
  end

  permissions :destroy? do
    let!(:facility_group) { create(:facility_group, organization: organization) }
    let!(:facility) { create(:facility, facility_group: facility_group) }

    it "permits owners" do
      expect(subject).to permit(owner, facility)
    end

    it "permits organization owners" do
      expect(subject).to permit(owner, facility)
    end

    it "denies supervisors" do
      expect(subject).not_to permit(supervisor, facility)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, facility)
    end

    context "with associated patients" do
      before do
        facility.registered_patients << create(:patient)
      end

      it "denies everyone" do
        expect(subject).not_to permit(owner, facility)
        expect(subject).not_to permit(organization_owner, facility)
      end
    end

    context "with associated blood pressures" do
      before do
        create(:blood_pressure, facility: facility)
      end

      it "denies everyone" do
        expect(subject).not_to permit(owner, facility)
        expect(subject).not_to permit(organization_owner, facility)
      end
    end
  end
end

RSpec.describe FacilityPolicy::Scope do
  let(:subject) { described_class }
  let(:organization) { create(:organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let!(:facility_1) { create(:facility, facility_group: facility_group) }
  let!(:facility_2) { create(:facility, facility_group: facility_group) }
  let!(:facility_3) { create(:facility) }

  describe "owner" do
    let(:owner) { create(:admin, :owner) }
    it "resolves all facilities" do
      resolved_records = subject.new(owner, Facility.all).resolve
      expect(resolved_records.to_a).to match_array(Facility.all.to_a)
    end
  end

  describe "organization owner" do
    let(:organization_owner) {
      create(:admin,
             :organization_owner,
             admin_access_controls: [AdminAccessControl.new(access_controllable: organization)]
      ) }
    it "resolves facility for their organizations" do
      resolved_records = subject.new(organization_owner, Facility.all).resolve
      expect(resolved_records).to match_array([facility_1, facility_2])
    end
  end

  describe "supervisor" do
    let(:supervisor) {
      create(:admin,
             :supervisor,
             admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group)])
    }
    it "resolves facilities of their facility groups" do
      resolved_records = subject.new(supervisor, Facility.all).resolve
      expect(resolved_records).to match_array([facility_1, facility_2])
    end
  end

  describe "analyst" do
    let(:analyst) {
      create(:admin,
             :analyst,
             admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group)])
    }
    it "resolves facilities of their facility groups" do
      resolved_records = subject.new(analyst, Facility.all).resolve
      expect(resolved_records).to match_array([facility_1, facility_2])
    end
  end
end
