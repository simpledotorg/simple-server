# frozen_string_literal: true

require "features_helper"

RSpec.feature "test protocol screen functionality", type: :feature do
  let(:owner) { create(:admin, :power_user) }
  let!(:medication_list) { create(:protocol, name: "PunjabTestProtocol", follow_up_days: "20") }

  medication_list_new = AdminPage::Protocols::New.new
  medication_list_page = AdminPage::Protocols::Index.new
  medication_list_show = AdminPage::Protocols::Show.new

  before(:each) do
    visit root_path
    sign_in(owner.email_authentication)
    visit admin_protocols_path
  end

  context "medication list landing page" do
    it "add new medication list" do
      medication_list_page.click_add_new_medication_list
      medication_list_new.create_new_medication_list("testProtocol", "40")

      medication_list_show.verify_successful_message("Medication list was successfully created")
      medication_list_show.click_message_cross_button

      expect(page).to have_content("TestProtocol")
    end

    it "edit medication list" do
      medication_list_page.click_edit_medication_list_link(medication_list.name)
      AdminPage::Protocols::Edit.new.update_medication_list_followup_days(40)
      medication_list_show.verify_updated_followup_days("40")

      visit admin_protocols_path

      # assertion at landing page
      within(:xpath, "//div[@id='" + medication_list.name + "']") do
        expect(page).to have_content("Edit")
        expect(page).to have_selector("a.btn-outline-danger")
        expect(page).to have_content("40")
      end
    end
  end
end
