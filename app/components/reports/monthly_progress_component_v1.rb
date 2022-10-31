# frozen_string_literal: true

class Reports::MonthlyProgressComponentV1 < ViewComponent::Base
  include AssetsHelper
  include DashboardHelper
  attr_reader :dimension
  attr_reader :range
  attr_reader :dimension_indicator
  attr_reader :dimension_field
  attr_reader :monthly_counts
  attr_reader :total_counts
  attr_reader :current_user

  def initialize(dimension, service:, current_user:)
    @dimension = dimension
    @dimension_indicator = dimension.indicator
    @dimension_field = dimension.field_v1
    @monthly_counts = service.monthly_counts
    @total_counts = service.total_counts
    @region = service.region
    @range = service.range.reverse_each
    @current_user = current_user
  end

  def render?
    Flipper.enabled?(:new_progress_tab_v1, current_user) || Flipper.enabled?(:new_progress_tab_v1)
  end

  # The default diagnosis is the one we display at the top level on initial page load
  def default_diagnosis
    :all
  end

  def total_count
    @total_counts.attributes[dimension_field]
  end

  def monthly_count(period)
    counts = monthly_counts[period]
    if counts
      counts.attributes[dimension_field]
    else
      0
    end
  end
end
