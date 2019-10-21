require 'rails_helper'

RSpec.xdescribe Admin, type: :model do
  describe 'Associations' do
    it { should have_many(:admin_access_controls) }

    describe 'protocols' do
      before :each do
        create_list :protocol, 3
      end

      it 'lists all protocols for owners' do
        owner = create :admin, :owner

        expect(owner.protocols).to eq(Protocol.all)
      end

      it 'lists all protocols scoped by facility groups for other email_authentications' do
        protocol = Protocol.first
        facility_group = create :facility_group, protocol: protocol

        admin = create :admin, role: :organization_owner
        AdminAccessControl.create(admin: admin, access_controllable: facility_group.organization)

        expect(admin.protocols).to eq([protocol])

        Admin.roles.except(:owner, :organization_owner).each do |role|
          admin = create :admin, role: role.first
          AdminAccessControl.create(admin: admin, access_controllable: facility_group)

          expect(admin.protocols).to eq([protocol])
        end
      end
    end

    describe 'facilities' do
      before :each do
        create_list :facility, 3
      end

      it 'lists all facility groups for owners' do
        owner = create :admin, :owner

        expect(owner.facilities).to eq(Facility.all)
      end

      it 'lists admin facility groups for all other email_authentications' do
        facility = Facility.first

        admin = create :admin, role: :organization_owner
        AdminAccessControl.create(admin: admin, access_controllable: facility.facility_group.organization)

        expect(admin.facilities).to eq([facility])

        Admin.roles.except(:owner, :organization_owner).each do |role|
          admin = create :admin, role: role.first
          AdminAccessControl.create(admin: admin, access_controllable: facility.facility_group)

          expect(admin.facilities).to eq([facility])
        end
      end
    end

    describe 'users' do
      before :each do
        create_list :user, 3
      end

      it 'lists all users for owners' do
        owner = create :admin, :owner

        expect(owner.users).to eq(User.all)
      end

      it 'lists all users scoped by facility groups for other email_authentications' do
        facility_group = FacilityGroup.first
        users = facility_group.users

        admin = create :admin, role: :organization_owner
        AdminAccessControl.create(admin: admin, access_controllable: facility_group.organization)

        expect(admin.users).to eq(users)

        Admin.roles.except(:owner, :organization_owner).each do |role|
          admin = create :admin, role: role.first
          AdminAccessControl.create(admin: admin, access_controllable: facility_group)

          expect(admin.users).to eq(users)
        end
      end
    end
  end

  context 'Validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:password) }
    it { should validate_presence_of(:role) }

    it { should define_enum_for(:role).with([:owner, :supervisor, :analyst, :organization_owner, :counsellor]) }
  end

  context 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end

  context 'Utility methods' do
    describe "#has_role?" do
      let(:owner) { create(:admin, :owner) }
      let(:supervisor) { create(:admin, :supervisor) }

      it "returns true for matching roles as strings" do
        expect(owner.has_role?("owner", "analyst")).to eq(true)
      end

      it "returns true for matching roles as symbols" do
        expect(owner.has_role?(:owner, :analyst)).to eq(true)
      end

      it "returns true when passed a single matching role" do
        expect(supervisor.has_role?(:supervisor)).to eq(true)
      end

      it "returns false for no matching roles" do
        expect(supervisor.has_role?(:fake_role)).to eq(false)
      end
    end
  end
end
