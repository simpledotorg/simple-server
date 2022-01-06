# frozen_string_literal: true

class Csv::FacilitiesValidator
  def self.validate(facilities)
    new(facilities).validate
  end

  attr_reader :errors

  def initialize(facilities)
    @facilities = facilities
    @errors = []
  end

  def validate
    at_least_one_facility
    duplicate_rows
    per_facility_validations
    self
  end

  private

  STARTING_ROW = 2

  attr_reader :facilities
  attr_writer :errors

  def at_least_one_facility
    errors << "Uploaded file doesn't contain any valid facilities" if facilities.blank?
  end

  def duplicate_rows
    fields = facilities
      .map do |facility|
        {name: facility[:name]&.gsub(/\s+/, ""),
         organization_name: facility[:organization_name],
         facility_group_name: facility[:facility_group_name]}
      end

    errors << "Uploaded file has duplicate facilities" if fields.count != fields.uniq.count
  end

  def per_facility_validations
    row_errors = []

    facilities.each.with_index(STARTING_ROW) do |facility, row_num|
      row_validator = FacilityValidator.new(facility)

      # skip populating errors if both csv-specific validations and model validations succeed
      next if [row_validator.valid?, facility.valid?].all?

      row_errors << [row_num, row_validator.errors.full_messages.to_sentence] if row_validator.errors.present?
      row_errors << [row_num, facility.errors.full_messages.to_sentence] if facility.errors.present?
    end

    group_row_errors(row_errors).each { |error| errors << error } if row_errors.present?
  end

  def group_row_errors(row_errors)
    unique_errors = row_errors.map { |_row, message| message }.uniq
    unique_errors.map do |error|
      rows = row_errors
        .select { |row, message| row if error == message }
        .map { |row, _message| row }

      "Row(s) #{rows.join(", ")}: #{error}"
    end
  end

  class FacilityValidator
    include ActiveModel::Validations
    include Memery

    validates :name, presence: true
    validates :organization_name, presence: true
    validates :facility_group_name, presence: true
    validate :facility_is_unique
    validate :organization_exists
    validate :facility_group_exists

    def initialize(facility)
      @facility = facility
    end

    private

    attr_reader :facility
    delegate :name, :organization_name, :facility_group_name, to: :facility

    def organization_exists
      if organization_name.present? && existing_organization.blank?
        errors.add(:organization, "doesn't exist")
      end
    end

    def facility_group_exists
      if existing_organization.present? && facility_group_name.present? && existing_facility_group.blank?
        errors.add(:facility_group, "doesn't exist for the organization")
      end
    end

    def facility_is_unique
      if existing_organization.present? && existing_facility_group.present? && existing_facility.present?
        errors.add(:facility, "already exists")
      end
    end

    memoize def existing_organization
      Organization.find_by(name: organization_name)
    end

    memoize def existing_facility_group
      FacilityGroup.find_by(name: facility_group_name, organization: existing_organization)
    end

    def existing_facility
      Facility.find_by(name: name, facility_group: existing_facility_group) if existing_facility_group.present?
    end
  end
end
