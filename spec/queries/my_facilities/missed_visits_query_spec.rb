require 'rails_helper'

RSpec.describe MyFacilities::MissedVisitsQuery do
  include QuarterHelper

  context 'Month queries' do
    let!(:facilities) { create_list(:facility, 2) }
    let!(:months) do
      [2, 1, 0].map { |n| n.months.ago.beginning_of_month }
    end

    let!(:patients) do
      [create(:patient, registration_facility: facilities.first, recorded_at: 4.months.ago),
       create(:patient, registration_facility: facilities.second, recorded_at: 3.months.ago)]
    end

    let!(:patient_3) { create(:patient, registration_facility: facilities.first, recorded_at: 1.month.ago) }

    let!(:bp_1) { create(:blood_pressure, facility: facilities.first, patient: patients.first, recorded_at: months.first) }
    let!(:bp_2) { create(:blood_pressure, facility: facilities.second, patient: patients.first, recorded_at: months.first) }
    let!(:bp_3) { create(:blood_pressure, facility: facilities.second, patient: patients.first, recorded_at: months.second) }
    let!(:bp_4) { create(:blood_pressure, facility: facilities.first, patient: patients.second, recorded_at: months.first) }
    let!(:bp_5) { create(:blood_pressure, facility: facilities.second, patient: patients.second, recorded_at: months.second) }
    let!(:bp_6) { create(:blood_pressure, facility: facilities.first, patient: patient_3, recorded_at: months.first) }
    let!(:bp_7) { create(:blood_pressure, facility: facilities.second, patient: patients.first, recorded_at: months.third) }
    let!(:bp_8) { create(:blood_pressure, facility: facilities.first, patient: patients.second, recorded_at: months.third) }

    before do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatient.refresh
    end

    let!(:query) { described_class.new(period: :month) }

    context '#patients' do
      it "shouldn't have patient registered less than two months ago" do
        expect(query.patients.map(&:id).sort).to eq(patients.map(&:id).sort)
      end
    end

    context '#patients_by_period' do
      it 'should bucket patients by the period they registered in' do
        expect(query.patients_by_period[query.periods.first].map(&:id).sort).to eq(patients.map(&:id).sort)
        expect(query.patients_by_period[query.periods.second].map(&:id).sort).to eq([patients.first.id].sort)
        expect(query.patients_by_period[query.periods.third].map(&:id)).to eq([])
      end
    end

    context '#visits_by_period' do
      it "should bucket visits by the period they were recorded in" do
        pp query.visits_by_period
        expect(query.visits_by_period[query.periods.first].map(&:bp_id)).to eq([bp_7.id, bp_8.id].sort)
        expect(query.visits_by_period[query.periods.second].map(&:bp_id).sort).to eq([bp_3.id].sort)
        expect(query.visits_by_period[query.periods.third].map(&:bp_id)).to eq([])
      end
    end
  end


  context 'Quarter queries' do
    let!(:facilities) { create_list(:facility, 2) }
    let!(:quarters) do
      last_n_quarters(n: 3, inclusive: true).map { |year_quarter| local_quarter_start(*year_quarter) }.reverse
    end

    let!(:patients) do
      [create(:patient, registration_facility: facilities.first, recorded_at: quarters.first.beginning_of_quarter - 3.months),
       create(:patient, registration_facility: facilities.second, recorded_at: quarters.second.beginning_of_quarter - 1.months)]
    end

    let!(:patient_3) { create(:patient, registration_facility: facilities.first, recorded_at: 1.month.ago) }

    let!(:bp_1) { create(:blood_pressure, facility: facilities.first, patient: patients.first, recorded_at: quarters.first) }
    let!(:bp_2) { create(:blood_pressure, facility: facilities.second, patient: patients.first, recorded_at: quarters.first) }
    let!(:bp_3) { create(:blood_pressure, facility: facilities.second, patient: patients.first, recorded_at: quarters.second) }
    let!(:bp_4) { create(:blood_pressure, facility: facilities.first, patient: patients.second, recorded_at: quarters.first) }
    let!(:bp_5) { create(:blood_pressure, facility: facilities.second, patient: patients.second, recorded_at: quarters.second) }
    let!(:bp_6) { create(:blood_pressure, facility: facilities.first, patient: patient_3, recorded_at: quarters.first) }
    let!(:bp_7) { create(:blood_pressure, facility: facilities.second, patient: patients.first, recorded_at: quarters.third) }
    let!(:bp_8) { create(:blood_pressure, facility: facilities.first, patient: patients.second, recorded_at: quarters.third) }

    before do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatient.refresh
      LatestBloodPressuresPerPatientPerQuarter.refresh
    end

    let!(:query) { described_class.new(period: :quarter) }

    context '#patients' do
      it "shouldn't have patient registered less than two months ago" do
        expect(query.patients.map(&:id).sort).to eq(patients.map(&:id).sort)
      end
    end

    context '#patients_by_period' do
      it 'should bucket patients by the period they registered in' do
        expect(query.patients_by_period[query.periods.first].map(&:id).sort).to eq(patients.map(&:id).sort)
        expect(query.patients_by_period[query.periods.second].map(&:id).sort).to eq([patients.first.id])
        expect(query.patients_by_period[query.periods.third].map(&:id)).to eq([patients.first.id])
      end
    end

    context '#visits_by_period' do
      it "should bucket visits by the period they were recorded in" do
        expect(query.visits_by_period[query.periods.first].map(&:bp_id).sort).to eq([bp_7.id, bp_8.id].sort)
        expect(query.visits_by_period[query.periods.second].map(&:bp_id).sort).to eq([bp_3.id].sort)
        expect(query.visits_by_period[query.periods.third].map(&:bp_id)).to eq([bp_2.id])
      end
    end
  end
end
