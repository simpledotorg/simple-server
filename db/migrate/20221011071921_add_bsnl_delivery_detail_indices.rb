class AddBsnlDeliveryDetailIndices < ActiveRecord::Migration[6.1]
  def change
    add_index :bsnl_delivery_details, :message_id, unique: true, name: :index_bsnl_delivery_details_message_id
    add_index :bsnl_delivery_details, :deleted_at, unique: true, name: :index_bsnl_delivery_details_deleted_at
  end
end
