# frozen_string_literal: true

class Reports::ProgressMissedVisitsComponent < ViewComponent::Base
  include AssetsHelper
  include ActionView::Helpers::NumberHelper

  attr_reader :control_range, :repository

  def initialize(service)
    @repository = service.control_rates_repository
    @control_range = repository.range
    @region = service.region
  end

  def missed_visits_rates
    repository.missed_visits_rate[@region.slug]
  end

  def missed_visits
    repository.missed_visits[@region.slug]
  end

  def adjusted_patients
    repository.adjusted_patients[@region.slug]
  end

  def period_info
    repository.period_info(@region)
  end
end
