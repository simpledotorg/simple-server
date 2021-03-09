class AddLtreeExtension < ActiveRecord::Migration[5.2]
  def change
    enable_extension "ltree"
  end
end
