require "rails_helper"

RSpec.describe ProtocolPolicy do
  subject { described_class }

  let(:user_can_manage_all_protocols) do
    user = create(:master_user)
    create(:user_permission, user: user, permission_slug: :can_manage_all_protocols, resource: nil)
    user
  end

  let(:other_user) { create(:master_user) }

  permissions :index? do
    it "permits users with permission to manage all protocols" do
      expect(subject).to permit(user_can_manage_all_protocols, Protocol)
    end

    it "denies other users" do
      expect(subject).not_to permit(other_user, Protocol)
    end
  end


  permissions :show?, :new?, :create?, :update?, :edit?, :destroy? do
    it "permits users with permission to manage all protocols" do
      expect(subject).to permit(user_can_manage_all_protocols, build(:protocol))
    end

    it "denies other users" do
      expect(subject).not_to permit(other_user, build(:protocol))
    end
  end
end

RSpec.describe ProtocolPolicy::Scope do
  let(:subject) { described_class }
  let(:organization) { create(:organization) }

  let(:protocol_1) { create(:protocol) }
  let(:protocol_2) { create(:protocol) }

  let!(:facility_group_1) { create(:facility_group, organization: organization, protocol: protocol_1) }
  let!(:facility_group_2) { create(:facility_group, organization: organization, protocol: protocol_2) }

  let(:user_can_manage_all_protocols) do
    user = create(:master_user)
    create(:user_permission, user: user, permission_slug: :can_manage_all_protocols, resource: nil)
    user
  end

  let(:other_user) { create(:master_user) }

  it 'resolves all protocol drugs for users with permission to manage all protocols' do
    resolved_records = subject.new(user_can_manage_all_protocols, Protocol.all).resolve
    expect(resolved_records.to_a).to match_array(Protocol.all.to_a)
  end

  it 'resolves no protocol drugs for other users' do
    resolved_records = subject.new(other_user, Protocol.all).resolve
    expect(resolved_records.to_a).to be_empty
  end
end