class AddUniqunessConstraintForCommunicationAndDetailable < ActiveRecord::Migration[5.1]
  def change
    add_index :communications,
              [:id, :detailable_id, :detailable_type],
              unique: true,
              name: 'unique_index_communications_on_detailable'
  end
end
