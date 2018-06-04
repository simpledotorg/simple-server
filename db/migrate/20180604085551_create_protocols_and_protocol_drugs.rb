class CreateProtocolsAndProtocolDrugs < ActiveRecord::Migration[5.1]
  def change
    create_table :protocols, id: false do |t|
      t.uuid :id, primary_key: true
      t.string :name, null: false
      t.integer :follow_up_days
    end

    create_table :protocol_drugs, id: false do |t|
      t.uuid :id, primary_key: true
      t.string :name, null: false
      t.string :dosage, null: false
      t.string :rxnorm_code
      t.uuid :protocol_id
    end

    add_foreign_key :protocol_drugs, :protocols
  end
end