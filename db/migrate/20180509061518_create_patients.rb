class CreatePatients < ActiveRecord::Migration[5.1]
  def change
    create_table :patients, id: false do |t|
      t.uuid :id, primary_key: true
      t.string :full_name
      t.integer :age_when_created
      t.integer :gender
      t.timestamps
    end
  end
end
