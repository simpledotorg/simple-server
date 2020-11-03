class SetRootRegion < ActiveRecord::Migration[5.2]
  def up
    Region.create!(name: Rails.application.config.country[:name], region_type: Region.region_types[:root])
  end

  def down
    Region.root.delete_all
  end
end
