class CreateImoAuthorization < ActiveRecord::Migration[5.2]
  def change
    create_table :imo_authorizations do |t|
      t.references :patient, type: :uuid, null: false
      t.date :last_invitation_date, null: false
      t.string :status, null: false
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
