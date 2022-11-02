# frozen_string_literal: true

class ProgressTab::Hypertension::DiagnosisReportComponent < ApplicationComponent
  include AssetsHelper
  include ApplicationHelper

  def initialize(service:, current_user:, period:, drug_stock_query:, drugs_by_category:, current_facility:, last_updated_at:, cohort_data:)
    @service = service
    @current_facility = current_facility
    @current_user = current_user
    @period = period
    @drug_stock_query = drug_stock_query
    @drug_by_category = drugs_by_category
    @cohort_data = cohort_data
    @last_updated_at = last_updated_at
  end

  def render?
    Flipper.enabled?(:new_progress_tab_v2, @current_user) || Flipper.enabled?(:new_progress_tab_v2) ||
      Flipper.enabled?(:new_progress_tab_v1, @current_user) || Flipper.enabled?(:new_progress_tab_v1)
  end
end
