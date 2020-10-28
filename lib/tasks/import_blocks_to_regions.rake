require "tasks/scripts/import_blocks_to_regions"

desc "Import zones from canonical list to Region"
task :import_zones_to_regions, [:organization_name, :dry_run] => :environment do |_t, args|
  abort "Requires <organization_name>" unless args[:organization_name].present?

  ImportBlocksToRegions.import(args[:organization_name], dry_run: args[:dry_run])
end
