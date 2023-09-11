require "dhis2"

class Dhis2::RegionsExporter
  DHIS2_CONFIG = YAML.load_file(ENV.fetch("DHIS2_TRACKER_CONFIG_FILE")).with_indifferent_access

  # all regions are stored
  # but only org, facgrp and facs have source types
  # use path to get parent name
  # how to get uid of parent
  # export line by line
  # export organization
  # get uid in response
  # export states with this parent uid
  # store received uids in config against their names
  # export districts with parent uids
  # etc
  # are we getting uid with name in response
  # use slug as name
  #
  def initialize(region)
    @region = region
    configure
  end

  def configure
    Dhis2.configure do |config|
      config.url = ENV.fetch("DHIS2_URL")
      config.user = ENV.fetch("DHIS2_USERNAME")
      config.password = ENV.fetch("DHIS2_PASSWORD")
    end
  end

  # Can have a resume feature to keep track of org units created.
  # can write to file/etc instead of storing in memory
  def export_region
    payload = {
      name: @region.name,
      shortName: @region.slug,
      openingDate: @region.created_at.iso8601
    }
    if has_parent?(@region)
      payload.merge({parent: get_parent_uid(@region)})
    end

    response = Dhis2.client.post(path: "organisationUnits",
      payload: payload)

    if response.with_indifferent_access.fetch(:http_status_code).in?([200, 201])
      store_org_unit_uids(response)
    else
      response.with_indifferent_access.dig(:response, :error_reports)
    end
  end

  def has_parent?(region)
    region.path.split(".").drop(2).count.zero?
  end

  def get_parent_uid(region)
    parent_slug = region.path.split(".").last
    get_uid(parent_slug)
  end

  def get_uid(slug)
    DHIS2_CONFIG.fetch(:facilities_to_migrate).map do |facility|
      if facility.fetch(:facility_slug) == slug
        return facility.fetch(:org_unit_id)
      end
    end
  end

  def store_org_unit_uids(response)
    response = response.with_indifferent_access
    uid = response.dig(:response, :uid)

    config = DHIS2_CONFIG
    config[:facilities_to_migrate] << {
      facility_slug: @region.slug,
      org_unit_id: uid
    }
    File.write(ENV.fetch("DHIS2_TRACKER_CONFIG_FILE"), config.to_hash.to_yaml)
    puts "wrote uid to file"
  end
end
