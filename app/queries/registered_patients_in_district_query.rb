class RegisteredPatientsInDistrictQuery
  attr_reader :district_name

  def initialize(district_name:)
    @district_name = district_name
  end

  def call
    by_facility = Patient
                    .select('facilities.name AS facility_name',
                            'facilities.id AS facility_id',
                            'count(distinct(patients.id)) AS registered_patients')
                    .joins('INNER JOIN facilities ON facilities.id = patients.registration_facility_id')
                    .where('facilities.district = ?', district_name)
                    .group('facilities.name', 'facilities.id')
                    .order('facilities.name')

    { patients_by_facility: by_facility,
      total: by_facility.map(&:registered_patients).inject(:+) }
  end
end
