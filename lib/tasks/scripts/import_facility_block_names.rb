class ImportFacilityBlockNames
  def self.import(file)
    facilities_updated = 0
    facilities_not_found = 0

    CSV.foreach(file, headers: true) do |row|
      district = row["district"]
      facility_name = row["facility_name"]
      block = row["block"]

      facility = Facility.where(name: facility_name, district: district)
      if facility.present?
        facilities_updated += 1 if facility.update(block: block)
      else
        facilities_not_found += 1
        Rails.logger.info "Facility #{facility_name} in #{block}, district #{district} not found"
      end
    end

    Rails.logger.info "Updated #{facilities_updated} facilities, #{facilities_updated} facilities not found"
  end
end
