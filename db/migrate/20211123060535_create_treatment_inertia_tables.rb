class CreateTreatmentInertiaTables < ActiveRecord::Migration[5.2]
  def up
    create_table :clean_medicine_to_dosage, id: false do |t|
      t.bigint :rxcui, null: false
      t.string :medicine, null: false
      t.float :dosage, null: false
    end

    create_table :raw_to_clean_medicine, id: false do |t|
      t.string :raw_name, null: false
      t.string :raw_dosage, null: false
      t.bigint :rxcui, null: false
    end

    create_table :medicine_purpose, id: false do |t|
      t.string :name, null: false
      t.boolean :hypertension, null: false
      t.boolean :diabetes, null: false
    end
  end

  def down
    drop_table :medicine_purpose
    drop_table :raw_to_clean_medicine
    drop_table :clean_medicine_to_dosage
  end
end
