class DropBpDrugsViews < ActiveRecord::Migration[5.2]
  def change
    drop_view :bp_drugs_views
  end
end
