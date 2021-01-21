class AddProtocolIdToFacilityGroup < ActiveRecord::Migration[5.1]
  def change
    add_column :facility_groups, :protocol_id, :uuid, index: true
  end
end
