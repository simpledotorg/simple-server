require "rails_helper"

RSpec.describe DashboardPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:supervisor) { create(:admin, :supervisor) }

  permissions :show? do
    it "permits owners" do
      expect(subject).to permit(owner, :dashboard)
    end

    it "denies supervisors" do
      expect(subject).to permit(supervisor, :dashboard)
    end
  end
end
