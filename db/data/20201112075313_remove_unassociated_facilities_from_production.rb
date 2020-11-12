class RemoveUnassociatedFacilitiesFromProduction < ActiveRecord::Migration[5.2]
  def up
    return if CountryConfig.current[:abbreviation] != "IN"

    facilities_to_purge = Facility.where(facility_group_id: nil)
    Rails.logger.info "Purging facilities that are unassociated: #{facilities_to_purge.pluck(:id).join(", ")}."
    facilities_to_purge.discard_all
  end

  def down
    Rails.logger.info "This data migration cannot be reversed. Skipping."
  end
end
