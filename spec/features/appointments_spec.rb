require 'rails_helper'

RSpec.feature 'Overdue Appointments', type: :feature do
  let!(:counsellor) { create(:admin, :counsellor) }

  describe 'index' do
    before { sign_in(counsellor) }

    it 'shows Overdue tab' do
      visit root_path

      expect(page).to have_content('Overdue Appointments')
    end

    describe 'Overdue Appointments tab' do
      let!(:facility_1) { create(:facility, facility_group: counsellor.facility_groups.first) }

      let!(:overdue_patient_in_facility_1) do
        patient = create(:patient, registration_facility: facility_1)
        create(:appointment, :overdue, facility: facility_1, patient: patient)
        patient
      end

      let!(:non_overdue_patient_in_facility_1) do
        create(:patient, registration_facility: facility_1)
      end

      let!(:facility_2) { create(:facility, facility_group: counsellor.facility_groups.first) }

      let!(:overdue_patient_in_facility_2) do
        patient = create(:patient, registration_facility: facility_2)
        create(:appointment, :overdue, facility: facility_2, patient: patient)
        patient
      end

      let!(:unauthorized_facility_group) { create(:facility_group) }

      let!(:unauthorized_facility) { create(:facility, facility_group: unauthorized_facility_group) }

      let!(:overdue_patient_in_unauthorized_facility) do
        patient = create(:patient, registration_facility: unauthorized_facility)
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

      it 'does not show non-overdue patients' do
        expect(page).not_to have_content(non_overdue_patient_in_facility_1.full_name)
      end

      it 'does not show overdue patients in unauthorized facilities' do
        expect(page).not_to have_content(overdue_patient_in_unauthorized_facility.full_name)
      end
    end
  end
end
