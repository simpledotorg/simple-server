class RemoveUnassociatedFacilitiesFromProduction < ActiveRecord::Migration[5.2]
  def up
    return if SIMPLE_SERVER_ENV != "production"
    return if ENV["DEFAULT_COUNTRY"] != "IN"

    Facility.where(facility_group_id: nil).delete_all
  end

  def down
    Rails.logger.info "This data migration cannot be reversed. Skipping."
  end
end
