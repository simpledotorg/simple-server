class AddZoneToAddresses < ActiveRecord::Migration[5.1]
  def change
    add_column :addresses, :zone, :string, index: true, null: true
  end
end
