class CreateMasterUserAuthentications < ActiveRecord::Migration[5.1]
  def change
    create_table :master_user_authentications, id: :uuid do |t|
      t.belongs_to :master_user

      t.string :authenticatable_type
      t.uuid :authenticatable_id

      t.timestamps


      # This is for discard gem
      t.datetime :deleted_at, null: true
    end

    add_index :master_user_authentications,
              [:master_user_id, :authenticatable_type, :authenticatable_id],
              unique: true,
              name: 'master_users_authenticatable_uniq_index'
  end
end
