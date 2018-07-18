require "rails_helper"

RSpec.describe ProtocolDrugPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:supervisor) { create(:admin, :supervisor) }

  permissions :index?, :show?, :new?, :create?, :update?, :edit?, :destroy? do
    it "permits owners" do
      expect(subject).to permit(owner, ProtocolDrug)
    end

    it "denies supervisors" do
      expect(subject).not_to permit(supervisor, ProtocolDrug)
    end
  end
end
