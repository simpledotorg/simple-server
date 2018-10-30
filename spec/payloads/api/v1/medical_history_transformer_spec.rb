require 'rails_helper'

describe Api::V1::MedicalHistoryTransformer do
  describe 'to_response' do
    let(:medical_history_questions) { Api::V1::MedicalHistoryTransformer.medical_history_questions.map(&:to_s) }
    let(:nil_medical_history_questions) { medical_history_questions.map { |key| [key, nil] }.to_h }
    let(:false_medical_history_questions) { medical_history_questions.map { |key| [key, false] }.to_h }
    let(:medical_history) { FactoryBot.create(:medical_history, nil_medical_history_questions) }

    it 'converts nils to false for medical history questions' do
      transformed_medical_history = Api::V1::MedicalHistoryTransformer.to_response(medical_history)
      expect(transformed_medical_history.slice(*medical_history_questions))
        .to eq(false_medical_history_questions)
    end
  end
end
