class AddIndexToAccessResources < ActiveRecord::Migration[5.2]
  def change
    add_index :accesses, :resource_id
  end
end
