class Encounter < ApplicationRecord
  include Mergeable

  belongs_to :patient
  belongs_to :facility

  has_many :observations
  has_many :blood_pressures, through: :observations, source: :observable, source_type: 'BloodPressure'

  def encountered_on
    device_updated_at
      .utc
      .advance(seconds: timezone_offset)
      .to_date
  end
end
