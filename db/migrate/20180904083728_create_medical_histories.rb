class CreateMedicalHistories < ActiveRecord::Migration[5.1]
  def change
    create_table :medical_histories, id: :uuid do |t|
      t.belongs_to :patient, type: :uuid, null: false
      t.boolean :prior_heart_attack
      t.boolean :prior_stroke
      t.boolean :chronic_kidney_disease
      t.boolean :receiving_treatment_for_hypertension
      t.datetime :device_created_at, null: false
      t.datetime :device_updated_at, null: false
      t.timestamps
    end
  end
end
