class CreateMobitelDeliveryDetails < ActiveRecord::Migration[6.1]
  def change
    create_table :mobitel_delivery_details do |t|
      t.string :recipient_number, null: false
      t.string :message
      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
