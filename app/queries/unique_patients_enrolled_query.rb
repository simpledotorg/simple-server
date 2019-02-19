class UniquePatientsEnrolledQuery
  attr_reader :facilities

  def initialize(facilities:)
    @facilities = facilities
  end

  def call
    Patient.where(registration_facility: facilities).distinct
  end
end