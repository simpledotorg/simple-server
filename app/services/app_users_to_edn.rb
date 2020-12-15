class AppUsersToEDN
  def self.convert
    users =
      User
        .non_admins
        .joins(:phone_number_authentications)
        .where(sync_approval_status: "allowed")
        .reject { |u| u.registration_facility.blank? }
        .map { |u|
          {
            id: u.id,
            access_token: u.access_token,
            facility_id: u.registration_facility.id,
            sync_region_id: u.registration_facility.region.block_region.id
          }
        }

    File.write("/tmp/sync_to_user.edn", {users: users}.to_edn)
  end
end
