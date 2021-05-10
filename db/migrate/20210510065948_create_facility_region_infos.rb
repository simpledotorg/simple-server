class CreateFacilityRegionInfos < ActiveRecord::Migration[5.2]
  def change
    create_view :facility_region_infos
  end
end
