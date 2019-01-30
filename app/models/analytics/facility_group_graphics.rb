class Analytics::FacilityGroupGraphics
  attr_reader :facility_group

  def initialize(facility_group)
    @facility_group = facility_group
  end

  def newly_enrolled_patients
    @newly_enrolled_patients ||=
      NewlyEnrolledPatientsQuery.new(facility_group.facilities)
        .call
        .reduce(0) { |sum, hash| sum += hash.second }
  end

  def return_patients
    @return_patients ||=
      ReturningPatientsQuery.new(facility_group.facilities)
        .call
        .reduce(0) { |sum, hash| sum += hash.second }
  end

  def patients_who_missed_appointments
    
  end
end