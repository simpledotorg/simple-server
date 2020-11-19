class Block
  attr_reader :name, :facilities
  def initialize(name:, facilities:)
    @name = name
    @facilities = facilities
  end

  def assigned_patients
    Patient.where(assigned_facility: facilities)
  end
end