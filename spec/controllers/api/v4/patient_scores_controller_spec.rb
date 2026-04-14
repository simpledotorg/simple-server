require "rails_helper"

describe Api::V4::PatientScoresController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:model) { PatientScore }

  def create_record(options = {})
    patient = create(:patient, registration_facility: request_facility)
    create(:patient_score, options.merge(patient: patient))
  end

  def create_record_list(n, options = {})
    patient = create(:patient, registration_facility: request_facility)
    create_list(:patient_score, n, options.merge(patient: patient))
  end

  it_behaves_like "a sync controller that authenticates user requests: sync_to_user"
  it_behaves_like "a sync controller that audits the data access: sync_to_user"

  describe "GET sync: send data from server to device;" do
    before { set_authentication_headers }

    it "returns only current facility patient scores" do
      expected = create_record_list(3)
      other_patient = create(:patient, registration_facility: create(:facility, facility_group: request_facility_group))
      create(:patient_score, patient: other_patient)

      get :sync_to_user

      body = JSON(response.body)
      expect(body["patient_scores"].map { |r| r["id"] }.to_set)
        .to eq(expected.map(&:id).to_set)
    end

    it "paginates via next_page token across multiple requests with a shared updated_at" do
      shared_ts = 5.minutes.ago
      records = create_record_list(5, updated_at: shared_ts)
      expected_ids = records.map(&:id).to_set

      received_ids = Set.new
      process_token = nil

      4.times do
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

    it "advances next_page on every non-empty page and resets to 1 only on an empty page" do
      create_record_list(5, updated_at: 5.minutes.ago)

      get :sync_to_user, params: {limit: 2}
      body1 = JSON(response.body)
      expect(body1["patient_scores"].size).to eq(2)
      expect(parse_process_token(body1)[:next_page]).to eq(2)

      reset_controller
      set_authentication_headers
      get :sync_to_user, params: {limit: 2, process_token: body1["process_token"]}
      body2 = JSON(response.body)
      expect(body2["patient_scores"].size).to eq(2)
      expect(parse_process_token(body2)[:next_page]).to eq(3)

      reset_controller
      set_authentication_headers
      get :sync_to_user, params: {limit: 2, process_token: body2["process_token"]}
      body3 = JSON(response.body)
      expect(body3["patient_scores"].size).to eq(1)
      expect(parse_process_token(body3)[:next_page]).to eq(4)

      reset_controller
      set_authentication_headers
      get :sync_to_user, params: {limit: 2, process_token: body3["process_token"]}
      body4 = JSON(response.body)
      expect(body4["patient_scores"]).to eq([])
      expect(parse_process_token(body4)[:next_page]).to eq(1)
    end

    it "returns an empty list and next_page=1 when there is nothing to sync" do
      get :sync_to_user

      body = JSON(response.body)
      token = parse_process_token(body)
      expect(body["patient_scores"]).to eq([])
      expect(token[:next_page]).to eq(1)
    end

    it "returns discarded records" do
      records = create_record_list(3, updated_at: 5.minutes.ago)
      records.first.patient.discard_data(reason: nil)

      get :sync_to_user

      body = JSON(response.body)
      expect(body["patient_scores"].size).to eq(3)
    end
  end
end
