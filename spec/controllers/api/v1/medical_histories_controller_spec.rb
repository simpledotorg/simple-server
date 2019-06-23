require 'rails_helper'

RSpec.describe Api::V1::MedicalHistoriesController, type: :controller do
  let(:request_user) { FactoryBot.create(:user) }
  before :each do
    request.env['X_USER_ID'] = request_user.id
    request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
  end

  let(:model) { MedicalHistory }

  let(:build_payload) { lambda { build_medical_history_payload_v1 } }
  let(:build_invalid_payload) { lambda { build_invalid_medical_history_payload_v1 } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { lambda { |medical_history| updated_medical_history_payload_v1 medical_history } }
  let(:number_of_schema_errors_in_invalid_payload) { 2 }

  def create_record(options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    patient = FactoryBot.create(:patient, registration_facility: facility)
    FactoryBot.create(:medical_history, options.merge(patient: patient))
  end

  def create_record_list(n, options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    patient = FactoryBot.create(:patient, registration_facility: facility)
    FactoryBot.create_list(:medical_history, n, options.merge(patient: patient))
  end

  it_behaves_like 'a sync controller that authenticates user requests'
  it_behaves_like 'a sync controller that audits the data access'
  it_behaves_like 'a working sync controller that short circuits disabled apis'

  describe 'POST sync: send data from device to server;' do
    it_behaves_like 'a working sync controller creating records'

    describe 'updates records' do
      let(:existing_records) do
        FactoryBot.create_list(:medical_history, 3)
      end
      let(:record_updates) { MedicalHistory::MEDICAL_HISTORY_QUESTIONS.map { |key| [key.to_s, %w(unknown yes).sample] }.to_h }
      let(:updated_records) { existing_records.map { |record| build_medical_history_payload_current(record).merge(record_updates).merge(updated_at: 10.minutes.from_now) } }
      let(:updated_payload) do
        medical_histories = updated_records.map do |payload|
          payload.map do |key, value|
            if MedicalHistory::MEDICAL_HISTORY_QUESTIONS.include?(key.to_sym)
              [key, Api::V1::MedicalHistoryTransformer::MEDICAL_HISTORY_ANSWERS_MAP[value]]
            else
              [key, value]
            end
          end.to_h
        end
        { medical_histories: medical_histories }
      end

      before :each do
        set_authentication_headers
      end

      it 'with updated record attributes' do
        post :sync_from_user, params: updated_payload, as: :json

        updated_records.each do |record|
          db_record = MedicalHistory.find(record['id'])
          expect(db_record.attributes.to_json_and_back.with_payload_keys.with_int_timestamps)
            .to eq(record.to_json_and_back.with_int_timestamps)
        end
      end

      describe 'updating from unknown to false' do
        let(:existing_record) do
          FactoryBot.create(:medical_history, :unknown)
        end

        let(:updated_payload) do
          updates = MedicalHistory::MEDICAL_HISTORY_QUESTIONS.map { |key| [key, false] }.to_h
          updates[:prior_heart_attack] = true
          { medical_histories: [existing_record.attributes.merge(updates)] }
        end

        it 'ignores fields marked false in the updates' do
          post :sync_from_user, params: updated_payload, as: :json

          db_record = MedicalHistory.find(existing_record.id)
          expect(db_record.prior_heart_attack).to eq('yes')
          (MedicalHistory::MEDICAL_HISTORY_QUESTIONS - [:prior_heart_attack]).each do |key|
            expect(db_record.read_attribute(key)).to eq('unknown')
          end
        end

        it 'creates a sentry alert' do
          expect(Raven).to receive(:capture_message)
          post :sync_from_user, params: updated_payload, as: :json
        end
      end
    end
  end

  describe 'GET sync: send data from server to device;' do
    it_behaves_like 'a working V1 sync controller sending records'

    context 'medical histories with nil questions' do
      let(:medical_history_questions) { MedicalHistory::MEDICAL_HISTORY_QUESTIONS.map(&:to_s) }
      let(:false_medical_history_questions) { medical_history_questions.map { |key| [key, false] }.to_h }
      before :each do
        set_authentication_headers
        FactoryBot.create_list(:medical_history, 2, :unknown)
        FactoryBot.create_list(:medical_history, 2)
      end

      it 'converts :unknown and :no to false in the response' do
        get :sync_to_user

        response_body = JSON(response.body)
        response_body['medical_histories'].each do |medical_history|
          expect(medical_history.slice(*medical_history_questions)).to eq(false_medical_history_questions)
        end
      end
    end
  end

  describe 'syncing within a facility group' do
    let(:facility_in_same_group) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
    let(:facility_in_another_group) { FactoryBot.create(:facility) }

    let(:patient_in_same_group) { FactoryBot.create(:patient, registration_facility: facility_in_same_group) }
    let(:patient_in_another_group) { FactoryBot.create(:patient, registration_facility: facility_in_another_group) }

    before :each do
      set_authentication_headers

      FactoryBot.create_list(:medical_history, 2, patient: patient_in_same_group, updated_at: 5.minutes.ago)
      FactoryBot.create_list(:medical_history, 2, patient: patient_in_another_group, updated_at: 3.minutes.ago)
    end

    it "only sends data for facilities belonging in the sync group of user's registration facility" do
      get :sync_to_user, params: { limit: 15 }

      response_medical_histories = JSON(response.body)['medical_histories']
      response_patients = response_medical_histories.map { |medical_history| medical_history['patient_id'] }.to_set

      expect(response_medical_histories.count).to eq 2
      expect(response_patients).not_to include(patient_in_another_group.id)
    end
  end
end