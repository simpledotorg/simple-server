class AddLoggedInAtColumnToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :logged_in_at, :datetime
  end
end
