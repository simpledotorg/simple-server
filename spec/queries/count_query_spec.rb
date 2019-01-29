require 'rails_helper'

RSpec.describe CountQuery, type: :query do
  let(:facility_1) { create :facility }
  let(:facility_2) { create :facility }

  let(:user_1) { create :user }
  let(:user_2) { create :user }

  let!(:blood_pressures_for_facility_1) { create_list :blood_pressure, 5, facility: facility_1, user: user_1 }
  let!(:blood_pressures_for_facility_2) { create_list :blood_pressure, 5, facility: facility_2, user: user_2 }

  describe 'distinct_count' do
    it 'returns distinct count for a column in a relation' do
      count = CountQuery.new(BloodPressure.all).distinct_count('facility_id')
      expect(count).to eq(2)
    end

    it 'returns distinct count for a column grouped by a single column' do
      count = CountQuery.new(BloodPressure.all).distinct_count('patient_id', group_by_columns: :user_id)

      expect(count).to eq(user_1.id => 5, user_2.id => 5)
    end

    it 'returns distinct count for a column grouped by multiple columns' do
      count = CountQuery.new(BloodPressure.all).distinct_count('patient_id', group_by_columns: [:facility_id, :user_id])

      expect(count)
        .to eq([facility_1.id, user_1.id] => 5, [facility_2.id, user_2.id] => 5)
    end

    it 'returns distinct count for a column grouped by a period' do
      create_list :blood_pressure, 5, created_at: 3.days.ago

      count = CountQuery.new(BloodPressure.all).distinct_count('patient_id', group_by_period:
        { period: :day, column: :created_at })

      expect(count).to include(3.days.ago.to_date => 5, Date.today => 10)
    end

    it 'returns distinct count for a column grouped by a period with options' do
      create_list :blood_pressure, 5, created_at: 3.days.ago

      count = CountQuery.new(BloodPressure.all).distinct_count('patient_id', group_by_period:
        { period: :day, column: :created_at, options: { last: 2 } })

      expect(count).to include(Date.today => 10)
      expect(count).not_to include(3.days.ago.to_date => 5)
    end
  end
end