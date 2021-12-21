# frozen_string_literal: true

class Reports::MonthlyProgressComponent < ViewComponent::Base
  attr_reader :gender_groups
  attr_reader :range
  attr_reader :diagnosis
  attr_reader :metric

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

  def diagnosis_code
    case diagnosis
    when :hypertension then "htn"
    when :diabetes then "dm"
    when :all then nil
    else raise ArgumentError, "invalid diagnosis #{diagnosis}"
    end
  end

  def total_count
    @query.sum(@total_field)
  end

  def monthly_count(period)
    @query.find_by(month_date: period).attributes[@total_field]
  end

  def monthly_count_by_gender(period, gender)
    field = "monthly_#{metric}_#{@diagnosis_code}_#{gender}"
    @query.find_by(month_date: period).attributes[field]
  end

  def total_count_by_gender(gender)
    field = "monthly_#{metric}_#{@diagnosis_code}_#{gender}"
    @query.sum(field)
  end


end
