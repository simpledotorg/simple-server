require "rails_helper"

RSpec.describe CohortReport::OrganizationPolicy::Scope do
  let!(:organization1) { create(:organization) }
  let!(:organization2) { create(:organization) }
  let!(:organization3) { create(:organization) }
  let!(:facility_group) { create(:facility_group, organization: organization1) }

  describe "#resolve" do
    context "user has permission to view cohort reports" do
      context "for all organizations" do
        let(:user) do
          create(:admin, user_permissions: [
            build(:user_permission, permission_slug: :view_cohort_reports, resource: nil)
          ])
        end

        it "resolves all facility groups" do
          result = described_class.new(user, Organization).resolve
          expect(result).to eq(Organization.all)
        end
      end

      context "for a specfic organization" do
        let(:user) do
          create(:admin, user_permissions: [
            build(:user_permission, permission_slug: :view_cohort_reports, resource: organization1)
          ])
        end

        it "resolves just that organization" do
          result = described_class.new(user, Organization).resolve
          expect(result).to eq([organization1])
        end
      end

      context "for a specfic facility group" do
        let(:user) do
          create(:admin, user_permissions: [
            build(:user_permission, permission_slug: :view_cohort_reports, resource: facility_group)
          ])
        end

        it "resolves the organization of that facility group" do
          result = described_class.new(user, Organization).resolve
          expect(result).to eq([facility_group.organization])
        end
      end
    end

    context "other users" do
      let(:user) { create(:admin, :owner) }
      before do
        user.user_permissions.where(permission_slug: :view_cohort_reports).delete_all
      end

      it "resolves nothing" do
        result = described_class.new(user, Organization).resolve

        expect(result).to be_empty
      end
    end
  end
end
