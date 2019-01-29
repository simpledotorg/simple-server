class AddSlugToOrganization < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :slug, :string
    add_index :organizations, :slug, unique: true
  end
end
