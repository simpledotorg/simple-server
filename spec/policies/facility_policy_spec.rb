require "rails_helper"

RSpec.describe FacilityPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:supervisor) { create(:admin, :supervisor) }

  permissions :index?, :show? do
    it "permits owners" do
      expect(subject).to permit(owner, Facility)
    end

    it "permits supervisors" do
      expect(subject).to permit(supervisor, Facility)
    end
  end

  permissions :new?, :create?, :update?, :edit?, :destroy? do
    it "permits owners" do
      expect(subject).to permit(owner, Facility)
    end

    it "denies supervisors" do
      expect(subject).not_to permit(supervisor, Facility)
    end
  end
end
