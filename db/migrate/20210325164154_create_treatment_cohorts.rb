class CreateTreatmentCohorts < ActiveRecord::Migration[5.2]
  def change
    create_table :treatment_cohorts, id: :uuid do |t|
      t.integer :bucketing_index, null: false
      t.string :description, null: false
      t.references :experiment, type: :uuid, null: false, foreign_key: true
      t.timestamps null: false
    end
  end
end
