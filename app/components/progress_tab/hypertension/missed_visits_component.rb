# frozen_string_literal: true

class ProgressTab::Hypertension::MissedVisitsComponent < ApplicationComponent
  include AssetsHelper
  include ActionView::Helpers::NumberHelper

  attr_reader :repository

  def initialize(service)
    @repository = service.repository
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
