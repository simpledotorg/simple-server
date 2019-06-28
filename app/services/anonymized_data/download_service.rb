require 'csv'

class AnonymizedData::DownloadService
  def run_for_district(recipient_name, recipient_email, district_name, organization_id)
    organization_district = OrganizationDistrict.new(district_name, Organization.find(organization_id))
    names_of_facilities = organization_district.facilities.flat_map(&:name).sort

    send_email(recipient_name, recipient_email,
               anonymize(AnonymizedData::DistrictData.new(organization_district).raw_data),
               { district_name: district_name, facilities: names_of_facilities })
  end

  def run_for_facility(recipient_name, recipient_email, facility_id)
    facility = Facility.find(facility_id)

    send_email(recipient_name, recipient_email,
               anonymize(AnonymizedData::FacilityData.new(facility).raw_data),
               { facility_name: facility.name, facilities: [facility.name] })
  end

  private

  def send_email(recipient_name, recipient_email, anonymized_data, resource)
    AnonymizedDataDownloadMailer
      .with(recipient_name: recipient_name,
            recipient_email: recipient_email,
            anonymized_data: anonymized_data,
            resource: resource)
      .mail_anonymized_data
      .deliver_later
  end

  def anonymize(csv_data_map)
    combined_csv_data = {}

    csv_data_map.each do |file_name, data|
      combined_csv_data[file_name] = to_csv(data)
    end

    combined_csv_data
  end

  def to_csv(resources)
    return unless resources.present?

    klass = resources.first.class
    headers = klass::ANONYMIZED_DATA_FIELDS

    CSV.generate(headers: true) do |csv|
      csv << headers.map(&:titleize)

      resources.map do |r|
        values = r.anonymized_data
        csv << headers.map do |h|
          values[h.to_sym] || AnonymizedData::Constants::UNAVAILABLE
        end
      end
    end
  end
end