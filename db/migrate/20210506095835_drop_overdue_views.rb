class DropOverdueViews < ActiveRecord::Migration[5.2]
  def change
    drop_view :overdue_views
  end
end
