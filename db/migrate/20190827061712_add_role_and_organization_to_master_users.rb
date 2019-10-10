class AddRoleAndOrganizationToMasterUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :master_users, :role, :string
    add_reference :master_users, :organization, type: :uuid, null: true
  end
end
