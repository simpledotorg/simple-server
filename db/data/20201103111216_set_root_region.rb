class SetRootRegion < ActiveRecord::Migration[5.2]
  def up
    Region.create!(name: Rails.application.config.country[:name],
                   region_type: Region.region_types[:root],
                   path: Rails.application.config.country[:name].downcase.underscore)
  end

  def down
    Region.root.delete_all
  end
end
