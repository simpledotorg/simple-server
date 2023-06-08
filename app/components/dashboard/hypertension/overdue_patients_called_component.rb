class Dashboard::Hypertension::OverduePatientsCalledComponent < ApplicationComponent
  attr_reader :data

  def initialize(region:, data:, period:, with_non_contactable:)
    @region = region
    @data = data
    @period = period
    @contactable = !with_non_contactable
  end

  def graph_data
    if @contactable
      return {
        overduePatients: data[:contactable_overdue_patients],
        overduePatientsCalled: data[:contactable_patients_called],
        overduePatientsCalledRate: data[:contactable_patients_called_rates],
        startDate: @period.advance(months: -17),
        calledWithResultAgreedToVisit: data[:contactable_patients_called_with_result_agreed_to_visit_rates],
        calledWithResultRemindToCallLater: data[:contactable_patients_called_with_result_remind_to_call_later_rates],
        calledWithResultRemoveFromOverdueList: data[:contactable_patients_called_with_result_removed_from_list_rates],
        chartProportionalPercentageCalledWithResultAgreedToVisit: proportional_call_rate(:contactable_patients_called_with_result_agreed_to_visit_rates),
        chartProportionalPercentageCalledWithResultRemindToCallLater: proportional_call_rate(:contactable_patients_called_with_result_remind_to_call_later_rates),
        chartProportionalPercentageCalledWithResultRemoveFromOverdueList: proportional_call_rate(:contactable_patients_called_with_result_removed_from_list_rates),
        **period_data
      }
    end

    {
      overduePatients: data[:overdue_patients],
      overduePatientsCalled: data[:patients_called],
      overduePatientsCalledRate: data[:patients_called_rates],
      startDate: @period.advance(months: -17),
      calledWithResultAgreedToVisit: data[:patients_called_with_result_agreed_to_visit_rates],
      calledWithResultRemindToCallLater: data[:patients_called_with_result_remind_to_call_later_rates],
      calledWithResultRemoveFromOverdueList: data[:patients_called_with_result_removed_from_list_rates],
      chartProportionalPercentageCalledWithResultAgreedToVisit: proportional_call_rate(:patients_called_with_result_agreed_to_visit_rates),
      chartProportionalPercentageCalledWithResultRemindToCallLater: proportional_call_rate(:patients_called_with_result_remind_to_call_later_rates),
      chartProportionalPercentageCalledWithResultRemoveFromOverdueList: proportional_call_rate(:patients_called_with_result_removed_from_list_rates),
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

  def proportional_call_rate(numerator)
    denominator_keys = if @contactable
      %i[contactable_patients_called_with_result_agreed_to_visit_rates
        contactable_patients_called_with_result_remind_to_call_later_rates
        contactable_patients_called_with_result_removed_from_list_rates]
    else
      %i[patients_called_with_result_agreed_to_visit_rates
        patients_called_with_result_remind_to_call_later_rates
        patients_called_with_result_removed_from_list_rates]
    end

    data[numerator].map do |period, value|
      denominator = denominator_keys.map { |k| data[k][period] }.sum
      {period => denominator.zero? ? 0 : value * 100 / denominator}
    end.reduce(:merge)
  end
end
