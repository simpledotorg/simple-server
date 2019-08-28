class CreateBpDrugsViews < ActiveRecord::Migration[5.1]
  def change
    create_view :bp_drugs_views
  end
end
