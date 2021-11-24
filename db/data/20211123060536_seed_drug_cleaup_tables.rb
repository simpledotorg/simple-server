class SeedDrugCleaupTables < ActiveRecord::Migration[5.2]
  def tables_to_import
    [
      {klass: PrescriptionDrugCleanup::CleanMedicineToDosage,
       filename: "#{Rails.root}/config/data/treatment-inertia/clean_medicine_to_dosage.csv"},
      {klass: PrescriptionDrugCleanup::RawToCleanMedicine,
       filename: "#{Rails.root}/config/data/treatment-inertia/raw_to_clean_medicine.csv"},
      {klass: PrescriptionDrugCleanup::MedicinePurpose,
       filename: "#{Rails.root}/config/data/treatment-inertia/medicine_purpose.csv"}
    ]
  end

  def up
    tables_to_import.each do |table|
      CSV.foreach(table[:filename], headers: true) do |row|
        table[:klass].create!(row.to_hash)
      end
    end

    def down
      tables_to_import.each do |table|
        table[:klass].destroy_all
      end
    end
  end
end
