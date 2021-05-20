class CreateNotificationsForCommunications < ActiveRecord::Migration[5.2]
  def up
    BackfillNotifications.call
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
