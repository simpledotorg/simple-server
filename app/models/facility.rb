class Facility < ApplicationRecord
  include Mergeable
  include QuarterHelper
  extend FriendlyId

  belongs_to :facility_group, optional: true

  has_many :users, foreign_key: 'registration_facility_id'
  has_many :blood_pressures
  has_many :patients, -> { distinct }, through: :blood_pressures
  has_many :prescription_drugs

  has_many :registered_patients, class_name: "Patient", foreign_key: "registration_facility_id"

  has_many :appointments

  validates :name, presence: true
  validates :district, presence: true
  validates :state, presence: true
  validates :country, presence: true
  validates :pin, numericality: true, allow_blank: true

  delegate :protocol, to: :facility_group, allow_nil: true
  delegate :organization, to: :facility_group, allow_nil: true

  friendly_id :name, use: :slugged

  def cohort_analytics
    query = CohortAnalyticsQuery.new(self.patients)
    results = {}

    (0..2).each do |quarters_back|
      date = (Date.today - (quarters_back * 3).months).beginning_of_quarter
      results[date] = query.patient_counts(year: date.year, quarter: quarter(date))
    end

    results
  end

  def dashboard_analytics
    query = FacilityAnalyticsQuery.new(self)

    [query.follow_up_patients_by_month,
     query.registered_patients_by_month,
     query.total_registered_patients].compact.inject(&:deep_merge)
  end
end
