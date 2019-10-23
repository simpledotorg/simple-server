class RemoveForiegnKeyReferenceFromEncountersToPatients < ActiveRecord::Migration[5.1]
  def change
    if foreign_key_exists?(:encounters, :patients)
      remove_foreign_key :encounters, :patients
    end
  end
end
