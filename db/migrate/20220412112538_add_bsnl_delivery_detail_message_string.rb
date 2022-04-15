class AddBsnlDeliveryDetailMessageString < ActiveRecord::Migration[5.2]
  def change
    add_column :bsnl_delivery_details, :message, :string
  end
end
