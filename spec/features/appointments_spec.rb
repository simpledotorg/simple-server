# frozen_string_literal: true

require "features_helper"

RSpec.feature "Overdue appointments", type: :feature do
  let!(:ihmi) { create(:organization, name: "IHMI") }
  let!(:ihmi_group) { create(:facility_group, organization: ihmi) }
  let!(:facility) { create(:facility, facility_group: ihmi_group) }
  let!(:call_center) { create(:admin, :call_center) }

  before do
    call_center.accesses.create(resource: ihmi)
    ENV["IHCI_ORGANIZATION_UUID"] = ihmi.id
  end

  describe "index" do
    before { sign_in(call_center.email_authentication) }

    it "shows Overdue tab" do
      visit root_path

      expect(page).to have_content("Overdue patients")
    end

    describe "Overdue patients tab" do
      it "shows all overdue patients" do
        authorized_facility_group = ihmi_group

        facility_1 = create(:facility, facility_group: authorized_facility_group)
        facility_2 = create(:facility, facility_group: authorized_facility_group)

        unauthorized_facility_group = create(:facility_group)
        unauthorized_facility = create(:facility, facility_group: unauthorized_facility_group)

        overdue_patient_in_facility_1 = create(:patient, full_name: "patient_1", registration_facility: facility_1)
        create(:appointment, :overdue, facility: facility_1, patient: overdue_patient_in_facility_1, scheduled_date: 10.days.ago)
        create(:blood_pressure, :critical, facility: facility_1, patient: overdue_patient_in_facility_1)

        non_overdue_patient_in_facility_1 = create(:patient, full_name: "patient_2", registration_facility: facility_1)

        dead_overdue_patient_in_facility_1 = create(:patient, full_name: "patient_3", registration_facility: facility_1, status: :dead)
        create(:appointment, :overdue, facility: facility_1, patient: dead_overdue_patient_in_facility_1, scheduled_date: 10.days.ago)
        create(:blood_pressure, :critical, facility: facility_1, patient: dead_overdue_patient_in_facility_1)

        overdue_patient_in_facility_2 = create(:patient, full_name: "patient_4", registration_facility: facility_2)
        create(:appointment, :overdue, facility: facility_2, patient: overdue_patient_in_facility_2, scheduled_date: 5.days.ago)
        create(:blood_pressure, :hypertensive, facility: facility_2, patient: overdue_patient_in_facility_2)

        overdue_patient_in_unauthorized_facility = create(:patient, full_name: "patient_5", registration_facility: unauthorized_facility)
        create(:appointment, :overdue, facility: unauthorized_facility, patient: overdue_patient_in_unauthorized_facility)

        visit appointments_path

        expect(page).to have_content(overdue_patient_in_facility_1.full_name)
        expect(page).to have_content(overdue_patient_in_facility_2.full_name)
        expect(page).to have_content("Registered on")
        expect(page).not_to have_content(non_overdue_patient_in_facility_1.full_name)
        expect(page).not_to have_content(dead_overdue_patient_in_facility_1.full_name)
        expect(page).not_to have_content(overdue_patient_in_unauthorized_facility.full_name)
        expect(page).to have_content(/select a facility/i)
        expect(page).not_to have_selector("a", text: "Download Overdue List")
      end
    end
  end
end
