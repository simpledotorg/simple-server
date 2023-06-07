class Dashboard::Hypertension::OverduePatientsCalledTableComponent < ApplicationComponent
  attr_reader :region, :period, :data, :children_data, :localized_region_type

  def initialize(region:, data:, repository:, period:, current_admin:, with_non_contactable:)
    @region = region
    @data = data
    @repository = repository
    @period = period
    @current_admin = current_admin
    @children_data = facility? ? patient_call_count_by_user : patients_call_count_by_region
  end

  def patients_call_count_by_region
    region
      .reportable_children
      .map { |sub_region| {sub_region => @repository.patients_called[sub_region.slug]} }
      .reduce(:merge)
  end

  def patient_call_count_by_user
     @current_admin.accessible_users(:view_reports)
      .order(:full_name)
      .filter {|accessible_user| accessible_user.registration_facility_id == @region.facilities.first.id}
      .map { |user| calls_made_by_user(user) }
      .reduce(:merge)
  end

  def calls_made_by_user(user)
    {user => periods.map { |p| monthly_calls_made_by_user(user, p) }.flatten.reduce(:merge)}
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

  def overdue_patients(region, period)
    @repository.overdue_patients.dig(region.slug, period)
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

  def patients_called_tooltip(numerator, denominator)
    "#{numerator} / #{denominator} overdue patients called"
  end

  private

  def atleast_one_call?(call_count_by_period)
    call_count_by_period.sum { |_p, values| values }.nonzero?
  end
end
