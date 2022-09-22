# frozen_string_literal: true

class ProgressTab::Hypertension::UncontrolledComponent < ApplicationComponent
  include AssetsHelper
  include ActionView::Helpers::NumberHelper

  attr_reader :control_range, :repository

  def initialize(service)
    @repository = service.control_rates_repository
    @control_range = repository.range
    @region = service.region
  end

  def uncontrolled_rates
    repository.uncontrolled_rates[@region.slug]
  end

  def uncontrolled
    repository.uncontrolled[@region.slug]
  end

  def adjusted_patients
    repository.adjusted_patients[@region.slug]
  end

  def period_info
    repository.period_info(@region)
  end
end
