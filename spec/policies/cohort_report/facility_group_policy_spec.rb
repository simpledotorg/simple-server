require "rails_helper"

RSpec.describe CohortReport::FacilityGroupPolicy::Scope do
  let(:organization) { create(:organization) }
  let!(:facility_group1) { create(:facility_group, organization: organization) }
  let!(:facility_group2) { create(:facility_group, organization: organization) }
  let!(:facility_group3) { create(:facility_group) }

  describe "#resolve" do
    context "user has permission to view cohort reports" do
      context "for all organizations" do
        let(:user) do
          create(:admin, user_permissions: [
            build(:user_permission, permission_slug: :view_cohort_reports, resource: nil)
          ])
        end

        it "resolves all facility groups" do
          result = described_class.new(user, FacilityGroup).resolve
          expect(result).to eq(FacilityGroup.all)
        end
      end

      context "for a specfic organization" do
        let(:user) do
          create(:admin, user_permissions: [
            build(:user_permission, permission_slug: :view_cohort_reports, resource: organization)
          ])
        end

        it "resolves all facility groups in that organization" do
          result = described_class.new(user, FacilityGroup).resolve
          expect(result).to eq(organization.facility_groups)
        end
      end

      context "for a specfic facility group" do
        let(:user) do
          create(:admin, user_permissions: [
            build(:user_permission, permission_slug: :view_cohort_reports, resource: facility_group3)
          ])
        end

        it "resolves that facility group" do
          result = described_class.new(user, FacilityGroup).resolve
          expect(result).to eq([facility_group3])
        end
      end
    end

    context "other users" do
      let(:user) { create(:admin, :owner) }
      before do
        user.user_permissions.where(permission_slug: :view_cohort_reports).delete_all
      end

      it "resolves nothing" do
        result = described_class.new(user, FacilityGroup).resolve
        expect(result).to be_empty
      end
    end
  end
end
