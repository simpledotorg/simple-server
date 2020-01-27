# frozen_string_literal: true

class MyFacilities::RegistrationsQuery

  def initialize(facilities = Facility.all)
    @facilities = facilities
  end
end
