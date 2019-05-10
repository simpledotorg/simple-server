class Api::V2::MedicalHistoriesController < Api::Current::MedicalHistoriesController
  def medical_histories_params
    params.require(:medical_histories).map do |medical_history_params|
      medical_history_params.permit(
        :id,
        :patient_id,
        :prior_heart_attack,
        :prior_stroke,
        :chronic_kidney_disease,
        :receiving_treatment_for_hypertension,
        :diabetes,
        :diagnosed_with_hypertension,
        :created_at,
        :updated_at)
    end
  end
end
