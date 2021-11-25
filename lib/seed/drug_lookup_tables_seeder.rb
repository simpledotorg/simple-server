module Seed
  class DrugLookupTablesSeeder
    TABLES_TO_IMPORT =
      [
        {klass: "DrugLookup::CleanMedicineToDosage",
         filename: "#{Rails.root}/config/data/drug-lookup/clean_medicine_to_dosage.csv"},
        {klass: "DrugLookup::RawToCleanMedicine",
         filename: "#{Rails.root}/config/data/drug-lookup/raw_to_clean_medicine.csv"},
        {klass: "DrugLookup::MedicinePurpose",
         filename: "#{Rails.root}/config/data/drug-lookup/medicine_purpose.csv"}
      ]

    def self.drop_and_create
      drop
      create
    end

    def self.create
      TABLES_TO_IMPORT.each do |table|
        CSV.foreach(table[:filename], headers: true) do |row|
          table[:klass].constantize.create!(row.to_hash)
        end
      end
    end

    def self.drop
      TABLES_TO_IMPORT.each do |table|
        ActiveRecord::Base.connection.execute "TRUNCATE #{table[:klass].constantize.table_name}"
      end
    end
  end
end
