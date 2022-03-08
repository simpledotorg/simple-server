namespace :dhis2 do
  desc "Export aggregate indicators for each facility to DHIS2"
  task export: :environment do
    DHIS2Exporter.export
  end

  desc "Export aggregate indicators for each facility to Maharashtra's DHIS2"
  task maharashtra_export: :environment do
    MaharashtraDHIS2Exporter.export
  end
end
