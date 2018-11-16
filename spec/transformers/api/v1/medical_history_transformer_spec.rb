require 'rails_helper'

describe Api::V1::MedicalHistoryTransformer do
  describe 'to_response' do
    let(:medical_history_questions) { MedicalHistory::MEDICAL_HISTORY_QUESTIONS.map(&:to_s) }
    let(:false_medical_history_questions) { medical_history_questions.map { |key| [key, false] }.to_h }
    let(:medical_history_questions_marked_no) {  }
    let(:unknown_medical_history) { FactoryBot.build(:medical_history, :unknown) }
    let(:medical_history) { FactoryBot.build(:medical_history) }

    it 'converts :unknown to false for medical history questions' do
      transformed_medical_history = Api::V1::MedicalHistoryTransformer.to_response(unknown_medical_history)
      expect(transformed_medical_history.slice(*medical_history_questions))
        .to eq(false_medical_history_questions)
    end

    it 'converts :no to false for medical history questions' do
      transformed_medical_history = Api::V1::MedicalHistoryTransformer.to_response(medical_history)
      expect(transformed_medical_history.slice(*medical_history_questions))
        .to eq(false_medical_history_questions)
    end

    it 'removes boolean fields from medical history hashes' do
      transformed_medical_history = Api::V1::MedicalHistoryTransformer.to_response(medical_history)
      MedicalHistory::MEDICAL_HISTORY_QUESTIONS.each do |question|
        expect(transformed_medical_history["#{question}_boolean"]).not_to be_present
      end
    end
  end
end
