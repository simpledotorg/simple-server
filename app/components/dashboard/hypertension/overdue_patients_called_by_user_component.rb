class Dashboard::Hypertension::OverduePatientsCalledByUserComponent < ApplicationComponent
  attr_reader :region, :period, :data, :children_data, :localized_region_type

  def initialize(region:, data:, repository:, period:, current_admin:, with_removed_from_overdue_list:)
    @region = region
    @data = data
    @repository = repository
    @period = period
    @current_admin = current_admin
    @children_data = patient_call_count_by_user
    calls_made_by_region
  end

  def patient_call_count_by_user
    users = @current_admin.accessible_users(:view_reports)
      .order(:full_name)
      .map { |user| calls_made_by_user(user) }
      .reduce(:merge)
      .filter { |_user, call_count_by_period| atleast_one_call?(call_count_by_period) }
  end

  def atleast_one_call?(call_count_by_period)
    call_count_by_period.sum { |_p, values| values }.nonzero?
  end

  def calls_made_by_user(user)
    {user => periods.map { |p| monthly_calls_made_by_user(user, p).reduce(:merge) }}
  end

  def monthly_calls_made_by_user(user, period)
    {period => @repository.overdue_patients_called_by_user.dig(region.slug, period, user.id) || 0}
  end

  def total_calls(period)
    @repository.overdue_patients_called_by_user.dig(region.slug)
      .map { |period, calls| {period => calls.values.sum} }
      .reduce(:merge)
      .dig(period) || 0
  end

  def calls_made_by_region
    region.reportable_children
  end

  def overdue_patients(period)
    data[:overdue_patients].dig(period)
  end

  def percentage(numerator, denominator)
    return "-" if denominator.blank? || denominator.zero?
    "#{numerator * 100 / denominator}%"
  end

  def table_headers
    [{title: "RBS &lt;200".html_safe}]
  end

  def periods
    start_period = @period.advance(months: -2)
    Range.new(start_period, @period)
  end

  def facility?
    region.region_type == "facility"
  end
end
