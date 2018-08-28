class CreateAppointmentsAndCommunications < ActiveRecord::Migration[5.1]
  def change
    create_table :appointments, id: :uuid do |t|
      t.belongs_to :patient, index: true, type: :uuid, null: false
      t.belongs_to :facility, index: true, type: :uuid, null: false
      t.date :date, null: false
      t.string :status
      t.string :status_reason
      t.datetime :device_created_at, null: false
      t.datetime :device_updated_at, null: false
      t.timestamps
    end
    add_foreign_key :appointments, :facilities

    create_table :communications, id: :uuid do |t|
      t.belongs_to :appointment, index: true, type: :uuid, null: false
      t.belongs_to :user, index: true, type: :uuid, null: false
      t.string :communication_type
      t.string :communication_result
      t.datetime :device_created_at, null: false
      t.datetime :device_updated_at, null: false
      t.timestamps
    end
    add_foreign_key :communications, :users
  end
end
