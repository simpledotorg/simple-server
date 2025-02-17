require "features_helper"

RSpec.feature "New facility group page functionality", type: :feature do
  let(:admin) { create(:admin, :power_user) }
  facility_group_page = AdminPage::FacilityGroups::New.new

  context "add new block" do
    before(:each) do
      visit root_path
      sign_in(admin.email_authentication)
    end

    it "escapes html tags in the input" do
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
