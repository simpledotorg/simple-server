desc "Export reporting table schemas in custom formats for documentation"
task export_reporting_schema: :environment do |_t, args|
  require "tasks/scripts/export_reporting_schema"

  begin
    ExportReportingSchema.export_all_tables
  rescue => e
    puts "Failed to export reporting schemas: #{e.message}"
  end
end
