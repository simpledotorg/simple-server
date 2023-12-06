require "features_helper"

RSpec.feature "region search functionality", type: :feature do
  let(:admin) { create(:admin, :power_user) }
  facility_group_page = AdminPage::FacilityGroups::New.new

  context "within the new facility group page" do
    before(:each) do
      visit root_path
      sign_in(admin.email_authentication)
    end

    it "does not execute malicious input when adding a block" do
      organization = create(:organization)
      create(:facility_group, organization: organization)
      visit new_admin_facility_group_path

      block_name = "<script>alert('hi')</script>"

      expect {
        accept_prompt do
          facility_group_page.add_new_block(block_name)
        end
      }.to raise_error(Capybara::ModalNotFound, "Unable to find modal dialog")
    end
  end
end
