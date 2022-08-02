class Dashboard::Diabetes::HealthcareWorkerActivityComponent < ApplicationComponent
  include Reports::RegionsHelper
  include DashboardHelper

  attr_reader :region, :repository, :period_range, :current_admin

  def initialize(region:, repository:, period_range:, current_admin:)
    @region = region
    @repository = repository
    @period_range = period_range
    @current_admin = current_admin
  end

  def show_user_row?(user)
    user_registrations_count(user)&.nonzero? || user_blood_pressure_measures_count(user)&.nonzero?
  end

  def user_registrations_count(user)
    sum_registration_counts(repository, slug: region.slug, user_id: user.id, diagnosis: :diabetes)
  end

  def user_blood_pressure_measures_count(user)
    sum_blood_sugar_measures(repository, slug: region.slug, user_id: user.id)&.nonzero?
  end

  def blood_sugar_measures_taken_by_user_in_period(user, period)
    repository.blood_sugar_measures_by_user.dig(region.slug, period, user.id)
  end
end
