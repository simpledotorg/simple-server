class AddDeletedAtIndexesToUserRelatedModels < ActiveRecord::Migration[5.2]
  def change
    add_index :users, :deleted_at
    add_index :phone_number_authentications, :deleted_at
  end
end
