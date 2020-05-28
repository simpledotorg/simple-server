class AddSearchIndicesToUsers < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    execute "CREATE INDEX CONCURRENTLY index_gin_users_on_full_name ON users USING GIN ((to_tsvector('simple'::regconfig, COALESCE((full_name)::text, ''::text))));"
    execute "CREATE INDEX CONCURRENTLY index_gin_phone_number_authentications_on_phone_number ON phone_number_authentications USING GIN ((to_tsvector('simple'::regconfig, COALESCE((phone_number)::text, ''::text))));"
    execute "CREATE INDEX CONCURRENTLY index_gin_email_authentications_on_email ON email_authentications USING GIN ((to_tsvector('simple'::regconfig, COALESCE((email)::text, ''::text))));"
  end

  def down
    remove_index :email_authentications, name: "index_gin_email_authentications_on_email"
    remove_index :phone_number_authentications, name: "index_gin_phone_number_authentications_on_phone_number"
    remove_index :users, name: "index_gin_users_on_full_name"
  end
end
