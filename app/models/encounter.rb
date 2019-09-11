class Encounter < ApplicationRecord
  belongs_to :patient
  belongs_to :facility

  has_many :encounter_events
  has_many :blood_pressures, through: :encounter_events, source: :encountered, source_type: 'BloodPressure'
  has_many :prescription_drugs, through: :encounter_events, source: :encountered, source_type: 'PrescriptionDrug'

  def events
    encounter_events.includes(:encountered).map(&:encountered)
  end
end
