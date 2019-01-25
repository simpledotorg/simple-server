require 'rails_helper'

RSpec.describe Admin::OverdueAppointmentsController, type: :controller do
  let(:healthcare_counsellor) { create(:admin, :healthcare_counsellor) }
  let(:facility_group) { healthcare_counsellor.facility_groups.first }
  let(:facility) { create(:facility, facility_group: facility_group) }

  let!(:patient_with_overdue_appointment) { create(:patient, registration_facility: facility) }
  let!(:patient_without_overdue_appointment) { create(:patient, registration_facility: facility) }

  let!(:overdue_appointment) { build(:overdue_appointment, patient: patient_with_overdue_appointment) }

  before do
    sign_in(healthcare_counsellor)
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index, params: {}
      expect(response).to be_success
    end
  end

  describe 'GET #edit' do
    it 'returns a success response for patient with overdue appointment' do
      get :edit, params: {id: patient_with_overdue_appointment.id}
      expect(response).to be_success
    end

    it 'returns a 404 response for patient without overdue appointment' do
      get :edit, params: {id: patient_without_overdue_appointment.id}
      expect(response.status).to eq(404)
    end
  end

  describe 'GET #cancel' do
    it 'returns a success response for patient with overdue appointment' do
      get :edit, params: {id: patient_with_overdue_appointment.id}
      expect(response).to be_success
    end

    it 'returns a 404 response for patient without overdue appointment' do
      get :edit, params: {id: patient_without_overdue_appointment.id}
      expect(response.status).to eq(404)
    end
  end

  describe 'PUT #update' do
    it 'edits the overdue appointment' do
      new_remind_date = Date.today + 1.month

      put :update, params: {
        id: patient_with_overdue_appointment.id,
        appointment: {
          remind_on: new_remind_date,
          agreed_to_visit: true
        }
      }

      overdue_appointment = OverdueAppointment.for_patient(patient_with_overdue_appointment)
      expect(overdue_appointment.appointment.remind_on).to eq(new_remind_date)
      expect(overdue_appointment.appointment.agreed_to_visit).to be(true)
      expect(response).to redirect_to(action: 'index')
    end

    it 'cancels the overdue appointment' do
      put :update, params: {
        id: patient_with_overdue_appointment.id,
        appointment: {
          status: :cancelled,
          cancel_reason: 'moved'
        }
      }

      cancelled_appointment = patient_with_overdue_appointment.appointments.first
      expect(cancelled_appointment.status).to eq('cancelled')
      expect(cancelled_appointment.cancel_reason).to eq('moved')
      expect(response).to redirect_to(action: 'index')
    end
  end
end
