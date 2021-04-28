class CreatePatientImportLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :patient_import_logs, id: :uuid do |t|
      t.belongs_to :user, null: false, type: :uuid

      t.uuid :record_id
      t.string :record_type

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
