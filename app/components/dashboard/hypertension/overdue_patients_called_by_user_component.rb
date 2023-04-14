class Dashboard::Hypertension::OverduePatientsCalledByUserComponent < ApplicationComponent
  attr_reader :region, :period, :data, :children_data, :localized_region_type

  def initialize(region:, data:, period:, with_removed_from_overdue_list:)
    @region = region
    @data = data
    @period = period
    @children_data = gen_children_data
    @with_removed_from_overdue_list = with_removed_from_overdue_list
  end

  def graph_data
  end

  def gen_children_data
    user = {
      user: User.first,
      patients_called: periods.map { |p| {p => rand(0..200)} }.reduce(:merge),
      total_patients: periods.map { |p| {p => rand(0..200)} }.reduce(:merge)
    }
    [user, user]
  end

  def table_headers
    [{title: "RBS &lt;200".html_safe}]
  end

  def periods
    start_period = @period.advance(months: -2)
    Range.new(start_period, @period)
  end

  def is_not_facility
    if region.child_region_type != 'facility'
      return true
    end
    false
  end
end
