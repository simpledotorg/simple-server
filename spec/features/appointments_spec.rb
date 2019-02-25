require 'rails_helper'

RSpec.feature 'Overdue Appointments', type: :feature do
  let!(:counsellor) { create(:admin, :counsellor) }
  let!(:facility_1) { create(:facility, facility_group: counsellor.facility_groups.first) }
  let!(:facility_2) { create(:facility, facility_group: counsellor.facility_groups.first) }

  let!(:unauthorized_facility_group) { create(:facility_group) }
  let!(:unauthorized_facility) { create(:facility, facility_group: unauthorized_facility_group) }

  describe 'index' do
    before { sign_in(counsellor) }

    it 'shows Overdue tab' do
      visit root_path

      expect(page).to have_content('Overdue Appointments')
    end

    describe 'Overdue Patients tab' do
      before do
        sign_in(counsellor)
        visit appointment_path
      end
    end
  end
end
