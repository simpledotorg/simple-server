class Encounter < ApplicationRecord
  include Mergeable

  belongs_to :patient
  belongs_to :facility

  has_many :observations
  has_many :blood_pressures, through: :observations, source: :observable, source_type: 'BloodPressure'

  def self.generate_id(facility_id, patient_id, recorded_at, timezone_offset)
    id_params = [
      facility_id,
      patient_id,
      generate_encountered_on(recorded_at, timezone_offset)
    ].join("")

    UUIDTools::UUID.sha1_create(UUIDTools::UUID_DNS_NAMESPACE, id_params).to_s
  end

  def self.generate_encountered_on(time, timezone_offset)
    time
      .to_time
      .utc
      .advance(seconds: timezone_offset)
      .to_date
  end
end
