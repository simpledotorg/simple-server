class CreateFollowUpSchedulesAndFollowUps < ActiveRecord::Migration[5.1]
  def change
    create_table :follow_up_schedules, id: :uuid do |t|
      t.belongs_to :patient, index: true, type: :uuid, null: false
      t.belongs_to :facility, index: true, type: :uuid, null: false
      t.date :next_visit, null: false
      t.uuid :action_by_user_id, index:true
      t.string :user_action
      t.string :reason_for_action
      t.datetime :device_created_at, null: false
      t.datetime :device_updated_at, null: false
      t.timestamps
    end
    add_foreign_key :follow_up_schedules, :facilities
    add_foreign_key :follow_up_schedules, :users, column: :action_by_user_id

    create_table :follow_ups, id: :uuid do |t|
      t.belongs_to :follow_up_schedule, index: true, type: :uuid, null: false
      t.belongs_to :user, index: true, type: :uuid, null: false
      t.string :follow_up_type
      t.string :follow_up_result
      t.datetime :device_created_at, null: false
      t.datetime :device_updated_at, null: false
      t.timestamps
    end
    add_foreign_key :follow_ups, :users
  end
end
