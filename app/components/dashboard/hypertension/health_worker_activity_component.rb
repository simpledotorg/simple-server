class Dashboard::Hypertension::HealthWorkerActivityComponent < ApplicationComponent
  include Reports::RegionsHelper
  include DashboardHelper

  attr_reader :region, :period, :repository, :current_admin

  def initialize(region:, period:, repository:, current_admin:)
    @region = region
    @period = period
    @repository = repository
    @current_admin = current_admin
  end

  def range
    repository.range
  end

  def show_overdue_call_results?
    current_admin.feature_enabled?(:show_call_results)
  end

  def users_in_region
    current_admin
      .accessible_users(:view_reports)
      .order(:full_name)
      .filter { |user| show_user_in_region?(user) }
  end

  def show_user_in_region?(user)
    if show_overdue_call_results?
      overdue_patients_contacted_by_user(user).nonzero? || bp_measures_by_user(user).nonzero?
    else
      registrations_by_user(user).nonzero? || bp_measures_by_user(user).nonzero?
    end
  end

  def overdue_patients_contacted_by_user(user)
    sum_overdue_calls(@repository, slug: @region.slug, user_id: user.id) || 0
  end

  def registrations_by_user(user)
    sum_registration_counts(repository, slug: region.slug, user_id: user.id, diagnosis: :hypertension) || 0
  end

  def bp_measures_by_user(user)
    sum_bp_measures(repository, slug: region.slug, user_id: user.id) || 0
  end

  def monthly_bp_measures_by_user(user, period)
    repository.bp_measures_by_user.dig(region.slug, period, user.id)
  end

  def monthly_registrations_by_user(user, period)
    repository.monthly_registrations_by_user.dig(region.slug, period, user.id)
  end

  def monthly_overdue_patients_contacted_by_user(user, period)
    repository.overdue_calls_by_user.dig(@region.slug, period, user.id)
  end
end
