require "rails_helper"

RSpec.describe FacilityPolicy do
  subject { described_class }

  let(:admin) { create(:admin) }
  let(:supervisor) { create(:admin, :supervisor) }

  permissions :index?, :show? do
    it "permits admins" do
      expect(subject).to permit(admin, Facility)
    end

    it "permits supervisors" do
      expect(subject).to permit(supervisor, Facility)
    end
  end

  permissions :new?, :create?, :update?, :edit?, :destroy? do
    it "permits admins" do
      expect(subject).to permit(admin, Facility)
    end

    it "denies supervisors" do
      expect(subject).not_to permit(supervisor, Facility)
    end
  end
end
