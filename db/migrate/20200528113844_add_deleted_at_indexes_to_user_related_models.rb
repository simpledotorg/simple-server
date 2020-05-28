class AddDeletedAtIndexesToUserRelatedModels < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :users, :deleted_at, algorithm: :concurrently
    add_index :phone_number_authentications, :deleted_at, algorithm: :concurrently
  end
end
