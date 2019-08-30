class CreateOverdueViews < ActiveRecord::Migration[5.1]
  def change
    create_view :overdue_views
  end
end
