require 'rails_helper'

RSpec.describe Api::Current::MedicalHistoriesController, type: :controller do
  let(:request_user) { FactoryBot.create(:user) }
  before :each do
    request.env['X_USER_ID'] = request_user.id
    request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
  end

  let(:model) { MedicalHistory }

  let(:build_payload) { lambda { build_medical_history_payload } }
  let(:build_invalid_payload) { lambda { build_invalid_medical_history_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { lambda { |medical_history| updated_medical_history_payload medical_history } }
  let(:number_of_schema_errors_in_invalid_payload) { 2 }

  it_behaves_like 'a sync controller that authenticates user requests'
  it_behaves_like 'a sync controller that audits the data access'
  it_behaves_like 'a working sync controller that short circuits disabled apis'

  describe 'POST sync: send data from device to server;' do
    it_behaves_like 'a working sync controller creating records'
    it_behaves_like 'a working sync controller updating records'
  end

  describe 'GET sync: send data from server to device;' do
    it_behaves_like 'a working sync controller sending records'

    context 'medical histories with nil questions' do
      let(:medical_history_questions) { Api::V1::MedicalHistoryTransformer.medical_history_questions.map(&:to_s) }
      let(:nil_medical_history_questions) { medical_history_questions.map { |key| [key, nil] }.to_h }
      let(:false_medical_history_questions) { medical_history_questions.map { |key| [key, false] }.to_h }
      before :each do
        set_authentication_headers
        FactoryBot.create_list(:medical_history, 10, nil_medical_history_questions)
      end

      it 'converts nil to false in the response' do
        get :sync_to_user

        response_body = JSON(response.body)
        response_body['medical_histories'].each do |medical_history|
          expect(medical_history.slice(*medical_history_questions)).to eq(false_medical_history_questions)
        end
      end
    end
  end
end
