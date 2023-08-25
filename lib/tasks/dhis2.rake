namespace :dhis2 do
  desc "Export indicator data of each facility to Bangladesh DHIS2"
  task export: :environment do
    BangladeshDhis2Exporter.export
  end

  desc "Export disaggregated indicator data of each facility to Bangladesh DHIS2"
  task bangladesh_disaggregated_export: :environment do
    BangladeshDisaggregatedDhis2Exporter.export
  end

  desc "Export data of each facility to Ethiopia DHIS2"
  task ethiopia_export: :environment do
    EthiopiaDhis2Exporter.export
  end
end
