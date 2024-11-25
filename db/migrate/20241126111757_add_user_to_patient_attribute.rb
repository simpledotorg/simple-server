class AddUserToPatientAttribute < ActiveRecord::Migration[6.1]
  def change
    add_reference :patient_attributes, :user, null: false, foreign_key: true, type: :uuid
  end
end
