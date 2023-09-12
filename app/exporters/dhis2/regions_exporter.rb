require "dhis2"

class Dhis2::RegionsExporter
  DHIS2_CONFIG = YAML.load_file(ENV.fetch("DHIS2_TRACKER_CONFIG_FILE")).with_indifferent_access

  def initialize(region, export_children: false)
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
    payload = generate_payload(@region, @export_children)
    response = send_to_dhis2(payload)

    if success?(response)
      store_org_unit_uids(response)
    else
      errors(response)
    end
  end

  # Can have a resume feature to keep track of org units created.
  # can write to file/etc instead of storing in memory
  def generate_payload(region, export_children)
    if export_children
      region.children.map do |child|
        # notes:
        # array of children under a parent with uid didnt fail didnt work
        # parent with uid didnt work
        # schema is here http://localhost:8080/api/schemas/organisationUnit
      end
    end

    {
      name: region.name,
      shortName: region.slug,
      openingDate: region.created_at.iso8601
    }
    # payload.merge({ parent: get_uid(region.parent.slug) }) if has_parent?(region)
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

  def has_parent?(region)
    region.path.split(".").drop(2).count.zero?
  end

  def get_uid(slug)
    DHIS2_CONFIG.fetch(:facilities_to_migrate).map do |facility|
      return facility.fetch(:org_unit_id) if facility.fetch(:facility_slug) == slug
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
