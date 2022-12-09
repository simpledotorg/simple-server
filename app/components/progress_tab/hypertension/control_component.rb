# frozen_string_literal: true

class ProgressTab::Hypertension::ControlComponent < ApplicationComponent
  include AssetsHelper
  include ActionView::Helpers::NumberHelper

  attr_reader :repository, :current_user

  def initialize(service, current_user)
    @repository = service.repository
    @region = service.region
    @current_user = current_user
  end

  def render?
    Flipper.enabled?(:new_progress_tab_v2, current_user) || Flipper.enabled?(:new_progress_tab_v2)
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
