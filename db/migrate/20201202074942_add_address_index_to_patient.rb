class AddAddressIndexToPatient < ActiveRecord::Migration[5.2]
  def change
    add_index :patients, :address_id
  end
end
