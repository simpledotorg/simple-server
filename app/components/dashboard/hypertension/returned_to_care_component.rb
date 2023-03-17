class Dashboard::Hypertension::ReturnedToCareComponent < ApplicationComponent
  attr_reader :region, :data, :period

  def initialize(region:, data:, period:)
    @region = region
    @data = data
    @period = period
  end

  def graph_data
    # puts :ltfu_trend
    # puts data
    # puts data.dig(:ltfu_trend, :ltfu_patients)
    {
      ltfuPatients: data.dig(:ltfu_trend, :ltfu_patients),
      ltfuPatientsRate: data.dig(:ltfu_trend, :ltfu_patients_rate),
      cumulativeAssignedPatients: data.dig(:ltfu_trend, :cumulative_assigned_patients),
      **period_data,
      **overdue_data
    }
  end

  def overdue_data
    {
      patients_under_care: [
        252,
        274,
        308,
        360,
        405,
        449,
        499,
        527,
        578,
        612,
        666,
        674
      ],

      overdue_patients: [
        28,
        122,
        112,
        173,
        135,
        140,
        124,
        92,
        185,
        215,
        175,
        128
      ],

      patients_called: [0,
        7,
        2,
        34,
        21,
        36,
        34,
        13,
        13,
        140,
        77,
        47],
      patients_called_agreed_to_visit: [
        0,
3,
2,
16,
6,
15,
17,
5,
8,
70,
34,
14
      ],
      patients_called_remind_to_call: [0, 0, 0, 0, 0, 1, 0, 1, 2, 0, 0, 0],
      patients_called_removed_from_overdue_list: [
        0,
4,
0,
18,
15,
20,
17,
7,
3,
70,
43,
33
      ],

      returned_to_care: [0,
        1,
        0,
        6,
        5,
        15,
        12,
        5,
        4,
        36,
        37,
        8],
      returned_to_care_agreed: [0, 0, 0, 4, 2, 8, 10, 3, 4, 26, 23, 4],
      returned_to_care_remind: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      returned_to_care_removed: [0, 1, 0, 2, 3, 7, 2, 2, 0, 10, 14, 4]

    }
  end

  private

  def period_data
    {
      startDate: period_info(:bp_control_start_date),
      endDate: period_info(:bp_control_end_date),
      registrationDate: period_info(:bp_control_registration_date)
    }
  end

  def period_info(key)
    data[:period_info].map { |k, v| [k, v[key]] }.to_h
  end
end
