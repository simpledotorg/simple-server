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
      it "doesn't have patient registered less than two months ago" do
        expect(query.patients.map(&:id).sort).to eq(patients.map(&:id).sort)
      end
    end

    context '#patients_by_period' do
      it 'buckets patients by the period they registered in' do
        expect(query.patients_by_period[query.periods.first].map(&:id).sort).to eq(patients.map(&:id).sort)
        expect(query.patients_by_period[query.periods.second].map(&:id).sort).to eq([patients.first.id].sort)
        expect(query.patients_by_period[query.periods.third].map(&:id)).to eq([])
      end
    end

    context '#visits_by_period' do
      it 'buckets visits by the period they were recorded in' do
        expect(query.visits_by_period[query.periods.first].map(&:bp_id).sort).to eq([bp_7.id, bp_8.id].sort)
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
    let!(:bp_2) { create(:blood_pressure, facility: facilities.second, patient: patients.first, recorded_at: quarters.first + 1.day) }
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
      it "doesn't have patient registered less than two months ago" do
        expect(query.patients.map(&:id).sort).to eq(patients.map(&:id).sort)
      end
    end

    context '#patients_by_period' do
      it 'buckets patients by the period they registered in' do
        expect(query.patients_by_period[query.periods.first].map(&:id).sort).to eq(patients.map(&:id).sort)
        expect(query.patients_by_period[query.periods.second].map(&:id).sort).to eq([patients.first.id])
        expect(query.patients_by_period[query.periods.third].map(&:id)).to eq([patients.first.id])
      end
    end

    context '#visits_by_period' do
      it 'buckets visits by the period they were recorded in' do
        expect(query.visits_by_period[query.periods.first].map(&:bp_id).sort).to eq([bp_7.id, bp_8.id].sort)
        expect(query.visits_by_period[query.periods.second].map(&:bp_id).sort).to eq([bp_3.id].sort)
        expect(query.visits_by_period[query.periods.third].map(&:bp_id)).to eq([bp_2.id])
      end
    end
  end

  context '#missed_visits_by_facility quarter' do
    let!(:facilities) { create_list(:facility, 3) }
    let!(:quarters) do
      last_n_quarters(n: 3, inclusive: true).map { |year_quarter| local_quarter_start(*year_quarter) }.reverse
    end

    let!(:patients) do
      [create(:patient, registration_facility: facilities.first, recorded_at: quarters.first.beginning_of_quarter),
       create(:patient, registration_facility: facilities.second, recorded_at: quarters.first.beginning_of_quarter),
       create(:patient, registration_facility: facilities.first, recorded_at: quarters.third.beginning_of_quarter - 1.month),
       create(:patient, registration_facility: facilities.second, recorded_at: quarters.second.beginning_of_quarter + 10.days)]
    end

    let!(:bp_1) { create(:blood_pressure, patient: patients.first, facility: facilities.third, recorded_at: quarters.second.beginning_of_quarter) }
    let!(:bp_2) { create(:blood_pressure, patient: patients.second, facility: facilities.third, recorded_at: quarters.second.beginning_of_quarter) }
    let!(:bp_3) { create(:blood_pressure, patient: patients.first, facility: facilities.third, recorded_at: quarters.third.beginning_of_quarter) }
    let!(:bp_4) { create(:blood_pressure, patient: patients.third, facility: facilities.third, recorded_at: quarters.third.beginning_of_quarter) }

    before do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatient.refresh
      LatestBloodPressuresPerPatientPerQuarter.refresh
    end

    let!(:query) { described_class.new(period: :quarter) }
    let!(:periods) { query.periods.reverse }

    it 'calculates missed visits' do
      expect(query.missed_visits_by_facility[[facilities.first.id, *periods.second]]).to eq(patients: 1, missed: 0)
      expect(query.missed_visits_by_facility[[facilities.second.id, *periods.second]]).to eq(patients: 1, missed: 0)
      expect(query.missed_visits_by_facility[[facilities.first.id, *periods.third]]).to eq(patients: 1, missed: 0)
      expect(query.missed_visits_by_facility[[facilities.second.id, *periods.third]]).to eq(patients: 2, missed: 2)
      expect(query.missed_visit_totals[periods.first]).to eq(nil)
      expect(query.missed_visit_totals[periods.second]).to eq(patients: 2, missed: 0)
      expect(query.missed_visit_totals[periods.third]).to eq(patients: 3, missed: 2)
    end
  end

  context '#missed_visits_by_facility month' do
    let!(:facilities) { create_list(:facility, 3) }
    let!(:months) do
      [2, 1, 0].map { |n| n.months.ago.beginning_of_month }
    end

    let!(:patients) do
      [create(:patient, registration_facility: facilities.first, recorded_at: months.first.beginning_of_month - 3.months),
       create(:patient, registration_facility: facilities.second, recorded_at: months.first.beginning_of_month - 3.months),
       create(:patient, registration_facility: facilities.first, recorded_at: months.second.beginning_of_month),
       create(:patient, registration_facility: facilities.second, recorded_at: months.first.beginning_of_month - 10.days)]
    end

    let!(:bp_1) { create(:blood_pressure, patient: patients.first, facility: facilities.third, recorded_at: months.second.beginning_of_month) }
    let!(:bp_2) { create(:blood_pressure, patient: patients.second, facility: facilities.third, recorded_at: months.second.beginning_of_month) }
    let!(:bp_3) { create(:blood_pressure, patient: patients.first, facility: facilities.third, recorded_at: months.third.beginning_of_month) }
    let!(:bp_4) { create(:blood_pressure, patient: patients.third, facility: facilities.third, recorded_at: months.third.beginning_of_month) }

    before do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatient.refresh
    end

    let!(:query) { described_class.new(period: :month) }
    let!(:periods) { query.periods.reverse }

    it 'calculates missed visits' do
      expect(query.missed_visits_by_facility[[facilities.first.id, *periods.second]]).to eq(patients: 1, missed: 0)
      expect(query.missed_visits_by_facility[[facilities.second.id, *periods.second]]).to eq(patients: 1, missed: 0)
      expect(query.missed_visits_by_facility[[facilities.first.id, *periods.third]]).to eq(patients: 1, missed: 0)
      expect(query.missed_visits_by_facility[[facilities.second.id, *periods.third]]).to eq(patients: 2, missed: 2)
      expect(query.missed_visit_totals[periods.first]).to eq(patients: 2, missed: 2)
      expect(query.missed_visit_totals[periods.second]).to eq(patients: 2, missed: 0)
      expect(query.missed_visit_totals[periods.third]).to eq(patients: 3, missed: 2)
    end
  end
end
