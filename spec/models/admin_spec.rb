require 'rails_helper'

RSpec.describe Admin, type: :model do
  describe 'Associations' do
    it { should have_many(:admin_access_controls) }

    describe 'protocols' do
      before :all do
        create_list :protocol, 3
      end

      it 'lists all protocols for owners' do
        owner = create :admin, :owner

        expect(owner.protocols).to eq(Protocol.all)
      end

      it 'lists all protocols scoped by facility groups for other admins' do
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
      before :all do
        create_list :facilities, 3
      end

      it 'lists all facility groups for owners' do
        owner = create :admin, :owner

        expect(owner.facilities).to eq(Facility.all)
      end

      it 'lists admin facility groups for all other admins' do
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
      before :all do
        create_list :user, 3
      end

      it 'lists all users for owners' do
        owner = create :admin, :owner

        expect(owner.users).to eq(User.all)
      end

      it 'lists all users scoped by facility groups for other admins' do
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

  describe 'Validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:password) }
    it { should validate_presence_of(:role) }

    it { should define_enum_for(:role).with([:owner, :supervisor, :analyst, :organization_owner]) }
  end

  describe 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end
end
