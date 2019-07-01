class RenameMasterUserIdToUserIdInUserAuthentications < ActiveRecord::Migration[5.1]
  def change
    rename_column :user_authentications, :master_user_id, :user_id
  end
end
