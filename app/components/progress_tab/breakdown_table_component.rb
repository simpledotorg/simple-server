# frozen_string_literal: true

class ProgressTab::BreakdownTableComponent < ApplicationComponent
  include AssetsHelper
  include ProgressTabHelper

  # We use 29 here because we also show today, so its 30 days including today
  DAYS_AGO = 29
  DAY_FORMAT = ApplicationHelper::STANDARD_DATE_DISPLAY_FORMAT

  attr_reader :title, :breakdown

  def initialize(title:, breakdown:)
    @title = title
    @breakdown = breakdown
  end

  def include_bottom_border
    true unless title == "Hypertension and Diabetes"
  end
end
