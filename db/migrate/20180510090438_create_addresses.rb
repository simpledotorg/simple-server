class CreateAddresses < ActiveRecord::Migration[5.1]
  def change
    create_table :addresses, id: false do |t|
      t.uuid :id, primary_key: true
      t.string :street_address
      t.string :colony
      t.string :village
      t.string :district
      t.string :state
      t.string :country
      t.string :pin

      t.timestamps
    end

    change_table :patients do |t|
      t.uuid :address_id
    end

    add_foreign_key :patients, :addresses
  end
end
