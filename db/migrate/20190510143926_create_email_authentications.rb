class CreateEmailAuthentications < ActiveRecord::Migration[5.1]
  def change
    create_table :email_authentications, id: :uuid do |t|
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.inet :current_sign_in_ip
      t.inet :last_sign_in_ip

      ## Lockable
      t.integer :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      t.string :unlock_token # Only if unlock strategy is :email or :both
      t.datetime :locked_at

      t.string :invitation_token
      t.datetime :invitation_created_at
      t.datetime :invitation_sent_at
      t.datetime :invitation_accepted_at
      t.integer :invitation_limit
      t.uuid :invited_by_id
      t.string :invited_by_type
      t.integer :invitations_count, default: 0

      t.timestamps null: false
      t.timestamp :deleted_at # For discard
    end

    add_index :email_authentications, :email, unique: true
    add_index :email_authentications, :reset_password_token, unique: true
    add_index :email_authentications, :unlock_token, unique: true

    add_index :email_authentications, :invitations_count
    add_index :email_authentications, :invitation_token, unique: true # for invitable
    add_index :email_authentications, :invited_by_id
    add_index :email_authentications, [:invited_by_type, :invited_by_id], name: 'index_email_authentications_invited_by'

    add_index :email_authentications, :deleted_at
  end
end