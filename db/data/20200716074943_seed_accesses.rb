class SeedAccesses < ActiveRecord::Migration[5.2]
  def up
    user = User.find("d3a890ff-7459-468d-8752-031c03f5f591")
    user.accesses.create!(role: Role.admin.first, resourceable: FacilityGroup.first)
    user.accesses.create!(role: Role.analyst.first, resourceable: f)
  end

  def down
    user = User.find("d3a890ff-7459-468d-8752-031c03f5f591")
    user.accesses.delete_all
  end
end
