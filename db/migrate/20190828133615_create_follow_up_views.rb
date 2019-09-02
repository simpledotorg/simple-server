class CreateFollowUpViews < ActiveRecord::Migration[5.1]
  def change
    create_view :follow_up_views
  end
end
