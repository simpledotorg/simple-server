class DropImoAuthorizations < ActiveRecord::Migration[5.2]
  def change
    drop_table :imo_authorizations, if_exists: true
  end
end
