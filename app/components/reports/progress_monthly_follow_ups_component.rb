# frozen_string_literal: true

class Reports::ProgressMonthlyFollowUpsComponent < ViewComponent::Base
  include AssetsHelper
  include ActionView::Helpers::NumberHelper

  attr_reader :repo, :report_month, :last_6_months

  def initialize(service, period_month)
    @region = service.region
    @report_month = period_month
    @last_6_months = Range.new(@report_month.advance(months: -5), @report_month)
    @repository = Reports::Repository.new(@region, periods: @last_6_months)
  end

  def monthly_follow_ups
    @repository.hypertension_follow_ups[@region.slug]
  end

  def period_info
    @repository.period_info(@region)
  end
end
