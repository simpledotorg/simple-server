require "rails_helper"

RSpec.describe AppointmentsController, type: :controller do
  let(:organization) { create(:organization, name: "org-1") }
  let(:facility_group) { create(:facility_group, organization: organization) }
  let(:counsellor) { create(:admin, :call_center, :with_access, resource: facility_group) }
  let(:manager) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }

  before do
    sign_in(counsellor.email_authentication)
  end

  describe "GET #index" do
    render_views

    let(:appointment_facility) { create(:facility, facility_group: facility_group) }
    let(:facility_1) { create(:facility, facility_group: facility_group) }
    let(:facility_1_patients) { create_list(:patient, 3, assigned_facility: facility_1, registration_user: manager) }
    let(:overdue_appointments_in_facility_1) do
      appointments = facility_1_patients.map { |patient| create(:appointment, :overdue, patient: patient, facility: appointment_facility) }
      appointments.each do |appointment|
        create(:blood_pressure, patient: appointment.patient, facility: facility_1, user: manager)
        create(:blood_pressure, patient: appointment.patient, facility: facility_1, user: manager)
      end
      appointments
    end

    let(:facility_2) { create(:facility, facility_group: facility_group) }
    let(:facility_2_patients) { create_list(:patient, 3, assigned_facility: facility_2, registration_user: manager) }
    let(:overdue_appointments_in_facility_2) do
      appointments = facility_2_patients.map { |patient| create(:appointment, :overdue, patient: patient, facility: appointment_facility) }
      appointments.each do |appointment|
        create(:blood_pressure, patient: appointment.patient, facility: facility_2, user: manager)
        create(:blood_pressure, patient: appointment.patient, facility: facility_2, user: manager)
      end
      appointments
    end

    it "returns a success response" do
      facility_1 # authorization requires at least one accessible facility
      get :index, params: {}
      expect(response).to be_successful
    end

    it "populates a list of overdue appointments" do
      patient_ids = (overdue_appointments_in_facility_1 + overdue_appointments_in_facility_2).map(&:patient_id)
      get :index, params: {}

      expect(assigns(:patient_summaries).map(&:id)).to match_array(patient_ids)
    end

    it "populates a list of unvisited appointments for CSV download" do
      unvisited_patient = create(:patient, registration_facility: facility_1)
      create(:appointment, patient: unvisited_patient, status: :cancelled, scheduled_date: 1.month.ago, facility: facility_1)
      patient_ids = (overdue_appointments_in_facility_1 + overdue_appointments_in_facility_2).map(&:patient_id) << unvisited_patient.id
      get :index, params: {format: :csv}

      expect(assigns(:patient_summaries).map(&:id)).to match_array(patient_ids)
    end

    describe "filtering by district" do
      it "displays appointments in the selected district for patients in the selected district" do
        overdue_appointments_in_facility_1
        overdue_appointments_in_facility_2

        other_district_facility = create(:facility)
        create(:patient, registration_facility: other_district_facility)
        create(:appointment, facility: other_district_facility)
        get :index, params: {district_slug: facility_group.region.slug}

        expect(response.body).to include("recorded at #{facility_1.name}")
        expect(response.body).to include("recorded at #{facility_2.name}")
        expect(response.body).not_to include("recorded at #{other_district_facility.name}")
      end

      it "displays appointments for alphabetically first district if none is selected" do
        sign_in(manager.email_authentication)
        overdue_appointments_in_facility_1
        overdue_appointments_in_facility_2

        other_fg = create(:facility_group, name: "aaaaaaa-alphabetically-first", organization: organization)
        other_district_facility = create(:facility, facility_group: other_fg)
        patient = create(:patient, registration_facility: other_district_facility)
        create(:appointment, :overdue, facility: other_district_facility, patient: patient)
        get :index

        expect(response.body).to include(patient.full_name)
        expect(response.body).not_to include("recorded at #{facility_1.name}")
      end
    end

    describe "filtering by facility" do
      before :each do
        overdue_appointments_in_facility_1
        overdue_appointments_in_facility_2
      end

      it "displays appointments for all facilities if none is selected" do
        get :index, params: {per_page: "All"}

        expect(response.body).to include("recorded at #{facility_1.name}")
        expect(response.body).to include("recorded at #{facility_2.name}")
      end

      it "displays appointments for only the selected assigned facility" do
        get :index, params: {
          facility_id: facility_1.id,
          per_page: "All"
        }

        expect(response.body).to include("recorded at #{facility_1.name}")
        expect(response.body).not_to include("recorded at #{facility_2.name}")
      end
    end

    describe "filtering by days overdue" do
      before :each do
        overdue_appointments_in_facility_1
        overdue_appointments_in_facility_2
      end

      it "displays patients only less than one year overdue when checked" do
        really_overdue_appointment = create(:appointment,
          facility: facility_2,
          scheduled_date: 380.days.ago,
          status: "scheduled")
        create(:blood_pressure, patient: really_overdue_appointment.patient, facility: facility_2)
        really_overdue_patient_id = really_overdue_appointment.patient_id

        get :index, params: {
          search_filters: ["only_less_than_year_overdue"],
          per_page: "All"
        }

        patient_ids = (overdue_appointments_in_facility_1 + overdue_appointments_in_facility_2).map(&:patient_id)
        expect(assigns(:patient_summaries).map(&:id)).to match_array(patient_ids)
        expect(assigns(:patient_summaries).map(&:id)).to_not include(really_overdue_patient_id)
      end

      it "displays patients with all overdue date when less than one year overdue is unchecked" do
        really_overdue_appointment = create(:appointment,
          facility: facility_2,
          scheduled_date: 380.days.ago,
          status: "scheduled",
          patient: create(:patient, registration_facility: facility_1))
        create(:blood_pressure, patient: really_overdue_appointment.patient, facility: facility_2)
        really_overdue_patient_id = really_overdue_appointment.patient_id

        get :index, params: {per_page: "All"}

        patient_ids = (overdue_appointments_in_facility_1 + overdue_appointments_in_facility_2).map(&:patient_id)
        expected_patient_ids = patient_ids.push(really_overdue_patient_id)
        expect(assigns(:patient_summaries).map(&:id)).to match_array(expected_patient_ids)
      end
    end

    describe "pagination" do
      before :each do
        overdue_appointments_in_facility_1
        overdue_appointments_in_facility_2
      end

      it 'shows "Pagination::DEFAULT_PAGE_SIZE" records per page' do
        stub_const("Pagination::DEFAULT_PAGE_SIZE", 5)
        get :index, params: {}

        expect(response.body.scan(/recorded at/).length).to be(5)
      end

      it "shows the selected number of records per page" do
        stub_const("Pagination::DEFAULT_PAGE_SIZE", 5)
        get :index, params: {per_page: 50}

        expect(response.body.scan(/recorded at/).length).to be(6)
      end

      it "shows all records if All is selected" do
        get :index, params: {per_page: "All"}

        total_records = overdue_appointments_in_facility_1.size + overdue_appointments_in_facility_2.size

        expect(response.body.scan(/recorded at/).length).to be(total_records)
      end
    end

    describe "search filters" do
      before { facility_1 }

      it "sets search_filters to default value if no index params are present" do
        get :index, params: {}
        expect(assigns(:search_filters)).to eq(["only_less_than_year_overdue"])
      end

      it "sets search_filters to params[:search_filters] if present" do
        get :index, params: {search_filters: ["hi"]}
        expect(assigns(:search_filters)).to eq(["hi"])
      end

      it "sets search filters to empty array if any index params are present but search_filters are not present" do
        get :index, params: {per_page: 20}
        expect(assigns(:search_filters)).to eq([])
      end
    end
  end

  describe "PUT #update" do
    let(:facility) { create(:facility, facility_group: facility_group) }

    let(:patient_with_overdue_appointment) do
      patient = create(:patient, registration_facility: facility)
      create(:blood_pressure, patient: patient, facility: facility)
      patient
    end

    let(:overdue_appointment) do
      create(:appointment, :overdue,
        patient: patient_with_overdue_appointment,
        facility: facility)
    end

    let(:patient_without_overdue_appointment) do
      patient = create(:patient, registration_facility: facility)
      create(:appointment, patient: patient, facility: facility)
    end

    it "remind_to_call_later updates remind_on and creates a call_result" do
      new_remind_date = Date.current + 7.days

      put :update, params: {
        id: overdue_appointment.id,
        appointment: {
          call_result: "remind_to_call_later"
        }
      }

      overdue_appointment.reload

      expect(overdue_appointment.remind_on).to eq(new_remind_date)
      expect(overdue_appointment.call_results.remind_to_call_later).to be_present
      expect(response).to redirect_to(appointments_path)
    end

    it "agreed_to_visit updates agreed_to_visit and remind_on and creates a call_result" do
      new_remind_date = Date.current + 30.days

      put :update, params: {
        id: overdue_appointment.id,
        appointment: {
          call_result: "agreed_to_visit"
        }
      }

      overdue_appointment.reload

      expect(overdue_appointment.agreed_to_visit).to eq(true)
      expect(overdue_appointment.remind_on).to eq(new_remind_date)
      expect(overdue_appointment.call_results.agreed_to_visit).to be_present
      expect(response).to redirect_to(appointments_path)
    end

    it "already_visited updates appointment status to visited" do
      put :update, params: {
        id: overdue_appointment.id,
        appointment: {
          call_result: "already_visited"
        }
      }

      overdue_appointment.reload

      expect(overdue_appointment.status).to eq "visited"
      expect(response).to redirect_to(appointments_path)
    end

    it "already_visited updates agreed_to_visit and remind_on to nil and creates a call_result" do
      put :update, params: {
        id: overdue_appointment.id,
        appointment: {
          call_result: "already_visited"
        }
      }

      overdue_appointment.reload

      expect(overdue_appointment.agreed_to_visit).to be nil
      expect(overdue_appointment.remind_on).to be nil
      expect(overdue_appointment.call_results.removed_from_overdue_list.already_visited).to be_present
      expect(response).to redirect_to(appointments_path)
    end

    describe "marking the appointment as cancelled updates the relevant fields and creates a call_result" do
      Appointment.cancel_reasons.values.each do |cancel_reason|
        it "marked the appointment cancelled: #{cancel_reason}" do
          put :update, params: {
            id: overdue_appointment.id,
            appointment: {
              call_result: cancel_reason
            }
          }

          overdue_appointment.reload

          expect(overdue_appointment.agreed_to_visit).to be_falsey
          expect(overdue_appointment.remind_on).to be nil
          expect(overdue_appointment.cancel_reason).to eq cancel_reason
          expect(overdue_appointment.status).to eq "cancelled"
          expect(overdue_appointment.call_results.removed_from_overdue_list).to be_present
          expect(overdue_appointment.call_results.removed_from_overdue_list.first.remove_reason).to eq cancel_reason
          expect(response).to redirect_to(appointments_path)
        end
      end
    end

    it "marking the cancel reason as dead updates the patient" do
      put :update, params: {
        id: overdue_appointment.id,
        appointment: {
          call_result: "dead"
        }
      }

      overdue_appointment.reload

      expect(overdue_appointment.cancel_reason).to eq "dead"
      expect(overdue_appointment.patient.status).to eq "dead"
      expect(response).to redirect_to(appointments_path)
    end

    it "marking the cancel reason as moved_to_private updates the patient" do
      put :update, params: {
        id: overdue_appointment.id,
        appointment: {
          call_result: "moved_to_private"
        }
      }
      expect(overdue_appointment.reload.patient.status).to eq "migrated"
    end

    it "marking the cancel reason as public_hospital_transfer updates the patient" do
      put :update, params: {
        id: overdue_appointment.id,
        appointment: {
          call_result: "public_hospital_transfer"
        }
      }
      expect(overdue_appointment.reload.patient.status).to eq "migrated"
    end

    it "passes along search_filters in the redirect" do
      put :update, params: {
        id: overdue_appointment.id,
        appointment: {
          call_result: "public_hospital_transfer",
          search_filters: "one two"
        }
      }
      expect(response).to redirect_to(appointments_path + "?" + {search_filters: [:one, :two]}.to_param)
    end
  end
end
