require "rails_helper"

describe Api::V4::PatientScoresController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:model) { PatientScore }

  def create_record(options = {})
    facility = create(:facility, facility_group: request_facility_group)
    patient = create(:patient, registration_facility: facility)
    create(:patient_score, options.merge(patient: patient))
  end

  def create_record_list(n, options = {})
    facility = create(:facility, facility_group_id: request_facility_group.id)
    patient = create(:patient, registration_facility_id: facility.id)
    create_list(:patient_score, n, options.merge(patient: patient))
  end

  it_behaves_like "a sync controller that authenticates user requests: sync_to_user"
  it_behaves_like "a sync controller that audits the data access: sync_to_user"

  describe "GET sync: send data from server to device;" do
    it_behaves_like "a working V3 sync controller sending records"

    it "advances the process_token when many records share one updated_at" do
      set_authentication_headers
      shared_ts = 5.minutes.ago
      facility = create(:facility, facility_group: request_facility_group)
      patient = create(:patient, registration_facility: facility)
      records = create_list(:patient_score, 5, patient: patient, updated_at: shared_ts)
      expected_ids = records.map(&:id).to_set

      received_ids = Set.new
      process_token = nil

      3.times do
        reset_controller
        set_authentication_headers
        get :sync_to_user, params: {limit: 2, process_token: process_token}.compact

        body = JSON(response.body)
        body["patient_scores"].each { |r| received_ids << r["id"] }
        process_token = body["process_token"]
        break if body["patient_scores"].empty?
      end

      expect(received_ids).to eq(expected_ids)
    end
  end
end
