require "dhis2"

class Dhis2::RegionsExporter
  DHIS2_CONFIG = YAML.load_file(ENV.fetch("DHIS2_TRACKER_CONFIG_FILE")).with_indifferent_access

  def initialize(region, export_children = false)
    @region = region
    @export_children = export_children

    configure
  end

  def configure
    Dhis2.configure do |config|
      config.url = ENV.fetch("DHIS2_URL")
      config.user = ENV.fetch("DHIS2_USERNAME")
      config.password = ENV.fetch("DHIS2_PASSWORD")
    end
  end

  def export
    unless @region
      puts "ERROR: Pass a valid region to export"
      return
    end

    if @export_children
      unless get_uid(@region)
        puts "ERROR: Parent region does not exist on DHIS2. Export it individually first."
        return
      end

      export_regions(@region.children)
    else
      export_region(@region)
    end
  end

  def export_region(region)
    payload = generate_payload(region)
    success = []
    error = []

    response = send_to_dhis2(payload)
    if success?(response)
      success.append(store_org_unit_uids(region, response))
    else
      error.append(errors(response))
    end

    puts "Attempted to export 1 region.\nSuccessful exports: #{success.size} - #{success}\nErrors: #{error}"
  end

  def export_regions(children)
    errors = []
    successes = []

    children.map do |child|
      payload = generate_payload(child, true)
      response = send_to_dhis2(payload)
      if success?(response)
        successes.append(store_org_unit_uids(child, response))
      else
        errors.append(errors(response))
      end
    end

    puts "Attempted to export #{children.size} regions.\nSuccessful exports: #{successes.size} - #{successes}\nErrors: #{errors}"
  end

  # Can have a resume feature to keep track of org units created.
  # can write to file/etc instead of storing in memory
  def generate_payload(region, is_child = false)
    payload = {
      name: region.name,
      shortName: region.slug,
      openingDate: region.created_at.iso8601
    }

    return payload unless is_child

    payload.merge({
      parent: {
        id: get_uid(region.parent)
      }
    })
  end

  def send_to_dhis2(payload)
    Dhis2.client.post(
      path: "organisationUnits",
      payload: payload
    )
  end

  def success?(response)
    response.with_indifferent_access.fetch(:http_status_code).in?([200, 201])
  end

  def errors(response)
    response.with_indifferent_access.dig(:response, :error_reports)
  end

  def get_uid(region)
    region_slug = "#{region.region_type}_slug".to_sym
    DHIS2_CONFIG.dig(:regions_to_migrate, region.region_type.to_sym)&.map do |region_to_migrate|
      next unless region_to_migrate.fetch(region_slug) == region.slug

      return region_to_migrate.fetch(:org_unit_id)
    end
    nil
  end

  def store_org_unit_uids(region, response)
    response = response.with_indifferent_access
    region_type = region.region_type
    region_key = "#{region_type}_slug".to_sym
    config_key = region_type.to_sym

    region_info = {
      region_key => region.slug,
      :org_unit_id => response.dig(:response, :uid)
    }

    config = DHIS2_CONFIG
    (config[:regions_to_migrate][config_key] ||= []) << region_info
    File.write(ENV.fetch("DHIS2_TRACKER_CONFIG_FILE"), config.to_hash.to_yaml)

    region_info
  end
end
