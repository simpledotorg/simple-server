class CreatePatients < ActiveRecord::Migration[5.1]
  def change
    create_table :patients, id: false do |t|
      t.uuid :id, primary_key: true
      t.string :full_name
      t.integer :age_when_created
      t.string :gender
      t.date :date_of_birth
      t.string :status
      t.timestamps
    end
  end
end
