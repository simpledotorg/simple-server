require 'rails_helper'

RSpec.describe VisitedPatientsWithControlledBpQuarterly, type: :model do
  Timecop.travel('1 Oct 2019') do
    let!(:one_quarter_ago) { 3.months.ago }
    let!(:two_quarters_ago) { 6.months.ago }
    let!(:three_quarters_ago) { 9.months.ago }
    let!(:four_quarters_ago) { 12.months.ago }
    let!(:facility_1) { create(:facility) }
    let!(:facility_2) { create(:facility) }

    let!(:facilities) { [facility_1, facility_2] }
    let!(:quarters) { [one_quarter_ago, two_quarters_ago, three_quarters_ago, four_quarters_ago] }

    let!(:patients) do
      facilities.map do |facility|
        quarters.map do |quarter|
          create(:patient, registration_facility: facility, recorded_at: quarter)
        end
      end.flatten
    end

    let!(:blood_pressures) do
      patients.map do |patient|
        create(:blood_pressure, patient: patient, facility: patient.registration_facility, recorded_at: (patient.recorded_at + 3.months), systolic: 120, diastolic: 70)
      end
    end
    let!(:encounters) do
      blood_pressures.each {|record| create(:encounter, :with_observables, patient: record.patient, observable: record, facility: record.facility)}
    end
    let!(:query_results) { VisitedPatientsWithControlledBpQuarterly.all }
  end

  it 'should return a row per facility per quarter' do
    # puts facilities
    # puts quarters
    # puts patients
    # puts blood_pressures
    # puts encounters.count
    expect(query_results.count).to eq(8)
  end
  it 'should return at least one row per facility' do
    expect { query_results.pluck(:facility_id).uniq }.to match_array(facilities.map(&:id))
  end
  it 'should return 1 blood_pressure per facility per quarter' do
    expect { query_results.pluck(:count).uniq }.to eq([1])
  end

end
