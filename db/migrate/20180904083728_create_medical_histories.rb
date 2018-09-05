class CreateMedicalHistories < ActiveRecord::Migration[5.1]
  def change
    create_table :medical_histories, id: :uuid do |t|
      t.belongs_to :patient, type: :uuid, null: false
      t.boolean :has_prior_heart_attack
      t.boolean :has_prior_stroke
      t.boolean :has_chronic_kidney_disease
      t.boolean :is_on_treatment_for_hypertension
      t.datetime :device_created_at, null: false
      t.datetime :device_updated_at, null: false
      t.timestamps
    end
  end
end
