class Encounter < ApplicationRecord
  belongs_to :patient
  belongs_to :facility

  has_many :encounter_events
  has_many :blood_pressures, through: :encounter_events, source: :encounterable, source_type: 'BloodPressure'

  def events
    encounter_events.includes(:encounterable).map(&:encounterable)
  end

  def self.create_encounter_with_events!(params)
    encounter_params = {
      patient: params[:patient],
      facility: params[:facility],
      timezone: params[:timezone],
      timezone_offset: params[:timezone_offset],
      device_created_at: params[:device_created_at],
      device_updated_at: params[:device_updated_at],
      recorded_at: params[:recorded_at],
      encountered_on: encountered_on(params[:device_created_at],
                                     params[:timezone_offset])
    }

    encounter_event_params =
      params[:encounterables].map do |encounter_event|
        {
          user: params[:user],
          encounterable: encounter_event
        }
      end

    create!(encounter_params).encounter_events.create!(encounter_event_params)
  end

  def self.encountered_on(time, timezone_offset)
    time
      .utc
      .advance(seconds: timezone_offset)
      .to_date
  end
end
