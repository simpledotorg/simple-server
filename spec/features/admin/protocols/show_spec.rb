require "features_helper"

RSpec.feature "test medication list detail page functionality", type: :feature do
  let(:owner) { create(:admin, :power_user) }
  let!(:medication_list_1) { create(:protocol, name: "PunjabTestProtocol", follow_up_days: "20") }
  let!(:medication_1) { create(:protocol_drug, name: "test_Drug_01", dosage: "10mg", rxnorm_code: "code", protocol: medication_list_1) }

  medication_list = AdminPage::Protocols::Index.new
  medication_list_show = AdminPage::Protocols::Show.new
  medication_list_update = AdminPage::Protocols::Edit.new
  new_medication = AdminPage::ProtocolDrugs::New.new

  before(:each) do
    visit root_path
    sign_in(owner.email_authentication)
    visit admin_protocols_path
  end

  context "medication list show page" do
    it "edit medication list" do
      medication_list.select_medication_list(medication_list_1.name)

      medication_list_show.click_edit_medication_list_button
      medication_list_update.update_medication_list_followup_days("10")

      # assertion
      medication_list_show.verify_successful_message("Medication list was successfully updated")
      medication_list_show.verify_updated_followup_days("10")
      medication_list_show.click_message_cross_button
    end

    it "should create new medication" do
      medication_list.select_medication_list(medication_list_1.name)

      medication_list_show.click_new_medication_button
      new_medication.add_new_medication("test_drug", "10mg", "AXDSC")

      # assertion
      medication_list_show.verify_successful_message("Medication was successfully created")
      expect(page).to have_content("test_drug")
    end

    it "should edit medication" do
      medication_list.select_medication_list(medication_list_1.name)
      medication_list_show.click_edit_medication_button("#{medication_1.name}-#{medication_1.dosage}")
      AdminPage::ProtocolDrugs::Edit.new.edit_medication_info("50mg", "AXDFC")
    end
  end
end
