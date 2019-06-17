class Facility < ApplicationRecord
  include Mergeable
  include PatientSetAnalyticsReportable
  extend FriendlyId

  attribute :import, :boolean, default: false
  attribute :organization_name, :string
  attribute :facility_group_name, :string

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

  with_options if: :is_import? do |facility|
    facility.validates :organization_name, presence: true
    facility.validates :facility_group_name, presence: true
    facility.validate :facility_group_and_organization_unique_exist
  end

  delegate :protocol, to: :facility_group, allow_nil: true
  delegate :organization, to: :facility_group, allow_nil: true

  friendly_id :name, use: :slugged

  def report_on_patients
    registered_patients
  end

  def is_import?
    import
  end

  def facility_group_and_organization_unique_exist
    organization = Organization.find_by(name: organization_name)
    if organization.blank?
      errors.add(:organization, "doesn't exist")
    else
      facility_group = FacilityGroup.find_by(name: facility_group_name,
                                             organization_id: organization.id)
      if facility_group.blank?
        errors.add(:facility_group, "for organization doesn't exist")
      else
        facility = Facility.find_by(name: name, facility_group: facility_group.id)
        errors.add(:facility, "already exists") if facility.present?
      end
    end
  end
end
