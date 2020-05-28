class AddSearchIndexToFacility < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    execute "CREATE INDEX CONCURRENTLY index_gin_facilities_on_name ON facilities USING GIN ((to_tsvector('simple'::regconfig, COALESCE((name)::text, ''::text))));"
    execute "CREATE INDEX CONCURRENTLY index_gin_facilities_on_slug ON facilities USING GIN ((to_tsvector('simple'::regconfig, COALESCE((slug)::text, ''::text))));"
  end

  def down
    remove_index :facilities, name: "index_gin_facilities_on_slug"
    remove_index :facilities, name: "index_gin_facilities_on_name"
  end
end
