require 'rails_helper'

describe Api::Current::MedicalHistoryTransformer do
  describe 'to_response' do
    let(:medical_history) { FactoryBot.build(:medical_history) }

    it 'removes boolean fields from medical history hashes' do
      transformed_medical_history = Api::Current::MedicalHistoryTransformer.to_response(medical_history)
      MedicalHistory::MEDICAL_HISTORY_QUESTIONS.each do |question|
        expect(transformed_medical_history["#{question}_boolean"]).not_to be_present
      end
    end

    it 'removes user_id from medical history response hashes' do
      transformed_medical_history = Api::Current::MedicalHistoryTransformer.to_response(medical_history)
        expect(transformed_medical_history).not_to include('user_id')
    end
  end
end