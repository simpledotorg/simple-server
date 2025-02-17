namespace :dhis2 do
  desc "Export indicator data of each facility to Bangladesh DHIS2"
  task bangladesh_export: :environment do
    FacilityBusinessIdentifier.dhis2_org_unit_id.each do |facility_identifier|
      Dhis2::BangladeshExporterJob.perform_async(facility_identifier.id, 24)
    end
  end

  desc "Export disaggregated hypertension indicator data of each facility to Bangladesh DHIS2"
  task bangladesh_disaggregated_hypertension_export: :environment do
    FacilityBusinessIdentifier.dhis2_org_unit_id.each do |facility_identifier|
      Dhis2::BangladeshDisaggregatedHypertensionExporterJob.perform_async(facility_identifier.id, 24)
    end
  end

  desc "Export disaggregated diabetes indicator data of each facility to Bangladesh DHIS2"
  task bangladesh_disaggregated_diabetes_export: :environment do
    FacilityBusinessIdentifier.dhis2_org_unit_id.each do |facility_identifier|
      Dhis2::BangladeshDisaggregatedDiabetesExporterJob.perform_async(facility_identifier.id, 24)
    end
  end

  desc "Export data of each facility to Ethiopia DHIS2"
  task ethiopia_export: :environment do
    FacilityBusinessIdentifier.dhis2_org_unit_id.each do |facility_identifier|
      Dhis2::EthiopiaExporterJob.perform_async(facility_identifier.id, 24)
    end
  end
end
