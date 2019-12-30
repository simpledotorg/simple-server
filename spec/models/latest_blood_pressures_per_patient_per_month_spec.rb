require 'rails_helper'

RSpec.describe LatestBloodPressuresPerPatientPerMonth, type: :model do
  Timecop.travel('1 Oct 2019') do
    let!(:facilities) { create_list(:facility, 2) }
    let!(:months) do
      [1, 2, 3].map { |n| n.months.ago }
    end
    let!(:patients) { create_list(:patient, 2) }

    let!(:blood_pressures) do
      facilities.map do |facility|
        months.map do |month|
          patients.map do |patient|
            create_list(:blood_pressure, 2, facility: facility, recorded_at: month, patient: patient)
          end
        end
      end.flatten
    end

    let!(:query_results) do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatientPerMonth.all
    end
  end

  it 'should return a row per patient per month' do
    expect(query_results.count).to eq(6)
  end
  it 'should return at least one row per patient' do
    expect(query_results.pluck(:patient_id).uniq).to match_array(patients.map(&:id))
  end
end

