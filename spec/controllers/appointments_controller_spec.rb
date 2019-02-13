require 'rails_helper'

RSpec.describe AppointmentsController, type: :controller do
  let(:counsellor) { create(:admin, :counsellor) }
  let(:facility_group) { counsellor.facility_groups.first }
  let(:facility) { create(:facility, facility_group: facility_group) }

  let!(:patient_with_overdue_appointment) do
    patient = create(:patient, registration_facility: facility)
    create(:blood_pressure, patient: patient, facility: facility)
    patient
  end

  let!(:overdue_appointment) do
    create(:appointment, :overdue,
           patient: patient_with_overdue_appointment,
           facility: facility)
  end

  let!(:patient_without_overdue_appointment) do
    patient = create(:patient, registration_facility: facility)
    create(:appointment, patient: patient, facility: facility)
  end

  before do
    sign_in(counsellor)
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index, params: {}
      expect(response).to be_success
    end
  end

  describe 'PUT #update' do
    it 'remind_in_a_week updates agreed_to_visit and remind_on' do
      new_remind_date = Date.today + 7.days

      put :update, params: {
        id: overdue_appointment.id,
        appointment: {
          call_result: 'remind_in_a_week'
        }
      }

      overdue_appointment.reload

      expect(overdue_appointment.remind_on).to eq(new_remind_date)
      expect(overdue_appointment.agreed_to_visit).to be(true)
      expect(response).to redirect_to(action: 'index')
    end
  end
end
