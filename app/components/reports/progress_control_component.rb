# frozen_string_literal: true

class Reports::ProgressControlComponent < ViewComponent::Base
  include ActionView::Helpers::NumberHelper

  attr_reader :control_range, :repository

  def initialize(service)
    @repository = service.control_rates_repository
    @control_range = repository.range
    @region = service.region
  end

  def control_summary
    controlled_count = format(controlled[control_range.last])
    registrations = format(adjusted_patients[control_range.last])
    label = "patient".pluralize(registrations)
    "#{controlled_count} of #{registrations} #{label}"
  end

  def format(number)
    number_with_delimiter(number)
  end

  def controlled
    repository.controlled[@region.slug]
  end

  def control_rates
    repository.controlled_rates[@region.slug]
  end

  def adjusted_patients
    repository.adjusted_patients[@region.slug]
  end
end
