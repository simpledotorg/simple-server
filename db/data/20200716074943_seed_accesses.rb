class SeedAccesses < ActiveRecord::Migration[5.2]
  def up
    admin = EmailAuthentication.find_by_email("admin@simple.org").user
    admin.accesses.admin.create!(resource: FacilityGroup.first)
  end

  def down
    admin = EmailAuthentication.find_by_email("admin@simple.org").user
    admin.accesses.delete_all
  end
end
