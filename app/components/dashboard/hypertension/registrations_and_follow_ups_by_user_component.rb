class Dashboard::Hypertension::RegistrationsAndFollowUpsByUserComponent < ApplicationComponent
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

  def show_user_in_region?(user)
    registrations_by_user(user).nonzero? || bp_measures_by_user(user).nonzero?
  end

  def registrations_by_user(user)
    sum_registration_counts(repository, slug: region.slug, user_id: user.id, diagnosis: :hypertension) || 0
  end

  def bp_measures_by_user(user)
    sum_bp_measures(repository, slug: region.slug, user_id: user.id) || 0
  end

  def monthly_registrations_by_user(user, period)
    repository.monthly_registrations_by_user.dig(region.slug, period, user.id)
  end

  def monthly_follow_ups_by_user(user, period)
    repository.hypertension_follow_ups(group_by: "blood_pressures.user_id").dig(region.slug, period, user.id)
  end
end
