class CreateDownloadApiTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :download_api_tokens do |t|
      t.string :name
      t.string :access_token
      t.boolean :enabled, default: true
      t.references :facility, type: :uuid, foreign_key: true

      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
