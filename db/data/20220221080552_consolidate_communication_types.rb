class ConsolidateCommunicationTypes < ActiveRecord::Migration[5.2]
  def up
    Communication.where(communication_type: :missed_visit_sms_reminder).update_all(communication_type: :sms)
    Communication.where(communication_type: :missed_visit_whatsapp_reminder).update_all(communication_type: :whatsapp)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
