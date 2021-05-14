class DropBpViews < ActiveRecord::Migration[5.2]
  def change
    drop_view :bp_views
  end
end
