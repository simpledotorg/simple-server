# frozen_string_literal: true

class Reports::MonthlyProgressComponent < ViewComponent::Base
  # maybe we dont need:
  # facility
  #
  # definitely need:
  # range
  # total counts
  # monthly counts
  # metric (or indicator?)
  # diagnosis
  # gender

  attr_reader :diabetes_enabled
  attr_reader :diagnosis
  attr_reader :facility
  attr_reader :gender_groups
  attr_reader :metric
  attr_reader :range
  attr_reader :counts

  def initialize(facility:, diagnosis:, metric:, counts:, total_counts:, range:, gender_groups: true)
    @facility = facility
    @diagnosis = diagnosis
    @metric = metric
    @counts = counts
    @range = range
    @total_counts = total_counts
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
    :all
  end

  def total_count(gender: :all)
    field = ["monthly", metric, diagnosis_code_for_non_gender_breakdowns, "all"].compact.join("_")
    d field
    @total_counts.attributes[field]
  end

  NULL_COUNTS = Struct.new(:attributes) do
    def attributes
      Hash.new(0)
    end
  end

  def counts_by_period
    @counts_by_period ||= range.each_with_object({}) do |period, hsh|
      hsh[period] = counts.find { |c| c.period == period } || NULL_COUNTS.new
    end
  end

  def monthly_count(period)
    field = ["monthly", metric, diagnosis_code_for_non_gender_breakdowns, "all"].compact.join("_")
    counts_by_period[period]&.attributes[field]
  end

  def monthly_count_by_gender(period, gender)
    field = "monthly_#{metric}_#{diagnosis_code}_#{gender}"
    counts_by_period[period].attributes[field]
  end
end
