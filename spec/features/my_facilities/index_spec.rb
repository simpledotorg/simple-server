require "features_helper"

RSpec.feature "My facilities page functionality", type: :feature do
  let(:admin) { create(:admin, :power_user) }
  my_facilities_page = MyFacilitiesPage::Index.new

  context "region search bar" do
    before(:each) do
      visit root_path
      sign_in(admin.email_authentication)
    end
    it "sanitizes the search query" do
      create(:facility)
      visit my_facilities_overview_path
      search_query = "<script>alert('hi')</script>"
      expect {
        accept_prompt do
          my_facilities_page.search_region(search_query)
        end
      }.to raise_error(Capybara::ModalNotFound, "Unable to find modal dialog")
    end
    it "sanitizes fields of search result facilities" do
      search_query = "<script>alert('hi')</script>"
      create(:facility, name: search_query)
      visit my_facilities_overview_path
      expect {
        accept_prompt do
          my_facilities_page.search_region("<script>")
        end
      }.to raise_error(Capybara::ModalNotFound, "Unable to find modal dialog")
    end
  end
end
