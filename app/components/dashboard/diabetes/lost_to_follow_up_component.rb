class Dashboard::Diabetes::LostToFollowUpComponent < ApplicationComponent
  attr_reader :region, :data, :period

  def initialize(region:, data:, period:)
    @region = region
    @data = data
    @period = period
  end

  def graph_data
    {
      ltfuPatients: data.dig(:ltfu_trend, :ltfu_patients),
      ltfuPatientsRate: data.dig(:ltfu_trend, :ltfu_patients_rate),
      cumulativeAssignedPatients: data.dig(:ltfu_trend, :cumulative_assigned_patients),
      **period_data
    }
  end

  private

  def period_data
    {
      startDate: period_info(:ltfu_since_date),
      endDate: period_info(:ltfu_end_date)
    }
  end

  def period_info(key)
    data[:period_info].transform_values { |v| v[key] }
  end
end
