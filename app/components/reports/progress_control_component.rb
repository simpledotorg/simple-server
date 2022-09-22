# frozen_string_literal: true

class Reports::ProgressControlComponent < ViewComponent::Base
  include AssetsHelper
  include ActionView::Helpers::NumberHelper

  attr_reader :control_range, :repository, :current_user

  def initialize(service, current_user)
    @repository = service.control_rates_repository
    @control_range = repository.range
    @region = service.region
    @current_user = current_user
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

  def control_rates
    repository.controlled_rates[@region.slug]
  end

  def controlled
    repository.controlled[@region.slug]
  end

  def adjusted_patients
    repository.adjusted_patients[@region.slug]
  end

  def period_info
    repository.period_info(@region)
  end
end
