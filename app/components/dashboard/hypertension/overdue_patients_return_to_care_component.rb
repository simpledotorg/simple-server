class Dashboard::Hypertension::OverduePatientsReturnToCareComponent < ApplicationComponent
  attr_reader :data

  def initialize(region:, data:, period:, with_removed_from_overdue_list:)
    @region = region
    @data = data
    @period = period
    @contactable = !with_removed_from_overdue_list
  end

  def graph_data
    if @contactable
      return {
        overduePatients: data[:overdue_patients],
        overduePatientsCalled: data[:patients_called],
        overduePatientsCalledRate: data[:patients_called_rates],
        startDate: @period.advance(months: -17),
        chartProportionalPercentageCalledWithResultAgreedToVisit: data[:contactable_patients_called_with_result_agreed_to_visit_rates],
        chartProportionalPercentageCalledWithResultRemindToCallLater: data[:contactable_patients_called_with_result_remind_to_call_later_rates],
        chartProportionalPercentageCalledWithResultRemoveFromOverdueList: data[:contactable_patients_called_with_result_removed_from_list_rates],
        **period_data
      }
    end

    {
      overduePatients: data[:overdue_patients],
      overduePatientsCalled: data[:patients_called],
      overduePatientsCalledRate: data[:patients_called_rates],
      startDate: @period.advance(months: -17),
      chartProportionalPercentageCalledWithResultAgreedToVisit: data[:patients_called_with_result_agreed_to_visit_rates],
      chartProportionalPercentageCalledWithResultRemindToCallLater: data[:patients_called_with_result_remind_to_call_later_rates],
      chartProportionalPercentageCalledWithResultRemoveFromOverdueList: data[:patients_called_with_result_removed_from_list_rates],
      **period_data
    }
  end

  def periods
    start_period = @period.advance(months: -17)
    Range.new(start_period, @period)
  end

  private

  def cap_percentage(percentage)
    [percentage, 100].min
  end

  def period_data
    {
      startDate: @period.advance(months: -17),
      endDate: period_info(:name)
    }
  end

  def period_info(key)
    data[:period_info].map { |k, v| [k, v[key]] }.to_h
  end
end
