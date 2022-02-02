# frozen_string_literal: true

class Reports::MonthlyProgressComponent < ViewComponent::Base
  # maybe we dont need:
  # facility
  #
  # definitely need:
  #
  # range
  # total counts
  # monthly counts
  # FacilityProgressDimension

  attr_reader :diabetes_enabled
  attr_reader :dimension
  attr_reader :range
  attr_reader :monthly_counts
  attr_reader :total_counts

# <% render(Reports::MonthlyProgressComponent.new(dimension, range: @range, total_counts: @total_counts, monthly_counts: monthly_counts)
  def initialize(dimension, range:, total_counts:, monthly_counts:)
    @dimension = dimension
    @monthly_counts = monthly_counts
    @total_counts = total_counts
    @range = range
  end

  def diagnosis_group_class
    classes = []
    classes << dimension.diagnosis unless dimension.diagnosis == :all
    classes << dimension.gender
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

  def display?
    dimension.diagnosis == :all && dimension.gender == :all
  end

  def table(&block)
    options = {class: ["progress-table", dimension.indicator, diagnosis_group_class]}
    if !display?
      options[:style] = "display:none"
    end
    tag.table(options, &block)
  end

  # The default diagnosis is the one we display at the top level for the first display of progress tab
  def default_diagnosis
    :all
  end

  def total_count
    d dimension.field
    @total_counts.attributes[dimension.field]
  end

  NULL_COUNTS = Struct.new(:attributes) do
    def attributes
      Hash.new(0)
    end
  end

  def counts_by_period
    @counts_by_period ||= range.each_with_object({}) do |period, hsh|
      hsh[period] = @monthly_counts.find { |c| c.period == period } || NULL_COUNTS.new
    end
  end

  def monthly_count(period)
    counts_by_period[period]&.attributes[dimension.field]
  end

  def monthly_count_by_gender(period)
    counts_by_period[period].attributes[dimension.field]
  end
end
