class Encounter < ApplicationRecord
  belongs_to :patient
  belongs_to :facility

  has_many :encounter_events
  has_many :blood_pressures, through: :encounter_events, source: :encountered, source_type: 'BloodPressure'
  has_many :prescription_drugs, through: :encounter_events, source: :encountered, source_type: 'PrescriptionDrug'

  def events
    encounter_events.includes(:encountered).map(&:encountered)
  end

  def self.create_encounter(params)
    create!(facility_id: params['facility_id'],
            patient_id: params['patient_id'],
            encountered_on: encountered_on(params['timezone'], params['timezone_offset']))
      .encounter_events
      .create!(user: params['user'],
               encountered: params['encountered'])
  end

  def encountered_on(_a, _b)
    Date.today
  end
end
