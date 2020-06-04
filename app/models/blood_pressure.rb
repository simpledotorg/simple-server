class BloodPressure < ApplicationRecord
  include Mergeable
  include Hashable
  include Observeable
  include SQLHelpers

  ANONYMIZED_DATA_FIELDS = %w[id patient_id created_at bp_date registration_facility_name user_id
    bp_systolic bp_diastolic]

  THRESHOLDS = {
    critical: {systolic: 180, diastolic: 110},
    hypertensive: {systolic: 140, diastolic: 90}
  }.freeze

  belongs_to :patient, optional: true
  belongs_to :user, optional: true
  belongs_to :facility, optional: true

  has_one :observation, as: :observable
  has_one :encounter, through: :observation

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  scope :hypertensive, -> {
    where(arel_table[:systolic].gteq(THRESHOLDS[:hypertensive][:systolic]))
      .or(where(arel_table[:diastolic].gteq(THRESHOLDS[:hypertensive][:diastolic])))
  }

  scope :under_control, -> {
    where(arel_table[:systolic].lt(THRESHOLDS[:hypertensive][:systolic]))
      .where(arel_table[:diastolic].lt(THRESHOLDS[:hypertensive][:diastolic]))
  }

  def self.recent_in_month(time, patients: nil)
    query = select("DISTINCT ON (patient_id) *")
      .order(:patient_id, "recorded_at desc")
      .where("recorded_at >= ? AND recorded_at <= ?", time.beginning_of_month, time.end_of_month)
    query.where(patient: patients) if patients
    query
  end

  def critical?
    systolic >= THRESHOLDS[:critical][:systolic] || diastolic >= THRESHOLDS[:critical][:diastolic]
  end

  def hypertensive?
    systolic >= THRESHOLDS[:hypertensive][:systolic] || diastolic >= THRESHOLDS[:hypertensive][:diastolic]
  end

  def under_control?
    !hypertensive?
  end

  def recorded_days_ago
    (Date.current - device_created_at.to_date).to_i
  end

  def to_s
    [systolic, diastolic].join("/")
  end

  def quarter_for_month(month)
    case month
    when 1, 2, 3
      1
    when 4, 5, 6
      2
    when 7, 8, 9
      3
    when 10, 11, 12
      4
    else
      raise ArgumentError
    end
  end

  def create_or_update_rollup
    month = recorded_at.month
    quarter = quarter_for_month(month)
    month_attrs = rollup_attributes(period_type: :month, period_number: month)
    quarter_attrs = rollup_attributes(period_type: :quarter, period_number: quarter)

    rollups = BloodPressureRollup.arel_table
    month_conditions = rollups[:recorded_at].lt(recorded_at).and(rollups[:period_type].eq(0)).and(rollups[:period_number].eq(month))
    month_rollup  = BloodPressureRollup.upsert(month_attrs, arel_condition: month_conditions)
    logger.info "result for month upsert #{month_rollup.attributes}"
    quarter_conditions = rollups[:recorded_at].lt(recorded_at).and(rollups[:period_type].eq(1)).and(rollups[:period_number].eq(quarter))
    quarter_rollup = BloodPressureRollup.upsert(quarter_attrs, arel_condition: quarter_conditions)
    logger.info "result for quarter upsert #{quarter_rollup.attributes}"
  end

  def rollup_attributes(period_type:, period_number:)
    attrs = {
      assigned_facility_id: patient.registration_facility_id,
      blood_pressure_facility_id: facility_id,
      blood_pressure_id: id,
      diastolic: diastolic,
      patient_id: patient_id,
      recorded_at: recorded_at,
      systolic: systolic,
      year: recorded_at.year
    }
    attrs.merge(period_type: period_type, period_number: period_number)
  end

  def anonymized_data
    {id: hash_uuid(id),
     patient_id: hash_uuid(patient_id),
     created_at: created_at,
     bp_date: recorded_at,
     registration_facility_name: facility.name,
     user_id: hash_uuid(user_id),
     bp_systolic: systolic,
     bp_diastolic: diastolic}
  end
end
