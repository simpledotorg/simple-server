require 'rails_helper'

RSpec.feature 'To test adherence followup patient functionality', type: :feature do
  let!(:ihmi) {create(:organization, name: "IHMI")}
  let!(:ihmi_facility_group) {create(:facility_group, organization: ihmi, name: "Bathinda")}
  let!(:owner) { create(:admin) }
  let!(:permissions) { create(:user_permission, user: owner, permission_slug: :view_adherence_follow_up_list) }

  login = AdminPage::Sessions::New.new
  adherence_page = PatientPage::Index.new
  nav_page = Navigations::DashboardPageNavigation.new

  context "Page verification" do
    before(:each) do
      visit root_path
      login.do_login(owner.email, owner.password)
    end

    it "landing page -with no follow-up patient" do
      expect(page).to have_content("Adherence follow-ups")
      nav_page.select_main_menu_tab("Adherence follow-ups")
      adherence_page.verify_adherence_follow_up_landing_page
      expect(page).to have_content("All facilities")
      expect(page).to have_content("20 per page")
      expect(page).to have_content("No patients found for follow up")
    end

    it "landing page -Facility and page dropdown " do
      create_list(:facility, 5)
      nav_page.select_main_menu_tab("Adherence follow-ups")
      adherence_page.click_facility_drop_down
      expect(adherence_page.get_all_facility_count).to eq(6)

      adherence_page.click_page_dropdown
      expect(adherence_page.get_all_page_dropdown).to eq(2)
    end

    it "landing page - adherence follow up patient card detail -without bp" do
      chc_bagta_facility = create(:facility, facility_group: ihmi_facility_group, name: "bagta")
      var_patient=create(:patient ,registration_facility: chc_bagta_facility, device_created_at: 2.day.ago)
      nav_page.select_main_menu_tab("Adherence follow-ups")

      within(".card") do
        expect(page).to have_content(var_patient.full_name)
        expect(page).to have_content("Registered on:")
        expect(page).to have_content(var_patient.registration_date)
        expect(page).to have_content(var_patient.address.street_address)
        expect(page).to have_content("Call result")
        expect(find("a.btn-phone").text).to eq(var_patient.phone_numbers.first.number)
      end
    end

    it "landing page - adherence follow up patient card detail- with bp" do
      chc_bagta_facility = create(:facility, facility_group: ihmi_facility_group, name: "bagta")
      var_patient=create(:patient ,registration_facility: chc_bagta_facility, device_created_at: 2.day.ago)
      var_bp=create(:blood_pressure, :critical, facility: chc_bagta_facility, patient: var_patient)
      nav_page.select_main_menu_tab("Adherence follow-ups")

      within(".card") do
        expect(page).to have_content(var_patient.full_name)
        expect(page).to have_content(var_patient.age)
        expect(page).to have_content("Registered on:")
        expect(page).to have_content(var_patient.registration_date)
        expect(page).to have_content("Last BP:")
        expect(page).to have_content(var_bp.to_s)
        expect(page).to have_content(var_bp.facility.name)
        expect(page).to have_content(var_patient.address.street_address)
        expect(page).to have_content("Call result")
        expect(find("a.btn-phone").text).to eq(var_patient.phone_numbers.first.number)
      end
    end
  end


  skip 'JS specs are currently disabled' do
    describe "Javascript based tests", :js => true do
      let!(:chc_bagta_facility) {create(:facility, facility_group: ihmi_facility_group, name: "bagta")}
      let!(:path) {create(:facility, facility_group: ihmi_facility_group, name: "test_facility")}
      let!(:chc_buccho_facility) {create(:facility, facility_group: ihmi_facility_group, name: "buccho")}

      before(:each) do
        visit root_path
        login.do_login(owner.email, owner.password)
      end

      it "should display list -for different facilities" do
        create_list(:patient, 2, registration_facility: chc_bagta_facility, device_created_at: 2.day.ago)
        create_list(:patient, 4, registration_facility: path, device_created_at: 2.day.ago)
        create_list(:patient, 9, registration_facility: chc_buccho_facility, device_created_at: 2.day.ago)


        nav_page.select_main_menu_tab("Adherence follow-ups")

        adherence_page.select_facility(chc_buccho_facility.name)
        expect(adherence_page.get_all_patient_count.size).to eq(9)

        adherence_page.select_facility(path.name)
        expect(adherence_page.get_all_patient_count.size).to eq(4)

        adherence_page.select_facility(chc_bagta_facility.name)
        expect(adherence_page.get_all_patient_count.size).to eq(2)

        adherence_page.select_facility("All facilities")
        expect(adherence_page.get_all_patient_count.size).to eq(15)
      end

      it "should be able to select result of follow up" do
        var_patients=create(:patient ,registration_facility: chc_bagta_facility, device_created_at: 2.day.ago)
        nav_page.select_main_menu_tab("Adherence follow-ups")
        within(".card") do
          select "Contacted", from: "patient[call_result]"
        end
        find(:css, 'button.close').click
        expect(page).not_to have_content(var_patients.full_name)
      end

      it "should display list - for different page selection" do
        create_list(:patient, 25, registration_facility: chc_bagta_facility, device_created_at: 2.day.ago)

        nav_page.select_main_menu_tab("Adherence follow-ups")
        expect(adherence_page.get_all_patient_count.size).to eq(20)
        expect(adherence_page.get_page_link.size).to eq(4)
        expect(page).to have_content("Next")
        expect(page).to have_content("Last")

        adherence_page.select_page_dropdown(50)
        expect(adherence_page.get_all_patient_count.size).to eq(25)
      end
    end
  end
end
