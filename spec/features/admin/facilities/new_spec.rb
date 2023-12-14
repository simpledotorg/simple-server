require "features_helper"

RSpec.feature "New facility page functionality", type: :feature do
  let(:admin) { create(:admin, :power_user) }
  new_facility_page = AdminPage::Facilities::New.new

  context "teleconsultation enabled" do
    before(:each) do
      facility_group = create(:facility_group, organization: create(:organization))
      visit root_path
      sign_in(admin.email_authentication)
      visit new_admin_facility_group_facility_path(facility_group.id)
      new_facility_page.enable_teleconsultation
    end
    it "escapes html tags in the user teleconsulation search" do
      search_query = "<script>alert('hi')</script>"
      expect {
        accept_prompt do
          new_facility_page.search_user(search_query)
        end
      }.to raise_error(Capybara::ModalNotFound, "Unable to find modal dialog")
    end
  end
end
