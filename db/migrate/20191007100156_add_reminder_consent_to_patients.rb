class AddReminderConsentToPatients < ActiveRecord::Migration[5.1]
  def change
    add_column :patients, :reminder_consent, :string, index: true, null: false, default: Patient.reminder_consents[:denied]
  end
end
