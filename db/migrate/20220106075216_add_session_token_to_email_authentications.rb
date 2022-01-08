class AddSessionTokenToEmailAuthentications < ActiveRecord::Migration[5.2]
  def change
    add_column :email_authentications, :session_token, :string
  end
end
