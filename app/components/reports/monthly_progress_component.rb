# frozen_string_literal: true

class Reports::MonthlyProgressComponent < ViewComponent::Base
  include AssetsHelper
  include DashboardHelper
  attr_reader :dimension
  attr_reader :range
  attr_reader :monthly_counts
  attr_reader :total_counts

  def initialize(dimension, service:)
    @dimension = dimension
    @monthly_counts = service.monthly_counts
    @total_counts = service.total_counts
    @region = service.region
    @range = service.range.reverse_each
    @facility = Facility.find_by(name: @region.name)
    @is_diabetes_enabled = @facility.diabetes_enabled?
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
    counts = monthly_counts[period]
    if counts
      counts.attributes[dimension.field]
    else
      0
    end
  end
end
