require "rails_helper"

RSpec.describe FacilityPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:supervisor) { create(:admin, :supervisor) }
  let(:analyst) { create(:admin, :analyst) }

  permissions :index?, :show? do
    it "permits owners" do
      expect(subject).to permit(owner, Facility)
    end

    it "permits supervisors" do
      expect(subject).to permit(supervisor, Facility)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, Facility)
    end
  end

  permissions :new?, :create?, :update?, :edit?, :destroy? do
    it "permits owners" do
      expect(subject).to permit(owner, Facility)
    end

    it "denies supervisors" do
      expect(subject).not_to permit(supervisor, Facility)
    end

    it "denies analysts" do
      expect(subject).not_to permit(analyst, Facility)
    end
  end
end
