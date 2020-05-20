class Admin::FacilityCSVValidator

  def self.validate(*args)
    new(*args).validate
  end

  def initialize(facilities)
    @facilities = facilities
    @errors = []
  end

  attr_reader :errors

  def validate
    at_least_one_facility
    duplicate_rows
    facilities
    self
  end

  def at_least_one_facility
    @errors << "Uploaded file doesn't contain any valid facilities" if @facilities.blank?
  end

  def duplicate_rows
    facilities_slice = @facilities.map { |facility| facility.slice(:organization_name, :facility_group_name, :name) }
    @errors << 'Uploaded file has duplicate facilities' if facilities_slice.count != facilities_slice.uniq.count
  end

  def facilities
    row_errors = []
    @facilities.each.with_index(2) do |facility, row_num|
      import_facility = Facility.new(facility)
      row_errors << [row_num, import_facility.errors.full_messages.to_sentence] if import_facility.invalid?
    end
    if row_errors.present?
      group_row_errors(row_errors).each { |error| @errors << error }
    end
  end

  private

  def group_row_errors(row_errors)
    unique_errors = row_errors.map { |row, message| message }.uniq
    unique_errors.map do |error|
      rows = row_errors.select { |row, message| row if error == message }.map { |row, message| row }
      "Row(s) #{rows.join(', ')}: #{error}"
    end
  end
end
