class Dashboard::Hypertension::OverduePatientsReturnToCareComponent < ApplicationComponent
  attr_reader :data, :contactable, :period

  def initialize(region:, data:, period:, with_non_contactable:)
    @region = region
    @data = data
    @period = period
    @contactable = !with_non_contactable
  end

  def graph_data
    if contactable
      {
        overduePatientsCalled: data[:contactable_patients_called],
        overduePatientsReturned: data[:contactable_patients_returned_after_call],
        overduePatientsReturnedRate: data[:contactable_patients_returned_after_call_rates],
        patientsReturnedAgreedToVisitRates: data[:contactable_patients_returned_with_result_agreed_to_visit_rates],
        patientsReturnedRemindToCallLaterRates: data[:contactable_patients_returned_with_result_remind_to_call_later_rates],
        patientsReturnedRemovedFromOverdueListRates: data[:contactable_patients_returned_with_result_removed_from_list_rates],
        **period_data
      }
    else
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
  end

  private

  def period_data
    {
      startDate: period.advance(months: -17),
      endDate: period_info(:name)
    }
  end

  def period_info(key)
    data[:period_info].map { |k, v| [k, v[key]] }.to_h
  end
end
