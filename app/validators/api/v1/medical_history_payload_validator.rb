class Api::V1::MedicalHistoryPayloadValidator < Api::Current::MedicalHistoryPayloadValidator
  def schema
    Api::V1::Models.medical_history
  end
end
