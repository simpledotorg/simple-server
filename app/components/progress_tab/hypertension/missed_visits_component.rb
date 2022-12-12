# frozen_string_literal: true

class ProgressTab::Hypertension::MissedVisitsComponent < ApplicationComponent
  include AssetsHelper
  include ActionView::Helpers::NumberHelper

  attr_reader :missed_visits_rates, :missed_visits, :adjusted_patients, :period_info, :region

  def initialize(missed_visits_rates:, missed_visits:, adjusted_patients:, period_info:, region:)
    @missed_visits_rates = missed_visits_rates
    @missed_visits = missed_visits
    @adjusted_patients = adjusted_patients
    @period_info = period_info
    @region = region
  end
end
