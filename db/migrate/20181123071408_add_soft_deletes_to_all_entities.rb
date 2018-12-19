class AddSoftDeletesToAllEntities < ActiveRecord::Migration[5.1]
  def change
    add_column :patients, :deleted_at, :datetime
    add_index :patients, :deleted_at

    add_column :addresses, :deleted_at, :datetime
    add_index :addresses, :deleted_at

    add_column :patient_phone_numbers, :deleted_at, :datetime
    add_index :patient_phone_numbers, :deleted_at

    add_column :blood_pressures, :deleted_at, :datetime
    add_index :blood_pressures, :deleted_at

    add_column :prescription_drugs, :deleted_at, :datetime
    add_index :prescription_drugs, :deleted_at

    add_column :appointments, :deleted_at, :datetime
    add_index :appointments, :deleted_at

    add_column :communications, :deleted_at, :datetime
    add_index :communications, :deleted_at

    add_column :medical_histories, :deleted_at, :datetime
    add_index :medical_histories, :deleted_at

    add_column :users, :deleted_at, :datetime
    add_index :users, :deleted_at

    add_column :facilities, :deleted_at, :datetime
    add_index :facilities, :deleted_at

    add_column :protocols, :deleted_at, :datetime
    add_index :protocols, :deleted_at

    add_column :protocol_drugs, :deleted_at, :datetime
    add_index :protocol_drugs, :deleted_at

    add_column :admins, :deleted_at, :datetime
    add_index :admins, :deleted_at

  end
end
