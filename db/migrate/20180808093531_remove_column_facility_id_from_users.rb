class RemoveColumnFacilityIdFromUsers < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :facility_id
  end
end
