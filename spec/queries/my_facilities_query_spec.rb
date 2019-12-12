require 'rails_helper'

RSpec.describe MyFacilitiesQuery do
  context 'utility methods' do
    let!(:active_facility) { create(:facility) }
    let!(:inactive_facilty) { create (:facility) }
    let!(:blood_pressures_for_active_facilities) { create_list(:blood_pressure, 10, facility: active_facility, recorded_at: Time.now) }
    let!(:blood_pressures_for_inactive_facilities) { create_list(:blood_pressure, 9, facility: active_facility, recorded_at: Time.now) }

    describe ".active_facilities" do
      it 'should only return active facilities' do
        expect(MyFacilitiesQuery.new(Facility.all).active_facilities).to match_array(active_facility)
      end
    end
  end
end