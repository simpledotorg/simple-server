namespace :dhis2 do
  desc "Export indicator data of each facility to Bangladesh DHIS2"
  task bangladesh_export: :environment do
    FacilityBusinessIdentifier.dhis2_org_unit_id.each do |facility_identifier|
      Dhis2::Dhis2ExporterJob.perform_async(facility_identifier.id, 24)
    end
  end

  desc "Export disaggregated indicator data of each facility to Bangladesh DHIS2"
  task bangladesh_disaggregated_export: :environment do
    FacilityBusinessIdentifier.dhis2_org_unit_id.each do |facility_identifier|
      Dhis2::BangladeshDisaggregatedExporterJob.perform_async(facility_identifier.id, 24)
    end
  end

  desc "Export data of each facility to Ethiopia DHIS2"
  task ethiopia_export: :environment do
    FacilityBusinessIdentifier.dhis2_org_unit_id.each do |facility_identifier|
      Dhis2::Dhis2ExporterJob.perform_async(facility_identifier.id, 24)
    end
  end
end
