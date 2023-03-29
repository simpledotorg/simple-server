class Dashboard::Hypertension::OverduePatientsCalledByUserComponent < ApplicationComponent
  def initialize(region:, data:, period:, with_removed_from_overdue_list:)
    @region = region
    @data = data
    @period = period
    @with_removed_from_overdue_list = with_removed_from_overdue_list
  end

  def graph_data
  end
end
