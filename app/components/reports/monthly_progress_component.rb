# frozen_string_literal: true

class Reports::MonthlyProgressComponent < ViewComponent::Base
  attr_reader :dimension
  attr_reader :range
  attr_reader :monthly_counts
  attr_reader :total_counts

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

  # The default diagnosis is the one we display at the top level on initial page load
  def default_diagnosis
    :all
  end

  def total_count
    @total_counts.attributes[dimension.field]
  end

  def monthly_count(period)
    counts_by_period[period].attributes[dimension.field]
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

end
