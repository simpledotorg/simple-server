require 'rails_helper'

RSpec.describe MyFacilitiesQuery do
  context 'utility methods' do
    let!(:active_facility) { create(:facility) }
    let!(:inactive_facility) { create (:facility) }
    let!(:blood_pressures_for_active_facility) { create_list(:blood_pressure, 10, facility: active_facility, recorded_at: Time.now) }
    let!(:blood_pressures_for_inactive_facility) { create_list(:blood_pressure, 9, facility: inactive_facility, recorded_at: Time.now) }
    let!(:encounters) do
      (blood_pressures_for_active_facility + blood_pressures_for_inactive_facility).each { |record|
        create(:encounter, :with_observables, patient: record.patient, observable: record, facility: record.facility) }
    end

    describe ".active_facilities" do
      it 'should only return active facilities' do
        expect(MyFacilitiesQuery.new(Facility.all).active_facilities).to match_array(active_facility)
      end
    end
  end
end