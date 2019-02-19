class NewlyEnrolledPatientsQuery
  attr_reader :facilities, :from_time, :to_time

  def initialize(facilities:, from_time:, to_time:)
    @facilities = facilities
    @from_time = from_time
    @to_time = to_time
  end

  def call
    Patient.where(registration_facility: facilities)
      .where(device_created_at: from_time..to_time)
      .distinct
  end
end