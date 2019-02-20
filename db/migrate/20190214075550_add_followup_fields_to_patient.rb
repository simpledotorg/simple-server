class AddFollowupFieldsToPatient < ActiveRecord::Migration[5.1]
  def change
    add_column :patients, :contacted_by_counsellor, :boolean, default: false
    add_column :patients, :could_not_contact_reason, :string, null: true
  end
end
