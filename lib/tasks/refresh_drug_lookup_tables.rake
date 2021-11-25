# frozen_string_literal: true

namespace :drug_lookup_tables do
  desc "Reloads the contents of the drug lookup tables from the csvs"
  task refresh: :environment do
    Seed::DrugLookupTablesSeeder.drop_and_create
  end
end
