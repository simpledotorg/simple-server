module MyFacilitiesQuery
  def self.inactive_facilities(facilities = Facility.all)
    facility_ids = facilities.left_outer_joins(:blood_pressures)
                       .where('blood_pressures.recorded_at IS NULL OR blood_pressures.recorded_at > ?', 1.week.ago)
                       .group('facilities.id')
                       .count(:blood_pressures)
                       .select { |_, count| count < 10 }
                       .keys

    facilities.where(id: facility_ids)
  end
end