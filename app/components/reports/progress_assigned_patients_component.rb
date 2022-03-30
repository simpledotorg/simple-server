# frozen_string_literal: true

class Reports::ProgressAssignedPatientsComponent < ViewComponent::Base
  include AssetsHelper
  include ActionView::Helpers::NumberHelper

  attr_reader :repository, :region, :report_month, :last_6_months

  def initialize(service, period_month)
    @region = service.region
    @report_month = period_month
    @last_6_months = Range.new(@report_month.advance(months: -5), @report_month)
    @repository = Reports::Repository.new(@region, periods: @last_6_months)
  end

  def assigned_patients
    repository.cumulative_assigned_patients[region.slug][@report_month]
  end
end
