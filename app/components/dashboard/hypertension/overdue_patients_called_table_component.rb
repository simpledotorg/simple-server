class Dashboard::Hypertension::OverduePatientsCalledTableComponent < ApplicationComponent
  attr_reader :region, :period, :data, :children_data, :localized_region_type

  def initialize(region:, data:, repository:, period:, current_admin:, with_non_contactable:)
    @region = region
    @data = data
    @repository = repository
    @period = period
    @current_admin = current_admin
    @children_data = facility? ? patient_call_count_by_user : patients_call_count_by_region
    @contactable = !with_non_contactable
  end

  def patients_call_count_by_region
    region
      .reportable_children
      .map { |sub_region| {sub_region => patients_called(sub_region)} }
      .reduce(:merge)
  end

  def patient_call_count_by_user
    @current_admin.accessible_users(:view_reports)
      .order(:full_name)
      .map { |user| calls_made_by_user(user) }
      .reduce(:merge)
      .filter { |user, period| show_user?(user, period) }
  end

  def calls_made_by_user(user)
    {user => periods.map { |p| monthly_calls_made_by_user(user, p) }.flatten.reduce(:merge)}
  end

  def monthly_calls_made_by_user(user, period)
    if @contactable
      {period => @repository.contactable_overdue_patients_called_by_user.dig(region.slug, period, user.id) || 0}
    else
      {period => @repository.overdue_patients_called_by_user.dig(region.slug, period, user.id) || 0}
    end
  end

  def total_calls(period)
    if @contactable
      @data[:contactable_patients_called][period]
    else
      @data[:patients_called][period]
    end
  end

  def overdue_patients(region, period)
    if @contactable
      @repository.contactable_overdue_patients.dig(region.slug, period)
    else
      @repository.overdue_patients.dig(region.slug, period)
    end
  end

  def percentage_string(numerator, denominator)
    "#{percentage(numerator, denominator)}%"
  end

  def percentage(numerator, denominator)
    return 0 if denominator.blank? || denominator.zero?
    numerator * 100 / denominator
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
    "#{numerator} / #{denominator} overdue patients"
  end

  private

  def patients_called(region)
    if @contactable
      @repository.contactable_patients_called[region.slug]
    else
      @repository.patients_called[region.slug]
    end
  end

  def show_user?(user, call_count_by_period)
    registered_in_current_facility(user) || atleast_one_call?(call_count_by_period)
  end

  def registered_in_current_facility(user)
    user.registration_facility&.id == @region.facilities.first.id
  end

  def atleast_one_call?(call_count_by_period)
    call_count_by_period.sum { |_p, values| values }.nonzero?
  end
end
