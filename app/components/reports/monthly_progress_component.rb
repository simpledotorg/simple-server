# frozen_string_literal: true

class Reports::MonthlyProgressComponent < ViewComponent::Base
  attr_reader :diabetes_enabled
  attr_reader :diagnosis
  attr_reader :facility
  attr_reader :gender_groups
  attr_reader :metric
  attr_reader :range
  attr_reader :results

  def initialize(facility:, diagnosis:, metric:, results:, range:, gender_groups: true)
    @facility = facility
    @diagnosis = diagnosis
    # @diagnosis_code = @diagnosis == :hypertension ? "htn" : "dm"
    @metric = metric
    @results = results
    @range = range
    @total_field = ["monthly", metric, diagnosis_code, "all"].compact.join("_")
    @gender_groups = gender_groups
  end

  def diagnosis_group_class(gender)
    classes = []
    classes << diagnosis unless diagnosis == :all
    classes << gender
    classes.compact.join(":")
  end

  def diagnosis_code
    case diagnosis
    when :hypertension then :htn
    when :diabetes then :dm
    when :all then :all
    else raise ArgumentError, "invalid diagnosis #{diagnosis}"
    end
  end

  def diagnosis_code_for_non_gender_breakdowns
    case diagnosis
    when :hypertension then :htn
    when :diabetes then :dm
    when :all then nil
    else raise ArgumentError, "invalid diagnosis #{diagnosis}"
    end
  end

  def table(grouping, &block)
    options = {class: ["progress-table", metric, diagnosis_group_class(grouping)]}
    unless diagnosis == default_diagnosis && grouping == :all
      options[:style] = "display:none"
    end
    tag.table(options, &block)
  end

  # The default diagnosis is the one we display at the top level for the first display of progress tab
  def default_diagnosis
    if facility.diabetes_enabled?
      :all
    else
      :hypertension
    end
  end

  def total_count
    Reports::FacilityStateGroup.total(facility, metric, diagnosis)
  end

  def results_by_period
    @results_by_period ||= results.each_with_object({}) do |result, hsh|
      hsh[result.period] = result
    end
  end

  def monthly_count(period)
    field = ["monthly", metric, diagnosis_code_for_non_gender_breakdowns, "all"].compact.join("_")
    results_by_period[period].attributes[field]
  end

  def monthly_count_by_gender(period, gender)
    field = "monthly_#{metric}_#{diagnosis_code}_#{gender}"
    results_by_period[period].attributes[field]
    # d field
    # d result
  end

  def total_count_by_gender(gender)
    return "TODO"
    field = "monthly_#{metric}_#{@diagnosis_code}_#{gender}"
    results.sum(field).truncate
  end
end
