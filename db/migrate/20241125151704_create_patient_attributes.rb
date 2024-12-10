class CreatePatientAttributes < ActiveRecord::Migration[6.1]
  def change
    create_table :patient_attributes, id: :uuid do |t|
      t.decimal :height
      t.decimal :weight
      t.references :patient, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
