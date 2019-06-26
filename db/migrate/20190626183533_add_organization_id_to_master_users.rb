class AddOrganizationIdToMasterUsers < ActiveRecord::Migration[5.1]
  def change
    add_reference :master_users, :organizations, type: :uuid, null: true
  end
end
