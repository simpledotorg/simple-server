class CreateBpViews < ActiveRecord::Migration[5.1]
  def change
    create_view :bp_views
  end
end
