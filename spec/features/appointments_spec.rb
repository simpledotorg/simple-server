require 'rails_helper'

RSpec.feature 'Overdue appointments', type: :feature do
  let!(:ihmi) { create(:organization, name: "IHMI") }
  let!(:ihmi_group) { create(:facility_group, organization: ihmi) }
  let!(:supervisor) {
    create(
      :admin,
      :supervisor,
      facility_group: ihmi_group
    )
  }

  describe 'index' do
    before { sign_in(supervisor.email_authentication) }

    it 'shows Overdue tab' do
      visit root_path

      expect(page).to have_content('Overdue patients')
    end

    describe 'Overdue patients tab' do
      let!(:authorized_facility_group) { ihmi_group }

      let!(:facility_1) { create(:facility, facility_group: authorized_facility_group) }

      let!(:overdue_patient_in_facility_1) do
        patient = create(:patient, full_name: 'patient_1', registration_facility: facility_1)
        create(:appointment, :overdue, facility: facility_1, patient: patient, scheduled_date: 10.days.ago)
        create(:blood_pressure, :critical, facility: facility_1, patient: patient)
        patient
      end

      let!(:non_overdue_patient_in_facility_1) { create(:patient, full_name: 'patient_2', registration_facility: facility_1) }

      let!(:facility_2) { create(:facility, facility_group: authorized_facility_group) }

      let!(:overdue_patient_in_facility_2) do
        patient = create(:patient, full_name: 'patient_3', registration_facility: facility_2)
        create(:appointment, :overdue, facility: facility_2, patient: patient, scheduled_date: 5.days.ago)
        create(:blood_pressure, :high, facility: facility_2, patient: patient)
        patient
      end

      let!(:unauthorized_facility_group) { create(:facility_group) }

      let!(:unauthorized_facility) { create(:facility, facility_group: unauthorized_facility_group) }

      let!(:overdue_patient_in_unauthorized_facility) do
        patient = create(:patient, full_name: 'patient_4', registration_facility: unauthorized_facility)
        create(:appointment, :overdue, facility: unauthorized_facility, patient: patient)
        patient
      end

      before do
        visit appointments_path
      end

      it 'shows all overdue patients' do
        expect(page).to have_content(overdue_patient_in_facility_1.full_name)
        expect(page).to have_content(overdue_patient_in_facility_2.full_name)
      end

      it 'shows enrollment date for overdue patients' do
        expect(page).to have_content('Enrolled on')
      end

      it 'does not show non-overdue patients' do
        expect(page).not_to have_content(non_overdue_patient_in_facility_1.full_name)
      end

      it 'does not show overdue patients in unauthorized facilities' do
        expect(page).not_to have_content(overdue_patient_in_unauthorized_facility.full_name)
      end

      it 'shows overdue patients ordered by how overdue they are' do
        first_item = find(:css, '.card:nth-of-type(1)')
        second_item = find(:css, '.card:nth-of-type(2)')

        expect(first_item).to have_content(overdue_patient_in_facility_1.full_name)
        expect(second_item).to have_content(overdue_patient_in_facility_2.full_name)
      end

      it 'sets a call_result, and removes patient from the overdue list' do
        within('.card:first-of-type') do
          find(:option, 'Dead').click
        end

        page.reset!
        visit appointments_path
        expect(page).not_to have_content(overdue_patient_in_facility_1.full_name)
      end

      it 'allows you to filter by facility' do
        select facility_1.name, from: "facility_id"
        click_button "Filter"

        expect(page).to have_content(overdue_patient_in_facility_1.full_name)
        expect(page).not_to have_content(overdue_patient_in_facility_2.full_name)
      end

      it 'allows you to download the overdue list CSV for a facility' do
        select facility_1.name, from: "facility_id"
        click_button "Filter"

        click_link "Download overdue list"

        expect(page).to have_content(Appointment.csv_headers.to_csv.strip)

        appointment = overdue_patient_in_facility_1.appointments.first
        expect(page).to have_content(appointment.csv_fields.to_csv.strip)
      end

      it 'does not allow you to download the overdue list for all facilities' do
        expect(page).to have_content("Select a facility to download Overdue Patients list")
        expect(page).not_to have_selector("a", text: "Download Overdue List")
      end
    end
  end
end
