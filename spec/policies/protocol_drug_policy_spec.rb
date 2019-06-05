require "rails_helper"

RSpec.describe ProtocolDrugPolicy do
  subject { described_class }

  let(:user_can_manage_all_protocols) do
    user = create(:master_user)
    create(:user_permission, user: user, permission_slug: :can_manage_all_protocols, resource: nil)
    user
  end

  let(:other_user) { create(:master_user) }

  permissions :index? do
    it "permits users with permission to manage all protocols" do
      expect(subject).to permit(user_can_manage_all_protocols, ProtocolDrug)
    end

    it "denies other users" do
      expect(subject).not_to permit(other_user, ProtocolDrug)
    end
  end

  permissions :index?, :show?, :new?, :create?, :update?, :edit?, :destroy? do
    it "permits users with permission to manage all protocols" do
      expect(subject).to permit(user_can_manage_all_protocols, build(:protocol_drug))
    end

    it "denies other users" do
      expect(subject).not_to permit(other_user, build(:protocol_drug))
    end
  end
end

RSpec.describe ProtocolDrugPolicy::Scope do
  let(:subject) { described_class }
  let(:organization) { create(:organization) }

  let(:user_can_manage_all_protocols) do
    user = create(:master_user)
    create(:user_permission, user: user, permission_slug: :can_manage_all_protocols, resource: nil)
    user
  end

  let(:other_user) { create(:master_user) }

  let(:protocol_1) { create(:protocol) }
  let(:protocol_2) { create(:protocol) }
  let!(:protocol_drugs_1) { create_list(:protocol_drug, 5, protocol: protocol_1) }
  let!(:protocol_drugs_2) { create_list(:protocol_drug, 5, protocol: protocol_2) }

  let!(:facility_group_1) { create(:facility_group, organization: organization, protocol: protocol_1) }
  let!(:facility_group_2) { create(:facility_group, organization: organization, protocol: protocol_2) }

  it 'resolves all protocol drugs for users with permission to manage all protocols' do
    resolved_records = subject.new(user_can_manage_all_protocols, ProtocolDrug.all).resolve
    expect(resolved_records.to_a).to match_array(ProtocolDrug.all.to_a)
  end

  it 'resolves no protocol drugs for other users' do
    resolved_records = subject.new(other_user, ProtocolDrug.all).resolve
    expect(resolved_records.to_a).to be_empty
  end
end
