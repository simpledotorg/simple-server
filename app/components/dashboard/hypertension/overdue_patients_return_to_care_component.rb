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
        overduePatientsCalled: data[:contactable_patients_called],
        overduePatientsReturned: data[:contactable_patients_returned_after_call],
        overduePatientsReturnedRate: data[:contactable_patients_returned_after_call_rates],
        patientsReturnedAgreedToVisitRates: data[:contactable_patients_returned_with_result_agreed_to_visit_rates],
        patientsReturnedRemindToCallLaterRates: data[:contactable_patients_returned_with_result_remind_to_call_later_rates],
        patientsReturnedRemovedFromOverdueListRates: data[:contactable_patients_returned_with_result_removed_from_list_rates],
        **period_data
      }
    end

    {
      overduePatientsCalled: data[:patients_called],
      overduePatientsReturned: data[:patients_returned_after_call],
      overduePatientsReturnedRate: data[:patients_returned_after_call_rates],
      patientsReturnedAgreedToVisitRates: data[:patients_returned_with_result_agreed_to_visit_rates],
      patientsReturnedRemindToCallLaterRates: data[:patients_returned_with_result_remind_to_call_later_rates],
      patientsReturnedRemovedFromOverdueListRates: data[:patients_returned_with_result_removed_from_list_rates],
      **period_data
    }
  end

  def periods
    start_period = @period.advance(months: -17)
    Range.new(start_period, @period)
  end

  private

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
