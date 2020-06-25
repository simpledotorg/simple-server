require "rails_helper"

RSpec.feature "To test overdue appointment functionality", type: :feature do
  let!(:ihmi) { create(:organization, name: "IHMI") }
  let!(:ihmi_facility_group) { create(:facility_group, organization: ihmi, name: "Bathinda") }
  let!(:test_facility) { create(:facility, facility_group: ihmi_facility_group, name: "test_facility") }
  let!(:owner) { create(:admin) }
  let!(:permissions) do
    [
      create(:user_permission, user: owner, permission_slug: :view_overdue_list),
      create(:user_permission, user: owner, permission_slug: :download_overdue_list)
    ]
  end

  login = AdminPage::Sessions::New.new
  appoint_page = AppointmentsPage::Index.new
  nav_page = Navigations::DashboardPageNavigation.new

  context "Page verification" do
    before(:each) do
      visit root_path
      login.do_login(owner.email, owner.password)
    end

    it "landing page -with no overdue patient" do
      expect(page).to have_content("Overdue patients")
      nav_page.click_main_menu_tab("Overdue patients")
      appoint_page.verify_overdue_landing_page
      expect(page).to have_content("All facilities")
      expect(page).to have_content("20 per page")
      expect(page).to have_content("No overdue patients found")
    end

    it "landing page -Facility and page dropdown " do
      create_list(:facility, 5)
      nav_page.click_main_menu_tab("Overdue patients")
      appoint_page.select_facility_drop_down
      expect(appoint_page.get_all_facility_count).to eq(7)

      appoint_page.select_page_dropdown
      expect(appoint_page.get_all_page_dropdown).to eq(2)
    end

    it "landing page -patient list - with all facility category" do
      patients = create_list(:patient, 2, registration_facility: test_facility)

      appointments = patients.each do |patient|
        create(:appointment, :overdue, facility: test_facility, patient: patient, scheduled_date: 10.days.ago)
      end

      blood_pressures =
        patients.each do |patient|
          create(:blood_pressure, :critical, facility: test_facility, patient: patient)
        end

      nav_page.click_main_menu_tab("Overdue patients")
      expect(appoint_page.get_all_patient_count.size).to eq(2)
    end

    it "landing page -pagination" do
      patients = create_list(:patient, 22, registration_facility: test_facility)

      appointments = patients.each do |patient|
        create(:appointment, :overdue, facility: test_facility, patient: patient, scheduled_date: 10.days.ago)
      end

      blood_pressures =
        patients.each do |patient|
          create(:blood_pressure, :critical, facility: test_facility, patient: patient)
        end

      nav_page.click_main_menu_tab("Overdue patients")
      expect(page).to have_content("All facilities")
      expect(page).to have_content("20 per page")

      expect(appoint_page.get_all_patient_count.size).to eq(20)
      expect(appoint_page.get_page_link_count.size).to eq(4)

      expect(page).to have_content("Next")
      expect(page).to have_content("Last")
    end

    it "landing page - overdue patient card detail" do
      # creating overdue patient test data for test_facility, belongs to IHMI
      var_patients = create(:patient, registration_facility: test_facility)
      var_appointment = create(:appointment, :overdue, facility: test_facility, patient: var_patients, scheduled_date: 10.days.ago)
      var_bp = create(:blood_pressure, :critical, facility: test_facility, patient: var_patients)

      nav_page.click_main_menu_tab("Overdue patients")

      within(".card") do
        expect(page).to have_content(var_patients.full_name)
        expect(page).to have_content(var_patients.age)
        expect(page).to have_content("Registered on:")
        expect(page).to have_content(var_patients.registration_date)
        expect(page).to have_content("Last BP:")
        expect(page).to have_content(var_bp.to_s)
        expect(page).to have_content(var_bp.facility.name)
        expect(page).to have_content(var_patients.address.street_address)
        expect(page).to have_content("Call result")
        expect(find("a.btn-phone").text).to eq(var_patients.phone_numbers.first.number)
        expect(appoint_page.get_overdue_days).to eq(var_appointment.days_overdue.to_s + " days overdue")
      end
    end
  end

  skip "JS specs are currently disabled" do
    describe "Javascript based tests", js: true do
      let!(:ihmi) { create(:organization, name: "IHMI") }
      let!(:ihmi_facility_group) { create(:facility_group, organization: ihmi, name: "Bathinda") }
      let!(:test_facility) { create(:facility, facility_group: ihmi_facility_group, name: "test_facility") }

      before(:each) do
        visit root_path
        login.do_login(owner.email, owner.password)
      end

      it "should be able to download patient list" do
        # creating overdue patient test data for test_facility, belongs to IHMI
        patients = create_list(:patient, 5, registration_facility: test_facility)

        appointments =
          patients.each do |patient|
            create(:appointment, :overdue, facility: test_facility, patient: patient, scheduled_date: 10.days.ago)
          end

        blood_pressures =
          patients.each do |patient|
            create(:blood_pressure, :critical, facility: test_facility, patient: patient)
          end

        puts Capybara.default_selector

        nav_page.click_main_menu_tab("Overdue patients")
        expect(page).to have_content("Select a facility to download Overdue Patients list")

        appoint_page.select_facility("test_facility")
        expect(page).to have_content("Downloads")
        appoint_page.click_download_link
      end

      it "should display list -for different facilities" do
        # creating overdue patient test data for test_facility, belongs to IHMI
        patients = create_list(:patient, 3, registration_facility: test_facility)
        patients.each do |patient|
          create(:appointment, :overdue, facility: test_facility, patient: patient, scheduled_date: 10.days.ago)
        end
        patients.each do |patient|
          create(:blood_pressure, :critical, facility: test_facility, patient: patient)
        end

        # creating overdue patient test data for test_facility_02 and this belongs to PATH
        var_path = create(:organization, name: "Path")
        var_facility_group = create(:facility_group, organization: var_path, name: "path_facility_group")
        var_path_facility = create(:facility, facility_group: var_facility_group, name: "path_facility")

        patients = create_list(:patient, 2, registration_facility: var_path_facility)

        patients.each do |patient|
          create(:appointment, :overdue, facility: var_path_facility, patient: patient, scheduled_date: 30.days.ago)
        end

        patients.each do |patient|
          create(:blood_pressure, :critical, facility: var_path_facility, patient: patient)
        end

        nav_page.click_main_menu_tab("Overdue patients")

        # selecting first facility and asserting its result
        appoint_page.select_facility(test_facility.name)
        expect(appoint_page.get_all_patient_count.size).to eq(3)

        # selecting second facility and asserting its result
        appoint_page.select_facility(var_path_facility.name)
        expect(appoint_page.get_all_patient_count.size).to eq(2)

        # selecting All facility and asserting its result
        appoint_page.select_facility("All facilities")
        expect(appoint_page.get_all_patient_count.size).to eq(5)
      end

      it "should be able to select result of follow up" do
        # creating overdue patient test data for test_facility, belongs to IHMI
        var_patients = create(:patient, registration_facility: test_facility)
        create(:appointment, :overdue, facility: test_facility, patient: var_patients, scheduled_date: 10.days.ago)
        create(:blood_pressure, :critical, facility: test_facility, patient: var_patients)

        nav_page.click_main_menu_tab("Overdue patients")

        within(".card") do
          select "Agreed to visit", from: "appointment[call_result]"
        end

        find(:css, "button.close").click
        expect(page).not_to have_content(var_patients.full_name)
      end
    end
  end

  context "verify overdue patient list to exclude patients > 12 months overdue" do
    before(:each) do
      visit root_path
      login.do_login(owner.email, owner.password)
    end

    it "patient is exact 365 days overdue" do
      var_patients = create(:patient, registration_facility: test_facility)
      create(:blood_pressure, :critical, facility: test_facility, patient: var_patients)
      create(:appointment, :overdue, facility: test_facility, patient: var_patients, scheduled_date: 365.days.ago)

      nav_page.click_main_menu_tab("Overdue patients")
      expect(page).to have_content(var_patients.full_name)
    end

    it "366 days overdue" do
      var_patients = create(:patient, registration_facility: test_facility)
      create(:blood_pressure, :critical, facility: test_facility, patient: var_patients)
      create(:appointment, :overdue, facility: test_facility, patient: var_patients, scheduled_date: 366.days.ago)

      nav_page.click_main_menu_tab("Overdue patients")
      expect(page).not_to have_content(var_patients.full_name)
    end

    it "0 days overdue" do
      var_patients = create(:patient, registration_facility: test_facility)
      create(:blood_pressure, :critical, facility: test_facility, patient: var_patients)
      create(:appointment, :overdue, facility: test_facility, patient: var_patients, scheduled_date: 0.days.ago)

      nav_page.click_main_menu_tab("Overdue patients")
      expect(page).not_to have_content(var_patients.full_name)
    end
  end
end
