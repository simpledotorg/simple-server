# frozen_string_literal: true
require "dhis2"

class DHIS2Importer
  def initialize
    configure
  end

  def configure
    Dhis2.configure do |config|
      config.url = ENV.fetch("DHIS2_URL")
      config.user = ENV.fetch("DHIS2_USERNAME")
      config.password = ENV.fetch("DHIS2_PASSWORD")
    end
  end

  def fetch_org_units(params = {})
    Dhis2.client.get(
      path: "organisationUnits",
      query_params: params
    )
  end

  def fetch_org_units_by_region_type(region_type)
    level = {
      country: 1,
      state: 2,
      district: 3,
      block: 4,
      facility: 5
    }
    fetch_org_units(level: level[region_type])
  end

  def fetch_facility_level_org_units
    fetch_org_units_by_region_type(:facility)
  end

  def org_units(response)
    response.with_indifferent_access[:organisation_units].map do |org_unit|
      {
        display_name: org_unit[:display_name],
        org_unit_id: org_unit[:id]
      }
    end
  end

  def write_to_config(org_units)
    dhis2_config = YAML.load_file(ENV.fetch("DHIS2_TRACKER_CONFIG_FILE")).with_indifferent_access
    dhis2_config[:facilities_to_migrate].concat(org_units)
    File.write(ENV.fetch("DHIS2_TRACKER_CONFIG_FILE"), dhis2_config.to_hash.to_yaml)
  end

  def import_org_units
    fetch_facility_level_org_units.then do |response|
      org_units(response).then do |org_units|
        write_to_config(org_units)
      end
    end
  end
end
