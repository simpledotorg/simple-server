class AddEnumFieldsForMedicalHistoryQuestions < ActiveRecord::Migration[5.1]
  def change
    rename_column :medical_histories, :prior_heart_attack, :prior_heart_attack_boolean
    rename_column :medical_histories, :prior_stroke, :prior_stroke_boolean
    rename_column :medical_histories, :chronic_kidney_disease, :chronic_kidney_disease_boolean
    rename_column :medical_histories, :receiving_treatment_for_hypertension, :receiving_treatment_for_hypertension_boolean
    rename_column :medical_histories, :diabetes, :diabetes_boolean
    rename_column :medical_histories, :diagnosed_with_hypertension, :diagnosed_with_hypertension_boolean

    add_column :medical_histories, :prior_heart_attack, :text, null: true
    add_column :medical_histories, :prior_stroke, :text, null: true
    add_column :medical_histories, :chronic_kidney_disease, :text, null: true
    add_column :medical_histories, :receiving_treatment_for_hypertension, :text, null: true
    add_column :medical_histories, :diabetes, :text, null: true
    add_column :medical_histories, :diagnosed_with_hypertension, :text, null: true
  end
end
