class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :name
      t.string :phone_number
      t.string :security_pin_hash

      t.timestamps
    end

    add_reference :users, :facility, type: :uuid
    add_reference :blood_pressures, :user, type: :uuid
  end
end
