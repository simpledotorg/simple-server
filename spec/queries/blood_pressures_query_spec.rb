require 'rails_helper'

RSpec.describe BloodPressuresQuery, type: :query do
  let(:facility_1) { create :facility }
  let(:facility_2) { create :facility }

  let!(:blood_pressures_for_facility_1) { create_list :blood_pressure, 5, facility: facility_1}
  let!(:blood_pressures_for_facility_2) { create_list :blood_pressure, 5, facility: facility_2}

  describe 'for_facilities' do
    it 'returns bloods pressures recorded for a single' do
      blood_pressures = BloodPressuresQuery.new.for_facilities(facility_1)

      expect(blood_pressures).to eq(blood_pressures_for_facility_1)
    end

    it 'returns bloods pressures recorded for a list of facilities' do
      blood_pressures = BloodPressuresQuery.new.for_facilities(Facility.all)

      expect(blood_pressures).to eq(blood_pressures_for_facility_1 + blood_pressures_for_facility_2)
    end
  end

  describe 'for_facility_group' do
    it 'returns blood_pressures records in all facilities of a facility_group' do
      blood_pressures = BloodPressuresQuery.new.for_facility_group(facility_1.facility_group)

      expect(blood_pressures).to eq(blood_pressures_for_facility_1)
    end
  end

end