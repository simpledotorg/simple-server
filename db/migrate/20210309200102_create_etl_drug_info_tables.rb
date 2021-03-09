class CreateEtlDrugInfoTables < ActiveRecord::Migration[5.2]
  def change
    create_table :raw_to_clean_medicines, id: :uuid do |t|
      t.string raw_name
      t.string raw_dosage
      t.integer rxcui
      t.timestamps
    end

    add_index :raw_to_clean_medicines, [:raw_name, :raw_dosage], unique: true

    create_table :clean_medicine_to_dosages, id: :uuid do |t|
      t.integer rxcui, unique: true
      t.string medicine
      t.decimal dosage
      t.timestamps
    end

    create_table :medicine_purposes, id: :uuid do |t|
      t.string name
      t.boolean hypertension
      t.boolean diabetes
      t.timestamps
    end

    create_table :protocol_step_definitions, id: :uuid do |t|
      t.uuid protocol_id
      t.integer step
      t.decimal amlodipine
      t.decimal aspirin
      t.decimal atenolol
      t.decimal atorvastatin
      t.decimal captopril
      t.decimal chlorthalidone
      t.decimal clopidogrel
      t.decimal enalapril
      t.decimal glibenclamide
      t.decimal gliclazide
      t.decimal glimepiride
      t.decimal glipizide
      t.decimal hydrochlorothiazide
      t.decimal lisinopril
      t.decimal losartan
      t.decimal losartan-hydrochlorathiazide
      t.decimal losartan_h
      t.decimal losartan-amlodipine
      t.decimal metoprolol
      t.decimal metoprolol_xl
      t.decimal metformin
      t.decimal metformin_sr
      t.decimal propranolol
      t.decimal rosuvastatin
      t.decimal sitagliptin
      t.decimal spironolactone
      t.decimal telmisartan
      t.decimal telvas_3d
      t.decimal vildagliptin
      t.decimal other_bp_medications
      t.timestamps
    end
  end
end
