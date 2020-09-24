class CreateTeleconsultations < ActiveRecord::Migration[5.2]
  def change
    create_table :teleconsultations, id: false do |t|
      t.uuid :id, primary_key: true
      t.belongs_to :patient, type: :uuid, null: false, foreign_key: true
      t.belongs_to :medical_officer, type: :uuid, null: false, foreign_key: {to_table: :users}
      t.belongs_to :requested_medical_officer, type: :uuid, foreign_key: {to_table: :users}
      t.belongs_to :requester, type: :uuid, foreign_key: {to_table: :users}
      t.belongs_to :facility, type: :uuid, foreign_key: true
      t.string :request_completed
      t.datetime :requested_at
      t.datetime :recorded_at
      t.string :teleconsultation_type
      t.string :patient_took_medicines
      t.string :patient_consented
      t.string :medical_officer_number
      t.datetime :deleted_at, null: true
      t.datetime :device_updated_at
      t.datetime :device_created_at
      t.timestamps
    end
  end
end
