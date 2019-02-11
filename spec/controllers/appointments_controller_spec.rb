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

  describe 'GET #edit' do
    it 'returns a success response' do
      get :edit, params: { id: overdue_appointment.id }
      expect(response).to be_success
    end
  end

  describe 'PUT #update' do
    it 'edits the overdue appointment' do
      new_remind_date = Date.today + 1.month

      put :update, params: {
        id: overdue_appointment.id,
        appointment: {
          remind_on: new_remind_date,
          agreed_to_visit: true
        }
      }

      overdue_appointment.reload

      expect(overdue_appointment.remind_on).to eq(new_remind_date)
      expect(overdue_appointment.agreed_to_visit).to be(true)
      expect(response).to redirect_to(action: 'index')
    end
  end

  describe 'GET #cancel' do
    it 'returns a success response' do
      get :cancel, params: { appointment_id: overdue_appointment.id }
      expect(response).to be_success
    end
  end

  describe 'PUT #cancel_with_reason' do
    it 'cancels the overdue appointment' do
      put :cancel_with_reason, params: {
        appointment_id: overdue_appointment.id,
        appointment: {
          cancel_reason: 'moved'
        }
      }

      overdue_appointment.reload

      expect(overdue_appointment.status).to eq('cancelled')
      expect(overdue_appointment.cancel_reason).to eq('moved')
      expect(response).to redirect_to(action: 'index')
    end
  end
end
