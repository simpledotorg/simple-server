class ChangeImoAuthorizationIdTypeToUuid < ActiveRecord::Migration[5.2]
  def up
    add_column :imo_authorizations, :uuid, :uuid, default: "gen_random_uuid()", null: false

    change_table :imo_authorizations do |t|
      t.remove :id
      t.rename :uuid, :id
    end
    execute "ALTER TABLE imo_authorizations ADD PRIMARY KEY (id);"
  end
end
