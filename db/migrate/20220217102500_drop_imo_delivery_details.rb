class DropImoDeliveryDetails < ActiveRecord::Migration[5.2]
  def change
    drop_table :imo_delivery_details, if_exists: true
  end
end
