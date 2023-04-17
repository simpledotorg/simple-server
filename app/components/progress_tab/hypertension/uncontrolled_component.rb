# frozen_string_literal: true

class ProgressTab::Hypertension::UncontrolledComponent < ApplicationComponent
  include AssetsHelper
  include ActionView::Helpers::NumberHelper

  attr_reader :uncontrolled_rates, :uncontrolled, :adjusted_patients, :period_info, :region

  def initialize(uncontrolled_rates:, uncontrolled:, adjusted_patients:, period_info:, region:)
    @uncontrolled_rates = uncontrolled_rates
    @uncontrolled = uncontrolled
    @adjusted_patients = adjusted_patients
    @period_info = period_info
    @region = region
  end
end
