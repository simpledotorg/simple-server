class CreateUserAuthentications < ActiveRecord::Migration[5.1]
  def change
    create_table :user_authentications, id: :uuid do |t|
      t.belongs_to :master_user, type: :uuid
      t.string :authenticatable_type
      t.uuid :authenticatable_id

      t.timestamps
      t.datetime :deleted_at, null: true # This is for discard gem
    end

    add_index :user_authentications,
              [:master_user_id, :authenticatable_type, :authenticatable_id],
              unique: true,
              name: 'user_authentications_master_users_authenticatable_uniq_index'
  end
end
