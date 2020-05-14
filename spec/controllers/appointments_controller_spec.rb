require 'rails_helper'

RSpec.describe AppointmentsController, type: :controller do
  let(:facility_group) { create(:facility_group) }
  let(:counsellor) { create(:admin, :counsellor, facility_group: facility_group) }

  before do
    sign_in(counsellor.email_authentication)
  end

  describe 'GET #index' do
    render_views

    let!(:facility_1) { create(:facility, facility_group: facility_group) }
    let!(:overdue_appointments_in_facility_1) do
      appointments = create_list(:appointment, 3, :overdue, facility: facility_1)
      appointments.each do |appointment|
        create(:blood_pressure, patient: appointment.patient, facility: facility_1)
        create(:blood_pressure, patient: appointment.patient, facility: facility_1)
      end
      appointments
    end

    let!(:facility_2) { create(:facility, facility_group: facility_group) }
    let!(:overdue_appointments_in_facility_2) do
      appointments = create_list(:appointment, 3, :overdue, facility: facility_2)
      appointments.each do |appointment|
        create(:blood_pressure, patient: appointment.patient, facility: facility_2)
        create(:blood_pressure, patient: appointment.patient, facility: facility_2)
      end
      appointments
    end

    it 'returns a success response' do
      get :index, params: {}
      expect(response).to be_success
    end

    it 'populates a list of overdue appointments' do
      get :index, params: {}
      expected_ids = (overdue_appointments_in_facility_1 + overdue_appointments_in_facility_2).map(&:id)
      patient_ids = (overdue_appointments_in_facility_1 + overdue_appointments_in_facility_2).map(&:patient_id)

      expect(assigns(:patient_summaries).map(&:id)).to match_array(patient_ids)
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

    describe "filtering by days overdue" do
      it "displays patients only less than one year overdue when checked" do
        really_overdue_appointment = create(:appointment,
          facility: facility_2,
          scheduled_date: 380.days.ago,
          status: 'scheduled'
        )
        create(:blood_pressure, patient: really_overdue_appointment.patient, facility: facility_2)
        really_overdue_patient_id = really_overdue_appointment.patient_id

        get :index, params: {
          search_filters: ["only_less_than_year_overdue"],
          per_page: 'All'
        }

        patient_ids = (overdue_appointments_in_facility_1 + overdue_appointments_in_facility_2).map(&:patient_id)
        expect(assigns(:patient_summaries).map(&:id)).to match_array(patient_ids)
        expect(assigns(:patient_summaries).map(&:id)).to_not include(really_overdue_patient_id)
      end

      it "displays patients with all overdue date when unchecked and form is submitted" do
        really_overdue_appointment = create(:appointment,
          facility: facility_2,
          scheduled_date: 380.days.ago,
          status: 'scheduled'
        )
        create(:blood_pressure, patient: really_overdue_appointment.patient, facility: facility_2)
        really_overdue_patient_id = really_overdue_appointment.patient_id

        get :index, params: {
          per_page: 'All',
          submitted: 'true'
        }

        patient_ids = (overdue_appointments_in_facility_1 + overdue_appointments_in_facility_2).map(&:patient_id)
        expected_patient_ids = patient_ids.push(really_overdue_patient_id)
        expect(assigns(:patient_summaries).map(&:id)).to match_array(expected_patient_ids)
      end
    end

    describe 'pagination' do
      it 'shows "Pagination::DEFAULT_PAGE_SIZE" records per page' do
        stub_const('Pagination::DEFAULT_PAGE_SIZE', 5)
        get :index, params: {}

        expect(response.body.scan(/recorded at/).length).to be(5)
      end

      it 'shows the selected number of records per page' do
        stub_const('Pagination::DEFAULT_PAGE_SIZE', 5)
        get :index, params: { per_page: 50 }

        expect(response.body.scan(/recorded at/).length).to be(6)
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
      new_remind_date = Date.current + 7.days

      put :update, params: {
        id: overdue_appointment.id,
        appointment: {
          call_result: 'remind_to_call_later'
        }
      }

      overdue_appointment.reload

      expect(overdue_appointment.remind_on).to eq(new_remind_date)
      expect(response).to redirect_to(appointments_path)
    end

    it 'agreed_to_visit updates agreed_to_visit and remind_on' do
      new_remind_date = Date.current + 30.days

      put :update, params: {
        id: overdue_appointment.id,
        appointment: {
          call_result: 'agreed_to_visit'
        }
      }

      overdue_appointment.reload

      expect(overdue_appointment.agreed_to_visit).to eq(true)
      expect(overdue_appointment.remind_on).to eq(new_remind_date)
      expect(response).to redirect_to(appointments_path)
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
      expect(response).to redirect_to(appointments_path)
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
      expect(response).to redirect_to(appointments_path)
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
        expect(response).to redirect_to(appointments_path)
      end
    end
  end
end
