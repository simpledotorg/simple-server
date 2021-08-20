class FixEthiopiaBpDates < ActiveRecord::Migration[5.2]
  def up
    OneOff::FixKokaHcBps.call
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
