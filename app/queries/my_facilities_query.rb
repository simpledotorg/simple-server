class MyFacilitiesQuery < Struct.new(:facilities)

  def active_facilities
    facility_ids = facilities.left_outer_joins(:blood_pressures)
                     .group('facilities.id')
                     .where('blood_pressures.recorded_at > ?', 1.week.ago)
                     .count(:blood_pressures)
                     .select { |_, count| count >= 10}
                     .keys

    facilities.where(id: facility_ids)
  end
end