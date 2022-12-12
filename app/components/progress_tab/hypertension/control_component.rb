# frozen_string_literal: true

class ProgressTab::Hypertension::ControlComponent < ApplicationComponent
  include AssetsHelper
  include ActionView::Helpers::NumberHelper

  attr_reader :control_rates, :controlled, :adjusted_patients, :period_info, :region

  def initialize(controlled_rates:, controlled:, adjusted_patients:, period_info:, region:)
    @control_rates = controlled_rates
    @controlled = controlled
    @adjusted_patients = adjusted_patients
    @period_info = period_info
    @region = region
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
end
