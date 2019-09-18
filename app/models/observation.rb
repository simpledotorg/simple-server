class Observation < ApplicationRecord
  belongs_to :encounter, optional: true
  belongs_to :user, optional: true

  belongs_to :observable, polymorphic: true

  after_save :add_encounter

  def add_encounter
    if encounter.blank?
      encounter = create_encounter!(facility_id: observable.facility_id,
                                    patient_id: observable.patient_id,
                                    recorded_at: observable.device_created_at,
                                    device_created_at: observable.device_created_at,
                                    device_updated_at: observable.device_updated_at)
      encounter.save!
    end
  end
end