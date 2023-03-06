require "rails_helper"

describe PatientStates::CumulativeRegistrationsQuery do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  let(:regions) { setup_district_with_facilities }
  let(:period) { Period.current }

  context 'cumulative registrations' do
    it 'returns the cumulative registrations in a facility as of the given period' do
      facility_1_new_registrations = create_list(:patient, 2, assigned_facility: regions[:facility_1])
      facility_1_old_registration = create(:patient, assigned_facility: regions[:facility_1], device_created_at: 2.months.ago)
      facility_2_new_registrations = create_list(:patient, 2, assigned_facility: regions[:facility_2])
      refresh_views

      expect(PatientStates::CumulativeAssignedPatientsQuery.new(regions[:facility_1].region, period)
                                                           .call.map(&:patient_id))
        .to match_array((facility_1_new_registrations + [facility_1_old_registration]).map(&:id))

      expect(PatientStates::CumulativeAssignedPatientsQuery.new(regions[:facility_2].region, period)
                                                           .call.map(&:patient_id))
        .to match_array(facility_2_new_registrations.map(&:id))

      expect(PatientStates::CumulativeAssignedPatientsQuery.new(regions[:region].region, period)
                                                           .call.map(&:patient_id))
        .to match_array((facility_1_new_registrations + [facility_1_old_registration] + facility_2_new_registrations).map(&:id))
          end

    it 'returns the same number of cumulative registrations as in reporting facility states' do
      refresh_views

      _facility_1_new_registrations = create_list(:patient, 2, assigned_facility: regions[:facility_1])
      _facility_2_new_registrations = create_list(:patient, 3, assigned_facility: regions[:facility_2])
      _facility_2_old_registration = create(:patient, assigned_facility: regions[:facility_2], device_created_at: 2.months.ago)

      refresh_views

      expect(PatientStates::CumulativeRegistrationsQuery.new(regions[:facility_1].region, period).call.count)
        .to eq(Reports::FacilityState
                 .find_by(facility_id: regions[:facility_1].id, month_date: period.begin)
                 .cumulative_registrations)

      expect(PatientStates::CumulativeRegistrationsQuery.new(regions[:facility_2].region, period).call.count)
        .to eq(Reports::FacilityState
                 .find_by(facility_id: regions[:facility_2].id, month_date: period.begin)
                 .cumulative_registrations)
    end
  end
end
