class CreateLegacyMobileDataDumps < ActiveRecord::Migration[6.1]
  def change
    create_table :legacy_mobile_data_dumps, id: :uuid do |t|
      t.jsonb :raw_payload, null: false
      t.datetime :dump_date, null: false
      t.references :user, type: :uuid, foreign_key: true, null: false
      t.string :mobile_version

      t.timestamps
    end

    add_index :legacy_mobile_data_dumps, :dump_date
  end
end