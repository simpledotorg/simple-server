module Seed
  include DrugLookup

  class DrugLookupTablesSeeder
    TABLES_TO_IMPORT =
      [
        {klass: DrugLookup::MedicinePurpose,
          filename: "#{Rails.root}/config/data/drug-lookup/medicine_purpose.csv"},
        {klass: DrugLookup::CleanMedicineToDosage,
          filename: "#{Rails.root}/config/data/drug-lookup/clean_medicine_to_dosage.csv"},
        {klass: DrugLookup::RawToCleanMedicine,
          filename: "#{Rails.root}/config/data/drug-lookup/raw_to_clean_medicine.csv"}
      ]

    def self.drop_and_create
      drop
      create
    end

    def self.create
      TABLES_TO_IMPORT.each do |table|
        CSV.foreach(table[:filename], headers: true) do |row|
          table[:klass].create!(row.to_hash)
        end
      end
    end

    def self.drop
      table_names = TABLES_TO_IMPORT.reverse.map { |table| table[:klass].table_name }.join(", ")
      ActiveRecord::Base.connection.execute "TRUNCATE #{table_names}"
    end
  end
end
