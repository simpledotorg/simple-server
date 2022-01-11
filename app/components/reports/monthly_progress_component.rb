# frozen_string_literal: true

class Reports::MonthlyProgressComponent < ViewComponent::Base
  attr_reader :diabetes_enabled
  attr_reader :diagnosis
  attr_reader :facility
  attr_reader :gender_groups
  attr_reader :metric
  attr_reader :range

  def initialize(facility:, diagnosis:, metric:, query:, range:, gender_groups: true)
    @facility = facility
    @diagnosis = diagnosis
    @diagnosis_code = @diagnosis == :hypertension ? "htn" : "dm"
    @metric = metric
    @query = query
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
    when :hypertension then "htn"
    when :diabetes then "dm"
    when :all then nil
    else raise ArgumentError, "invalid diagnosis #{diagnosis}"
    end
  end

  def table(grouping, &block)
    options = { class: ["progress-table", metric, diagnosis_group_class(grouping)] }
    unless (diagnosis == default_diagnosis && grouping == :all)
      options[:style] = "display:none"
    end
    tag.table(options, &block)
  end

  # The defaut diagnosis is the one we display at the top level for the first display of progress tab
  def default_diagnosis
    if facility.diabetes_enabled?
      :all
    else
      :hypertension
    end
  end

  def total_count
    @query.sum(@total_field).truncate
  end

  def monthly_count(period)
    if (facility_state_group = @query.find_by(month_date: period))
      facility_state_group.attributes[@total_field]
    else
      0
    end
  end

  def monthly_count_by_gender(period, gender)
    field = "monthly_#{metric}_#{@diagnosis_code}_#{gender}"
    if (facility_state_group = @query.find_by(month_date: period))
      facility_state_group.attributes[field]
    else
      0
    end
  end

  def total_count_by_gender(gender)
    field = "monthly_#{metric}_#{@diagnosis_code}_#{gender}"
    @query.sum(field).truncate
  end
end
