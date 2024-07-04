# frozen_string_literal: true

class DisableUsersInMigratedFacilities < ActiveRecord::Migration[6.1]
  REGIONS_WITH_ONGOING_ACCESS = [
    {region_type: :state, slug: "west-bengal"},
    {region_type: :state, slug: "nagaland"},
    {region_type: :district, slug: "chennai"},
    {region_type: :district, slug: "pimpri-chinchwad-municipal-corporation"},
    {region_type: :district, slug: "pune-municipal-corporation"}
  ]
  def up
    unless CountryConfig.current_country?("India") && ENV["SIMPLE_SERVER_ENV"] == "production"
      return print "DisableUsersInMigratedFacilities is only for production India"
    end

    users_with_remaining_access = REGIONS_WITH_ONGOING_ACCESS.flat_map do |region_details|
      region = Region.find_by(region_details)
      next unless region

      if region.district_region?
        region.source.users.sync_approval_status_allowed
      elsif region.state_region?
        region.children.flat_map { |district| district.source.users.sync_approval_status_allowed }
      end
    end

    all_allowed_users = User.all.sync_approval_status_allowed.pluck(:id)
    disabled_users = all_allowed_users - users_with_remaining_access.map(&:id)

    User.where(id: disabled_users).update_all(
      sync_approval_status: :denied,
      sync_approval_status_reason: "Instructions to disable users"
    )
  end

  def down
    print "DisableUsersInMigratedFacilities cannot be reversed."
  end
end
