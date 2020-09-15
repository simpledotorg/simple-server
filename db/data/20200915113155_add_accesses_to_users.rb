class AddAccessesToUsers < ActiveRecord::Migration[5.2]
  def up
    require "tasks/scripts/create_accesses_from_permissions"

    Organization.find_each do |org|
      CreateAccessesFromPermissions.do(organization: org, dryrun: false)
    end
  end

  def down
    Access.delete_all
    User.admins.update_all(access_level: nil)
  end
end
