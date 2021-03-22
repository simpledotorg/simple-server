class CreateExperimentCommunication < ActiveRecord::Migration[5.2]
  def change
    create_table :experiment_communications do |t|
      t.integer :bucket_identifier, null: false
      t.string :mode, null: false
      t.string :message, null: true
      t.integer :appointment_offset, null: false
      t.references :experiment, null: false, foreign_key: true
      t.timestamps
    end
  end
end
