class SeedDrugCleaupTables < ActiveRecord::Migration[5.2]
  TABLES_TO_IMPORT =
    [
      {klass: PrescriptionDrugCleanup::CleanMedicineToDosage,
       filename: "#{Rails.root}/config/data/treatment-inertia/clean_medicine_to_dosage.csv"},
      {klass: PrescriptionDrugCleanup::RawToCleanMedicine,
       filename: "#{Rails.root}/config/data/treatment-inertia/raw_to_clean_medicine.csv"},
      {klass: PrescriptionDrugCleanup::MedicinePurpose,
       filename: "#{Rails.root}/config/data/treatment-inertia/medicine_purpose.csv"}
    ]

  def up
    TABLES_TO_IMPORT.each do |table|
      CSV.foreach(table[:filename], headers: true) do |row|
        table[:klass].create!(row.to_hash)
      end
    end
  end

  def down
    TABLES_TO_IMPORT.each do |table|
      execute "TRUNCATE #{table[:klass].table_name}"
    end
  end
end
