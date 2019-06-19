require 'roo'

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
    facility.validate :unique_facility_group_and_organization
  end

  delegate :protocol, to: :facility_group, allow_nil: true
  delegate :organization, to: :facility_group, allow_nil: true

  friendly_id :name, use: :slugged

  def report_on_patients
    registered_patients
  end


  def self.parse_import(file_contents)
    facilities = []
    CSV.parse(file_contents, headers: true, converters: :strip_whitespace) do |row|
      facility = {organization_name: row['organization'],
                  facility_group_name: row['facility_group'],
                  name: row['facility_name'],
                  facility_type: row['facility_type'],
                  street_address: row['street_address'],
                  village_or_colony: row['village_or_colony'],
                  district: row['district'],
                  state: row['state'],
                  country: row['country'],
                  pin: row['pin'],
                  latitude: row['latitude'],
                  longitude: row['longitude'],
                  import: true}
      facilities << facility
    end
    facilities
  end

  def self.read_import_file(file)
    file_contents = ''
    if file.content_type == 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      xlsx = Roo::Spreadsheet.open(file.path)
      file_contents = xlsx.to_csv
    end
    file_contents = file.read if file.content_type == 'text/csv'
    file_contents
  end

  def is_import?
    import
  end

  def unique_facility_group_and_organization
    organization = Organization.find_by(name: organization_name)
    unless organization.present?
      errors.add(:organization, "doesn't exist")
      return nil
    end
    facility_group = FacilityGroup.find_by(name: facility_group_name,
                                             organization_id: organization.id)
    unless facility_group.present?
      errors.add(:facility_group, "for organization doesn't exist")
      return nil
    end
    facility = Facility.find_by(name: name, facility_group: facility_group.id)
    errors.add(:facility, "already exists") if facility.present?
  end

  CSV::Converters[:strip_whitespace] = ->(value) { value.strip rescue value }
end
