class MakeNotificationsPolymorphicToSubject < ActiveRecord::Migration[5.2]
  def change
    change_table :notifications do |t|
      t.remove :appointment_id
      t.references :subject, polymorphic: true, type: :uuid, null: true
    end
  end
end
