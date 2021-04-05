class CreateTreatmentGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :treatment_groups, id: :uuid do |t|
      t.integer :index, null: false
      t.string :description, null: false
      t.references :experiment, type: :uuid, null: false, foreign_key: true
      t.timestamps null: false
    end
  end
end
