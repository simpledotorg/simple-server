require "rails_helper"

RSpec.describe ProtocolDrugPolicy do
  subject { described_class }

  let(:protocol_drug) { build(:protocol_drug) }
  context 'user can manage all protocols' do
    let(:user_with_permission) do
      create(:admin, user_permissions: [build(:user_permission, permission_slug: :can_manage_all_protocols)])
    end

    permissions :index? do
      it 'permits the user' do
        expect(subject).to permit(user_with_permission, ProtocolDrug)
      end
    end

    permissions :show?, :new?, :create?, :update?, :edit?, :destroy? do
      it 'permits the user' do
        expect(subject).to permit(user_with_permission, protocol_drug)
      end
    end
  end

  context 'other users' do
    let(:other_user) do
      create(:admin, user_permissions: [])
    end

    permissions :index? do
      it 'denies the user' do
        expect(subject).not_to permit(other_user, ProtocolDrug)
      end
    end

    permissions :show?, :new?, :create?, :update?, :edit?, :destroy? do
      it 'denies the user' do
        expect(subject).not_to permit(other_user, ProtocolDrug)
      end
    end
  end
end

RSpec.describe ProtocolDrugPolicy::Scope do
  let(:subject) { described_class }
  let(:organization) { create(:organization) }

  let(:protocol_1) { create(:protocol) }
  let(:protocol_2) { create(:protocol) }
  let!(:protocol_drugs_1) { create_list(:protocol_drug, 5, protocol: protocol_1) }
  let!(:protocol_drugs_2) { create_list(:protocol_drug, 5, protocol: protocol_2) }


  context 'user can manage all protocols' do
    let(:user_with_permission) do
      create(:admin, user_permissions: [build(:user_permission, permission_slug: :can_manage_all_protocols)])
    end

    it 'resolves all the protocol durgs' do
      resolved_records = subject.new(user_with_permission, ProtocolDrug.all).resolve
      expect(resolved_records).to match_array(ProtocolDrug.all)
    end
  end

  context 'other users' do
    let(:other_user) do
      create(:admin, user_permissions: [])
    end

    it 'resolves no protocol drugs' do
      resolved_records = subject.new(other_user, ProtocolDrug.all).resolve
      expect(resolved_records).to be_empty
    end
  end
end
