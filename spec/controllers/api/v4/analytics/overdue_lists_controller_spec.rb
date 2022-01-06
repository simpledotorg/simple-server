# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V4::Analytics::OverdueListsController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }

  describe "#show" do
    before :each do
      request.env["HTTP_X_USER_ID"] = request_user.id
      request.env["HTTP_X_FACILITY_ID"] = request_facility.id
      request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
    end

    it "populates a list of overdue patients for CSV download" do
      facility_patients = create_list(:patient, 3, assigned_facility: request_facility)
      overdue_appointments = facility_patients.map do |patient|
        create(:appointment, :overdue, patient: patient, facility: request_facility)
      end
      unvisited_patient = create(:patient, registration_facility: request_facility)
      create(:appointment,
        patient: unvisited_patient,
        status: :cancelled,
        scheduled_date: 1.month.ago,
        facility: request_facility)
      patient_ids = overdue_appointments.map(&:patient_id) << unvisited_patient.id

      get :show, params: {format: :csv}

      expect(assigns(:patient_summaries).map(&:id)).to match_array(patient_ids)
    end

    it "returns a 401 if user is not authenticated" do
      request.env["HTTP_AUTHORIZATION"] = nil

      get :show, params: {format: :csv}

      expect(response.status).to eq(401)
    end

    it "returns a 401 if user does not have access to the facility" do
      request.env["HTTP_X_FACILITY_ID"] = create(:facility)

      get :show, params: {format: :csv}

      expect(response.status).to eq(401)
    end
  end
end
