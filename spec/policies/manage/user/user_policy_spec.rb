require "rails_helper"

RSpec.describe Manage::User::UserPolicy do
  subject { described_class }

  let!(:organization) { create(:organization) }
  let!(:facility_group) { create(:facility_group, organization: organization) }
  let!(:facility) { create(:facility, facility_group: facility_group) }

  let(:user_1) { create(:user, registration_facility: facility) }
  let(:user_2) { build(:user) }

  context "user can manage users for all organizations" do
    let(:user_with_permission) do
      create(:admin, user_permissions: [build(:user_permission, permission_slug: :approve_health_workers)])
    end

    permissions :index? do
      it "allows the user" do
        expect(subject).to permit(user_with_permission, User)
      end
    end

    permissions :show?, :edit?, :update?, :disable_access?, :enable_access?, :reset_otp? do
      it "allows the user for all users" do
        expect(subject).to permit(user_with_permission, user_1)
        expect(subject).to permit(user_with_permission, user_2)
      end
    end
  end

  context "user can manage users for an organization" do
    let(:user_with_permission) do
      create(:admin, user_permissions: [build(:user_permission, permission_slug: :approve_health_workers, resource: user_1.organization)],
                     organization: user_1.organization)
    end

    permissions :index? do
      it "allows the user" do
        expect(subject).to permit(user_with_permission, User)
      end
    end

    permissions :show?, :edit?, :update?, :disable_access?, :enable_access?, :reset_otp? do
      it "allows the user for all users in the permitted organization" do
        expect(subject).to permit(user_with_permission, user_1)
      end

      it "denies the user for all users in other organization" do
        expect(subject).not_to permit(user_with_permission, user_2)
      end
    end
  end

  context "user can manage users for a facility group" do
    let(:user_with_permission) do
      create(:admin, user_permissions: [build(:user_permission, permission_slug: :approve_health_workers, resource: facility_group)])
    end

    permissions :index? do
      it "allows the user" do
        expect(subject).to permit(user_with_permission, User)
      end
    end

    permissions :show?, :edit?, :update?, :disable_access?, :enable_access?, :reset_otp? do
      it "allows the user for all users in the permitted facility group" do
        expect(subject).to permit(user_with_permission, user_1)
      end

      it "denies the user for all users in other facility_group" do
        expect(subject).not_to permit(user_with_permission, user_2)
      end
    end
  end
end

RSpec.describe Manage::User::UserPolicy::Scope do
  let(:subject) { described_class }
  let!(:organization) { create(:organization) }
  let!(:facility_group_1) { create(:facility_group, organization: organization) }
  let!(:facility_group_2) { create(:facility_group, organization: organization) }
  let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
  let!(:facility_2) { create(:facility, facility_group: facility_group_2) }
  let!(:user_1) { create(:user, registration_facility: facility_1) }
  let!(:user_2) { create(:user, registration_facility: facility_2) }
  let!(:user_3) { create(:user) }

  describe "User can manage all users" do
    let(:user_with_permission) do
      create(:admin, user_permissions: [build(:user_permission, permission_slug: :approve_health_workers)])
    end
    it "resolves all users" do
      resolved_records = subject.new(user_with_permission, User.all).resolve

      users = PhoneNumberAuthentication.all.map(&:user)
      expect(resolved_records.to_a).to match_array(users)
    end
  end

  describe "User can manage users for an organization" do
    let(:user_with_permission) do
      create(:admin, user_permissions: [build(:user_permission, permission_slug: :approve_health_workers, resource: organization)])
    end
    it "resolves user for their organizations" do
      resolved_records = subject.new(user_with_permission, User.all).resolve
      expect(resolved_records).to match_array([user_1, user_2])
    end

    it "does not resolve users for other organizations" do
      resolved_records = subject.new(user_with_permission, User.all).resolve
      expect(resolved_records).not_to include(user_3)
    end
  end

  describe "User can manage users for a facility group" do
    let(:user_with_permission) do
      create(:admin, user_permissions: [build(:user_permission, permission_slug: :approve_health_workers, resource: facility_group_1)])
    end
    it "resolves users of their facility groups" do
      resolved_records = subject.new(user_with_permission, User.all).resolve
      expect(resolved_records).to match_array([user_1])
    end

    it "does not resolve users for other facility groups" do
      resolved_records = subject.new(user_with_permission, User.all).resolve
      expect(resolved_records).not_to include(user_2, user_3)
    end
  end

  describe "User without permissions to manage users" do
    let(:user_without_permission) { create(:admin) }

    it "does not resolve any users" do
      resolved_records = subject.new(user_without_permission, User.all).resolve
      expect(resolved_records).to be_empty
    end
  end
end
