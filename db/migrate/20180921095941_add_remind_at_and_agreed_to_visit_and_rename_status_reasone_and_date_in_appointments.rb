class AddRemindAtAndAgreedToVisitAndRenameStatusReasoneAndDateInAppointments < ActiveRecord::Migration[5.1]
  def change
    change_table :appointments do |t|
      t.date :remind_on, null: true
      t.boolean :agreed_to_visit, null: true
      t.rename :status_reason, :cancel_reason
      t.rename :date, :scheduled_date
    end
  end
end
