class ChangeDrRaiTargetsPeriodToString < ActiveRecord::Migration[6.1]
  def up
    rename_column :dr_rai_targets, :period, :old_period
    add_column :dr_rai_targets, :period, :string

    DrRai::Target.reset_column_information
    DrRai::Target.find_each do |t|
      t.update_column(:period, t.old_period["name"]) if t.old_period.is_a?(Hash)
    end

    remove_column :dr_rai_targets, :old_period
  end

  def down
    add_column :dr_rai_targets, :period_json, :jsonb

    DrRai::Target.reset_column_information
    DrRai::Target.find_each do |t|
      t.update_column(:period_json, Period.new(type: :quarter, value: t.period)) if t.period
    end

    remove_column :dr_rai_targets, :period
    rename_column :dr_rai_targets, :period_json, :period
  end
end
