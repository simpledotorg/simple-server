require "rails_helper"

RSpec.describe MyFacilities::MissedVisitsQuery do
  include QuarterHelper

  context "#missed_visits_by_facility quarter" do
    let!(:facilities) { create_list(:facility, 3) }
    let!(:registration_facility) { create(:facility) }
    let!(:quarters) do
      last_n_quarters(n: 3, inclusive: false).map { |year_quarter| local_quarter_start(*year_quarter) }.reverse
    end

    let!(:patients) do
      [create(:patient, registration_facility: registration_facility, assigned_facility: facilities.first, recorded_at: quarters.first.beginning_of_quarter),
        create(:patient, registration_facility: registration_facility, assigned_facility: facilities.second, recorded_at: quarters.first.beginning_of_quarter),
        create(:patient, registration_facility: registration_facility, assigned_facility: facilities.first, recorded_at: quarters.third.beginning_of_quarter - 1.month),
        create(:patient, registration_facility: registration_facility, assigned_facility: facilities.second, recorded_at: quarters.second.beginning_of_quarter + 10.days)]
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

    it "calculates missed visits" do
      expect(query.missed_visits_by_facility[[facilities.first.id, *periods.first]]).to eq(patients: 1, missed: 0)
      expect(query.missed_visits_by_facility[[facilities.second.id, *periods.first]]).to eq(patients: 1, missed: 0)
      expect(query.missed_visits_by_facility[[facilities.first.id, *periods.second]]).to eq(patients: 1, missed: 0)
      expect(query.missed_visits_by_facility[[facilities.second.id, *periods.second]]).to eq(patients: 1, missed: 1)
      expect(query.missed_visits_by_facility[[facilities.first.id, *periods.third]]).to be_nil
      expect(query.missed_visits_by_facility[[facilities.second.id, *periods.third]]).to be_nil
      expect(query.missed_visit_totals[periods.first]).to eq(patients: 2, missed: 0)
      expect(query.missed_visit_totals[periods.second]).to eq(patients: 2, missed: 1)
      expect(query.missed_visit_totals[periods.third]).to eq(patients: 0, missed: 0)
    end
  end

  context "#missed_visits_by_facility month" do
    let!(:facilities) { create_list(:facility, 3) }
    let!(:registration_facility) { create(:facility) }
    let!(:months) do
      [3, 2, 1].map { |n| n.months.ago.beginning_of_month }
    end

    let!(:patients) do
      [create(:patient, registration_facility: registration_facility, assigned_facility: facilities.first, recorded_at: months.first.beginning_of_month),
        create(:patient, registration_facility: registration_facility, assigned_facility: facilities.second, recorded_at: months.second.beginning_of_month),
        create(:patient, registration_facility: registration_facility, assigned_facility: facilities.first, recorded_at: months.third.beginning_of_month),
        create(:patient, registration_facility: registration_facility, assigned_facility: facilities.second, recorded_at: months.first.beginning_of_month)]
    end

    let!(:bp_1) { create(:blood_pressure, patient: patients.first, facility: facilities.third, recorded_at: months.second.beginning_of_month) }
    let!(:bp_2) { create(:blood_pressure, patient: patients.second, facility: facilities.third, recorded_at: months.second.beginning_of_month) }
    let!(:bp_3) { create(:blood_pressure, patient: patients.first, facility: facilities.third, recorded_at: months.third.beginning_of_month) }
    let!(:bp_4) { create(:blood_pressure, patient: patients.third, facility: facilities.third, recorded_at: (months.third + 1.month).beginning_of_month) }

    before do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatient.refresh
    end

    let!(:query) { described_class.new(period: :month, facilities: facilities) }
    let!(:periods) { query.periods.reverse }

    it "calculates missed visits" do
      expect(query.missed_visits_by_facility[[facilities.first.id, *periods.first]]).to eq(patients: 1, missed: 0)
      expect(query.missed_visits_by_facility[[facilities.second.id, *periods.first]]).to eq(patients: 1, missed: 1)
      expect(query.missed_visits_by_facility[[facilities.first.id, *periods.second]]).to be_nil
      expect(query.missed_visits_by_facility[[facilities.second.id, *periods.second]]).to eq(patients: 1, missed: 1)
      expect(query.missed_visits_by_facility[[facilities.first.id, *periods.third]]).to eq(patients: 1, missed: 0)
      expect(query.missed_visits_by_facility[[facilities.second.id, *periods.third]]).to be_nil
      expect(query.missed_visit_totals[periods.first]).to eq(patients: 2, missed: 1)
      expect(query.missed_visit_totals[periods.second]).to eq(patients: 1, missed: 1)
      expect(query.missed_visit_totals[periods.third]).to eq(patients: 1, missed: 0)
    end
  end
end
