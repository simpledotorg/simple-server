class AddMissingIndexes < ActiveRecord::Migration[5.1]
  def change
    add_index(:appointments, :user_id) unless index_exists?(:appointments, :user_id)
    add_index(:medical_histories, :user_id) unless index_exists?(:medical_histories, :user_id)
    add_index(:prescription_drugs, :user_id) unless index_exists?(:prescription_drugs, :user_id)
    add_index(:facility_groups, :protocol_id) unless index_exists?(:facility_groups, :protocol_id)
    add_index(:patients, :reminder_consent) unless index_exists?(:patients, :reminder_consent)
    add_index(:addresses, :zone) unless index_exists?(:addresses, :zone)
  end
end
