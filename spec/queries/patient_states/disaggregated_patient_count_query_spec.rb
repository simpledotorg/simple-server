require "rails_helper"

describe PatientStates::DisaggregatedPatientCountQuery do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  let(:query) {
    Reports::PatientState.all
  }

  describe ".disaggregate_by_gender" do
    it "returns the query disaggregated by gender" do
      Patient::GENDERS.each { |gender| create(:patient, gender: gender) }
      refresh_views
      expected_disaggregated_counts = Patient::GENDERS.map { |gender| [gender, 1] }.to_h

      expect(PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_gender(query).count)
        .to eq(expected_disaggregated_counts)
    end
  end

  describe ".disaggregate_by_age" do
    it "returns the query disaggregated by age" do
      _facility_1_patient_1 = create(:patient, age: 30)
      _facility_1_patient_2 = create(:patient, date_of_birth: 85.years.ago)
      _facility_1_patient_1 = create(:patient, age: 10)
      _facility_1_patient_1 = create(:patient, age: 27)

      refresh_views

      expect(PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_age([25, 50, 75], query).count)
        .to eq({0 => 1, 1 => 2, 3 => 1})
    end
  end
end
