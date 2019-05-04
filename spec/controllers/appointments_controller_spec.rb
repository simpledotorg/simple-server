require 'rails_helper'

RSpec.describe AppointmentsController, type: :controller do
  let(:counsellor) { create(:admin, :counsellor) }
  let(:facility_group) { counsellor.facility_groups.first }

  before do
    sign_in(counsellor)
  end

  describe 'GET #index' do
    render_views

    let!(:facility_1) { create(:facility, facility_group: facility_group) }
    let!(:overdue_appointments_in_facility_1) do
      appointments = create_list(:appointment, 50, :overdue, facility: facility_1)
      appointments.each do |appointment|
        create(:blood_pressure, patient: appointment.patient, facility: facility_1)
      end
      appointments
    end

    let!(:facility_2) { create(:facility, facility_group: facility_group) }
    let!(:overdue_appointments_in_facility_2) do
      appointments = create_list(:appointment, 50, :overdue, facility: facility_2)
      appointments.each do |appointment|
        create(:blood_pressure, patient: appointment.patient, facility: facility_2)
      end
      appointments
    end

    it 'returns a success response' do
      get :index, params: {}

      expect(response).to be_success
    end

    describe 'filtering by facility' do
      it 'displays appointments for all facilities if none is selected' do
        get :index, params: { per_page: 'All' }

        expect(response.body).to include("recorded at #{facility_1.name}")
        expect(response.body).to include("recorded at #{facility_2.name}")
      end

      it 'displays appointments for only the selected facility' do
        get :index, params: {
          facility_id: facility_1.id,
          per_page: 'All'
        }

        expect(response.body).to include("recorded at #{facility_1.name}")
        expect(response.body).not_to include("recorded at #{facility_2.name}")
      end
    end

    describe 'pagination' do
      it 'shows 20 records per page by default' do
        get :index, params: {}

        expect(response.body.scan(/recorded at/).length).to be(20)
      end

      it 'shows the selected number of records per page' do
        get :index, params: { per_page: 50 }

        expect(response.body.scan(/recorded at/).length).to be(50)
      end

      it 'shows all records if All is selected' do
        get :index, params: { per_page: 'All' }

        total_records = overdue_appointments_in_facility_1.size + overdue_appointments_in_facility_2.size

        expect(response.body.scan(/recorded at/).length).to be(total_records)
      end
    end
  end

  describe 'PUT #update' do
    let!(:facility) { create(:facility, facility_group: facility_group) }

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

    it 'remind_to_call_later updates remind_on' do
      new_remind_date = Date.today + 7.days

      put :update, params: {
        id: overdue_appointment.id,
        appointment: {
          call_result: 'remind_to_call_later'
        }
      }

      overdue_appointment.reload

      expect(overdue_appointment.remind_on).to eq(new_remind_date)
      expect(response).to redirect_to(action: 'index')
    end

    it 'agreed_to_visit updates agreed_to_visit and remind_on' do
      new_remind_date = Date.today + 30.days

      put :update, params: {
        id: overdue_appointment.id,
        appointment: {
          call_result: 'agreed_to_visit'
        }
      }

      overdue_appointment.reload

      expect(overdue_appointment.agreed_to_visit).to eq(true)
      expect(overdue_appointment.remind_on).to eq(new_remind_date)
      expect(response).to redirect_to(action: 'index')
    end

    it 'patient_has_already_visited updates appointment status to visited' do
      put :update, params: {
        id: overdue_appointment.id,
        appointment: {
          call_result: 'patient_has_already_visited'
        }
      }

      overdue_appointment.reload

      expect(overdue_appointment.status).to eq 'visited'
      expect(response).to redirect_to(action: 'index')
    end

    it 'patient_has_already_visited updates agreed_to_visit and remind_on to nil' do
      put :update, params: {
        id: overdue_appointment.id,
        appointment: {
          call_result: 'patient_has_already_visited'
        }
      }

      overdue_appointment.reload

      expect(overdue_appointment.agreed_to_visit).to be nil
      expect(overdue_appointment.remind_on).to be nil
      expect(response).to redirect_to(action: 'index')
    end

    it 'marking the appointment as cancelled updates the relevant fields' do
      Appointment.cancel_reasons.values.each do |cancel_reason|
        put :update, params: {
          id: overdue_appointment.id,
          appointment: {
            call_result: cancel_reason
          }
        }

        overdue_appointment.reload

        expect(overdue_appointment.agreed_to_visit).to be false
        expect(overdue_appointment.remind_on).to be nil
        expect(overdue_appointment.cancel_reason).to eq cancel_reason
        expect(overdue_appointment.status).to eq 'cancelled'
        expect(response).to redirect_to(action: 'index')
      end
    end
  end
end
