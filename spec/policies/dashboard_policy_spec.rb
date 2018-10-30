require "rails_helper"

RSpec.describe DashboardPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:supervisor) { create(:admin, :supervisor) }
  let(:analyst) { create(:admin, :analyst) }

  permissions :show? do
    it "permits owners" do
      expect(subject).to permit(owner, :dashboard)
    end

    it "permits supervisors" do
      expect(subject).to permit(supervisor, :dashboard)
    end

    it "permits analysts" do
      expect(subject).to permit(analyst, :dashboard)
    end
  end
end
