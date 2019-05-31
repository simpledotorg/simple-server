class AddOrganizationIdAndUserTypeToMasterUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :master_users, :organization_id, :uuid, null: true
    add_column :master_users, :user_type, :string
  end
end
