class DropFollowUpViews < ActiveRecord::Migration[5.2]
  def change
    drop_view :follow_up_views
  end
end
