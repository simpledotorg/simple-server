require "rails_helper"

RSpec.describe UserPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:supervisor) { create(:admin, :supervisor) }
  let(:analyst) { create(:admin, :analyst) }

  permissions :index?, :show?, :enable_access?, :disable_access?, :reset_otp? do
    it "permits owners" do
      expect(subject).to permit(owner, User)
    end

    it "permits supervisors" do
      expect(subject).to permit(supervisor, User)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, User)
    end
  end

  permissions :new?, :create?, :update?, :edit?, :destroy? do
    it "permits owners" do
      expect(subject).to permit(owner, User)
    end

    it "denies supervisors" do
      expect(subject).not_to permit(supervisor, User)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, User)
    end
  end
end
