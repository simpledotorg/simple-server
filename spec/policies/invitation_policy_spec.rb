require "rails_helper"

RSpec.describe InvitationPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:supervisor) { create(:admin, :supervisor) }
  let(:analyst) { create(:admin, :analyst) }
  let(:organization_owner) { create(:admin, :organization_owner) }

  permissions :new?, :create? do
    it "permits owners" do
      expect(subject).to permit(owner)
    end

    it "permits organization owners" do
      expect(subject).to permit(owner)
    end
  end

  permissions :invite_owner? do
    it "permits owners" do
      expect(subject).to permit(owner)
    end

    it "doesn't permit any other admin" do
      expect(subject).not_to permit(organization_owner)
      expect(subject).not_to permit(supervisor)
      expect(subject).not_to permit(analyst)
    end
  end

  permissions :invite_organization_owner? do
    it "permits owners and organization owners" do
      expect(subject).to permit(owner)
      expect(subject).to permit(organization_owner)
    end

    it "doesn't permit other email_authentications" do
      expect(subject).not_to permit(supervisor)
      expect(subject).not_to permit(analyst)
    end
  end

  permissions :invite_supervisor?, :invite_analyst? do
    it "permits owners and organization owners" do
      expect(subject).to permit(owner)
      expect(subject).to permit(organization_owner)
    end

    it "doesn't permit any other admin" do
      expect(subject).not_to permit(supervisor)
      expect(subject).not_to permit(analyst)
    end
  end
end